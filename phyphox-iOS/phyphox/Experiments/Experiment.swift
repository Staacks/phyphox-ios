//
//  Experiment.swift
//  phyphox
//
//  Created by Jonas Gessner on 04.12.15.
//  Copyright © 2015 Jonas Gessner. All rights reserved.
//

import Foundation
import AVFoundation
import CoreLocation

private struct ExperimentRequiredPermission: OptionSet {
    let rawValue: Int
    
    static let none = ExperimentRequiredPermission(rawValue: 0)
    static let microphone = ExperimentRequiredPermission(rawValue: (1 << 0))
    static let location = ExperimentRequiredPermission(rawValue: (1 << 1))
}

protocol ExperimentDelegate: class {
    func experimentWillBecomeActive(_ experiment: Experiment)
}

struct ExperimentLink: Equatable {
    let label: String
    let url: URL
    let highlighted: Bool
}

final class Experiment {
    let title: String
    private let description: String?
    private let links: [ExperimentLink]
    private let category: String
    
    var localizedTitle: String {
        return translation?.selectedTranslation?.titleString ?? title
    }
    
    var localizedDescription: String? {
        return translation?.selectedTranslation?.descriptionString ?? description
    }
    
    let localizedLinks: [ExperimentLink]
    
    var localizedCategory: String {
        if source?.path.hasPrefix(savedExperimentStatesURL.path) == true {
            return NSLocalizedString("save_state_category", comment: "")
        }
        return translation?.selectedTranslation?.categoryString ?? category
    }

    weak var delegate: ExperimentDelegate?

    let icon: ExperimentIcon

    let persistentStorageURL: URL

    var local: Bool = true
    var source: URL?
    
    let viewDescriptors: [ExperimentViewCollectionDescriptor]?
    
    let translation: ExperimentTranslationCollection?

    let sensorInputs: [ExperimentSensorInput]
    let gpsInputs: [ExperimentGPSInput]
    let audioInputs: [ExperimentAudioInput]

    let output: ExperimentOutput?
    let analysis: ExperimentAnalysis?
    let export: ExperimentExport?
    
    let buffers: [String: DataBuffer]

    private var requiredPermissions: ExperimentRequiredPermission = .none
    
    private(set) var running = false
    private(set) var hasStarted = false
    
    private(set) var startTimestamp: TimeInterval?
    private var pauseBegin: TimeInterval = 0.0

    private var audioEngine: AudioEngine?

    init(title: String, description: String?, links: [ExperimentLink], category: String, icon: ExperimentIcon, persistentStorageURL: URL, translation: ExperimentTranslationCollection?, buffers: [String: DataBuffer], sensorInputs: [ExperimentSensorInput], gpsInputs: [ExperimentGPSInput], audioInputs: [ExperimentAudioInput], output: ExperimentOutput?, viewDescriptors: [ExperimentViewCollectionDescriptor]?, analysis: ExperimentAnalysis?, export: ExperimentExport?) {
        self.persistentStorageURL = persistentStorageURL
        self.title = title
        self.description = description
        self.links = links

        self.localizedLinks = links.map { ExperimentLink(label: translation?.localize($0.label) ?? $0.label, url: $0.url, highlighted: $0.highlighted) }

        self.category = category
        
        self.icon = icon
        
        self.translation = translation

        self.buffers = buffers
        self.sensorInputs = sensorInputs
        self.gpsInputs = gpsInputs
        self.audioInputs = audioInputs
        self.output = output
        self.viewDescriptors = viewDescriptors
        self.analysis = analysis
        self.export = export
        
        defer {
            NotificationCenter.default.addObserver(self, selector: #selector(Experiment.endBackgroundSession), name: NSNotification.Name(rawValue: EndBackgroundMotionSessionNotification), object: nil)
        }
        
        if !audioInputs.isEmpty {
            requiredPermissions.insert(.microphone)
        }
        
        if !gpsInputs.isEmpty {
            requiredPermissions.insert(.location)
        }
        
        analysis?.delegate = self
        analysis?.timestampSource = self
    }

    @objc private func endBackgroundSession() {
        stop()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /**
     Called when the experiment view controller will be presented.
     */
    func willBecomeActive(_ dismiss: @escaping () -> Void) {
        if requiredPermissions != .none {
            checkAndAskForPermissions(dismiss, locationManager: gpsInputs.first?.locationManager)
        }

        delegate?.experimentWillBecomeActive(self)
    }
    
    /**
     Called when the experiment view controller did dismiss.
     */
    func didBecomeInactive() {
        clear()
    }
    
    private func checkAndAskForPermissions(_ failed: @escaping () -> Void, locationManager: CLLocationManager?) {
        if requiredPermissions.contains(.microphone) {
            let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
            
            switch status {
            case .denied:
                failed()
                let alert = UIAlertController(title: "Microphone Required", message: "This experiment requires access to the Microphone, but the access has been denied. Please enable access to the microphone in Settings->Privacy->Microphone", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                UIApplication.shared.keyWindow!.rootViewController!.present(alert, animated: true, completion: nil)
                
            case .restricted:
                failed()
                let alert = UIAlertController(title: "Microphone Required", message: "This experiment requires access to the Microphone, but the access has been restricted. Please enable access to the microphone in Settings->General->Restrctions->Microphone", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                UIApplication.shared.keyWindow!.rootViewController!.present(alert, animated: true, completion: nil)
                
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler: { (allowed) in
                    if !allowed {
                        failed()
                    }
                })
                
            default:
                break
            }
        } else if requiredPermissions.contains(.location) {
            
            let status = CLLocationManager.authorizationStatus()
            
            switch status {
            case .denied:
                failed()
                let alert = UIAlertController(title: "Location/GPS Required", message: "This experiment requires access to the location (GPS), but the access has been denied. Please enable access to the location in Settings->Privacy->Location Services", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                UIApplication.shared.keyWindow!.rootViewController!.present(alert, animated: true, completion: nil)
                
            case .restricted:
                failed()
                let alert = UIAlertController(title: "Location/GPS Required", message: "This experiment requires access to the location (GPS), but the access has been restricted. Please enable access to the location in Settings->General->Restrctions->Location Services", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                UIApplication.shared.keyWindow!.rootViewController!.present(alert, animated: true, completion: nil)
                
            case .notDetermined:
                locationManager?.requestWhenInUseAuthorization()
                break
                
            default:
                break
            }
        }
    }
    
    private func startAudio() throws {
        if output?.audioOutput != nil || !audioInputs.isEmpty {
            audioEngine = try AudioEngine(audioOutput: output?.audioOutput, audioInput: audioInputs.first)
            try audioEngine?.startEngine()
        }
    }
    
    private func stopAudio() throws {
        try audioEngine?.stopEngine()
        audioEngine = nil
    }
    
    func start() throws {
        guard !running else {
            return
        }
        
        if pauseBegin > 0 {
            startTimestamp! += CFAbsoluteTimeGetCurrent()-pauseBegin
            pauseBegin = 0.0
        }
        
        if startTimestamp == nil {
            startTimestamp = CFAbsoluteTimeGetCurrent()
        }
        
        running = true

        try? FileManager.default.createDirectory(at: persistentStorageURL, withIntermediateDirectories: false, attributes: nil)

        for buffer in buffers.values {
            buffer.open()
        }

        hasStarted = true

        UIApplication.shared.isIdleTimerDisabled = true
        
        try startAudio()
        
        sensorInputs.forEach { $0.start() }
        gpsInputs.forEach { $0.start() }
        
        analysis?.running = true
        analysis?.setNeedsUpdate()
    }
    
    func stop() {
        guard running else {
            return
        }
        
        analysis?.running = false
        
        pauseBegin = CFAbsoluteTimeGetCurrent()
        
        sensorInputs.forEach { $0.stop() }
        gpsInputs.forEach { $0.stop() }
        
        try? stopAudio()
        
        UIApplication.shared.isIdleTimerDisabled = false
        
        running = false
    }
    
    func clear() {
        stop()
        pauseBegin = 0.0
        startTimestamp = nil
        hasStarted = false

        try? FileManager.default.removeItem(at: persistentStorageURL)

        for buffer in buffers.values {
            if !buffer.attachedToTextField {
                buffer.clear()
            }
        }

        sensorInputs.forEach { $0.clear() }
        gpsInputs.forEach { $0.clear() }

        for buffer in buffers.values {
            buffer.close()
        }
    }
}

extension Experiment: ExperimentAnalysisDelegate {
    func analysisWillUpdate(_: ExperimentAnalysis) {
    }

    func analysisDidUpdate(_: ExperimentAnalysis) {
        if running {
            audioEngine?.playAudioOutput()
        }
    }
}

extension Experiment: ExperimentAnalysisTimestampSource {
    func getCurrentTimestamp() -> TimeInterval {
        guard let startTimestamp = startTimestamp else { return 0.0 }

        return CFAbsoluteTimeGetCurrent() - startTimestamp
    }
}

extension Experiment {
    func metadataEqual(to rhs: Experiment?) -> Bool {
        guard let rhs = rhs else { return false }
        return title == rhs.title && category == rhs.category && description == rhs.description
    }
}

extension Experiment: Equatable {
    static func ==(lhs: Experiment, rhs: Experiment) -> Bool {
        print(lhs.title == rhs.title)
        print(lhs.localizedDescription == rhs.localizedDescription)
        print(lhs.localizedLinks == rhs.localizedLinks)
        print(lhs.localizedCategory == rhs.localizedCategory)
        print(lhs.icon == rhs.icon)
        print(lhs.local == rhs.local)
        print(lhs.translation == rhs.translation)
        
        print(lhs.buffers == rhs.buffers)
        print(lhs.sensorInputs.elementsEqual(rhs.sensorInputs, by: { (l, r) -> Bool in
            ExperimentSensorInput.valueEqual(lhs: l, rhs: r)
        }))
        print(lhs.gpsInputs == rhs.gpsInputs)
        print(lhs.audioInputs == rhs.audioInputs)
        print(lhs.output == rhs.output)
        print(lhs.analysis == rhs.analysis)
        print(lhs.viewDescriptors == rhs.viewDescriptors)
        print(lhs.export == rhs.export)

        
        return lhs.title == rhs.title &&
            lhs.localizedDescription == rhs.localizedDescription &&
            lhs.localizedLinks == rhs.localizedLinks &&
            lhs.localizedCategory == rhs.localizedCategory &&
            lhs.icon == rhs.icon &&
            lhs.local == rhs.local &&
            lhs.translation == rhs.translation &&
            lhs.buffers == rhs.buffers &&
            lhs.sensorInputs.elementsEqual(rhs.sensorInputs, by: { (l, r) -> Bool in
                ExperimentSensorInput.valueEqual(lhs: l, rhs: r)
            }) &&
            lhs.gpsInputs == rhs.gpsInputs &&
            lhs.audioInputs == rhs.audioInputs &&
            lhs.output == rhs.output &&
            lhs.viewDescriptors == rhs.viewDescriptors &&
            lhs.analysis == rhs.analysis &&
            lhs.export == rhs.export
    }
}
