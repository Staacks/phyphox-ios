//
//  Experiment.swift
//  phyphox
//
//  Created by Jonas Gessner on 04.12.15.
//  Copyright © 2015 Jonas Gessner. All rights reserved.
//  By Order of RWTH Aachen.
//

import Foundation
import AVFoundation
import CoreLocation

struct ExperimentRequiredPermission : OptionSet {
    let rawValue: Int
    
    static let None = ExperimentRequiredPermission(rawValue: 0)
    static let Microphone = ExperimentRequiredPermission(rawValue: (1 << 0))
    static let Location = ExperimentRequiredPermission(rawValue: (1 << 1))
}

protocol ExperimentDelegate: class {
    func experimentWillBecomeActive(_ experiment: Experiment)
}

extension Collection {
    func enumerateSlices(size: IndexDistance, until: Index, body: (SubSequence) throws -> Void) rethrows {
        var currentIndex = startIndex
        var nextIndex: Index

        repeat {
            nextIndex = Swift.min(index(currentIndex, offsetBy: size), endIndex)

            try body(self[currentIndex..<nextIndex])

            currentIndex = nextIndex
        }
        while nextIndex < endIndex
    }
}

extension DataBuffer {
    func flush(to url: URL) throws -> URL {
        let flushCount = count/2

        let fileURL = url.appendingPathComponent(name).appendingPathExtension(bufferContentsFileExtension)

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        }

        let values = toArray()

        let pointer = UnsafeMutablePointer(mutating: values)
        let rawPointer = UnsafeMutableRawPointer(pointer)

        let data = Data(bytesNoCopy: rawPointer, count: flushCount * MemoryLayout<Double>.size, deallocator: .none)

        try data.write(to: fileURL, options: .atomic)
//
//        let littleEndianValues = self[0..<flushCount].map({ $0.bitPattern.littleEndian })
//
//        let pointer = UnsafePointer(littleEndianValues)
//        let buffer = UnsafeBufferPointer(start: pointer, count: littleEndianValues.count)
//
//        let data = Data(buffer: buffer)
//
//        try data.write(to: fileURL)

//        let handle = try FileHandle(forWritingTo: fileURL)
//        handle.seekToEndOfFile()
//
//        var i = 0
//        enumerateSlices(size: 100000, until: flushCount) { values in
//            i += values.count
//            print("write \(100 * Double(i)/Double(flushCount))%")
//            let littleEndianValues = values.map({ $0.bitPattern.littleEndian })
//
//            let pointer = UnsafePointer(littleEndianValues)
//            let buffer = UnsafeBufferPointer(start: pointer, count: littleEndianValues.count)
//
//            let data = Data(buffer: buffer)
//
//            handle.write(data)
//        }
//
//        handle.closeFile()

        removeFirst(flushCount)

        return fileURL
    }
}

final class Experiment: ExperimentAnalysisDelegate, ExperimentAnalysisTimeManager {
    let title: String
    private let description: String?
    private let links: [String: String]
    private let highlightedLinks: [String: String]
    private let category: String
    
    var localizedTitle: String {
        return translation?.selectedTranslation?.titleString ?? title
    }
    
    var localizedDescription: String? {
        return translation?.selectedTranslation?.descriptionString ?? description
    }
    
    var localizedLinks: [String: String] {
        var allLinks = links
        if let translatedLinks = translation?.selectedTranslation?.translatedLinks {
            for (key, value) in translatedLinks {
                allLinks[key] = value
            }
        }
        return allLinks
    }
    
    var localizedHighlightedLinks: [String: String] {
        var allLinks = highlightedLinks
        if let translatedLinks = translation?.selectedTranslation?.translatedLinks {
            for (key, _) in translatedLinks {
                allLinks[key] = translatedLinks[key]
            }
        }
        return allLinks
    }
    
    var localizedCategory: String {
        if source?.path.hasPrefix(savedExperimentStatesURL.path) == true {
            return NSLocalizedString("save_state_category", comment: "")
        }
        return translation?.selectedTranslation?.categoryString ?? category
    }

    weak var delegate: ExperimentDelegate?

    let icon: ExperimentIcon

    let persistentStorageURL: URL

    var local: Bool
    var source: URL?
    
    let viewDescriptors: [ExperimentViewCollectionDescriptor]?
    
    let translation: ExperimentTranslationCollection?
    let sensorInputs: [ExperimentSensorInput]?
    let gpsInput: ExperimentGPSInput?
    let audioInput: ExperimentAudioInput?
    let output: ExperimentOutput?
    let analysis: ExperimentAnalysis?
    let export: ExperimentExport?
    
    let buffers: ([String: DataBuffer], [DataBuffer])
    
    let queue: DispatchQueue
    
    var requiredPermissions: ExperimentRequiredPermission = .None
    
    private(set) var running = false
    private(set) var hasStarted = false
    
    private(set) var startTimestamp: TimeInterval?
    private var pauseBegin: TimeInterval = 0.0

//    private var bufferStorageURL: URL?

    init(title: String, description: String?, links: [String: String], highlightedLinks: [String:String], category: String, icon: ExperimentIcon, local: Bool, persistentStorageURL: URL, translation: ExperimentTranslationCollection?, buffers: ([String: DataBuffer], [DataBuffer]), sensorInputs: [ExperimentSensorInput]?, gpsInput: ExperimentGPSInput?, audioInput: ExperimentAudioInput?, output: ExperimentOutput?, viewDescriptors: [ExperimentViewCollectionDescriptor]?, analysis: ExperimentAnalysis?, export: ExperimentExport?) {
        self.persistentStorageURL = persistentStorageURL
        self.title = title
        self.description = description
        self.links = links
        self.highlightedLinks = highlightedLinks
        self.category = category
        
        self.icon = icon
        
        self.local = local
        
        self.translation = translation

        self.buffers = buffers
        self.sensorInputs = sensorInputs
        self.gpsInput = gpsInput
        self.audioInput = audioInput
        self.output = output
        self.viewDescriptors = viewDescriptors
        self.analysis = analysis
        self.export = export
        
        queue = DispatchQueue(label: "de.rwth-aachen.phyphox.experiment.queue", attributes: DispatchQueue.Attributes.concurrent)
        
        defer {
            NotificationCenter.default.addObserver(self, selector: #selector(Experiment.endBackgroundSession), name: NSNotification.Name(rawValue: EndBackgroundMotionSessionNotification), object: nil)
        }
        
        if audioInput != nil {
            requiredPermissions.insert(.Microphone)
        }
        
        if gpsInput != nil {
            requiredPermissions.insert(.Location)
        }
        
        self.analysis?.delegate = self
        self.analysis?.timeManager = self

//        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryWarning), name: .UIApplicationDidReceiveMemoryWarning, object: nil)
    }

//    private func createBufferStorage() -> URL {
//        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
//
//        let storageURL = temporaryDirectory.appendingPathComponent(UUID().uuidString)
//
//        try? FileManager.default.createDirectory(at: storageURL, withIntermediateDirectories: false, attributes: nil)
//
//        return storageURL
//    }
//
//    @objc private func didReceiveMemoryWarning() {
//        let outputBuffers = self.outpututBuffers
//
//        guard outpututBuffers.count > 0 else { return }
//
//        let bufferStorage = bufferStorageURL ?? createBufferStorage()
//
//        outpututBuffers.forEach { buffer in
//            try? buffer.flush(to: bufferStorage)
//        }
//    }
//
    @objc func endBackgroundSession() {
        stop()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func getCurrentTimestamp() -> TimeInterval {
        return startTimestamp != nil ? CFAbsoluteTimeGetCurrent()-startTimestamp! : 0.0
    }
    
    func analysisWillUpdate(_: ExperimentAnalysis) {
    }
    
    func analysisDidUpdate(_: ExperimentAnalysis) {
        if running {
            output?.audioOutput?.play()
        }
    }
    
    /**
     Called when the experiment view controller will be presented.
     */
    func willGetActive(_ dismiss: @escaping () -> ()) {
        if requiredPermissions != .None {
            checkAndAskForPermissions(dismiss, locationManager: gpsInput?.locationManager)
        }

        delegate?.experimentWillBecomeActive(self)
    }
    
    /**
     Called when the experiment view controller did dismiss.
     */
    func didBecomeInactive() {
        clear()
    }
    
    func checkAndAskForPermissions(_ failed: @escaping () -> Void, locationManager: CLLocationManager?) {
        if requiredPermissions.contains(.Microphone) {
            
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
        } else if requiredPermissions.contains(.Location) {
            
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
        try ExperimentManager.shared.audioEngine.startEngine(playback: output?.audioOutput, recordInput: audioInput)
        output?.audioOutput?.play()
    }
    
    private func stopAudio() {
        ExperimentManager.shared.audioEngine.stopEngine()
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

        for buffer in buffers.1 {
            buffer.open()
        }

        hasStarted = true

        UIApplication.shared.isIdleTimerDisabled = true
        
        try startAudio()
        
        if let sensorInputs = sensorInputs {
            for sensor in sensorInputs {
                sensor.start()
            }
        }

        gpsInput?.start()
        
        analysis?.running = true
        analysis?.setNeedsUpdate()
    }
    
    func stop() {
        guard running else {
            return
        }
        
        analysis?.running = false
        
        pauseBegin = CFAbsoluteTimeGetCurrent()
        
        if let sensorInputs = sensorInputs {
            for sensor in sensorInputs {
                sensor.stop()
            }
        }
        
        gpsInput?.stop()
        
        stopAudio()
        
        UIApplication.shared.isIdleTimerDisabled = false
        
        running = false
    }
    
    func clear() {
        stop()
        pauseBegin = 0.0
        startTimestamp = nil
        hasStarted = false

        for buffer in buffers.1 {
            buffer.close()
        }

        try? FileManager.default.removeItem(at: persistentStorageURL)

        for buffer in buffers.1 {
            if !buffer.attachedToTextField {
                buffer.clear()
            }
        }
        
        if let sensorInputs = sensorInputs {
            for sensor in sensorInputs {
                sensor.clear()
            }
        }

        gpsInput?.clear()
    }
}

extension Experiment: Equatable {
    static func ==(lhs: Experiment, rhs: Experiment) -> Bool {
        return lhs.title == rhs.title && lhs.category == rhs.category && lhs.description == rhs.description
    }
}

//extension Experiment {
//    var outpututBuffers: [DataBuffer] {
//        guard let inputBufferNames = analysis?.modules.flatMap({ $0.inputs.flatMap { $0.buffer?.name } }) else { return buffers.1 }
//
//        return buffers.1.filter { !inputBufferNames.contains($0.name) }
//    }
//}

