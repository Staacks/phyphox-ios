//
//  ExperimentAnalysis.swift
//  phyphox
//
//  Created by Jonas Gessner on 11.01.16.
//  Copyright © 2016 RWTH Aachen. All rights reserved.
//

import Foundation

protocol ExperimentAnalysisDelegate : AnyObject {
    func analysisWillUpdate(analysis: ExperimentAnalysis)
    func analysisDidUpdate(analysis: ExperimentAnalysis)
}

private let analysisQueue = dispatch_queue_create("de.rwth-aachen.phyphox.analysis", DISPATCH_QUEUE_SERIAL)

final class ExperimentAnalysis : DataBufferObserver {
    let analyses: [ExperimentAnalysisModule]
    
    let sleep: Double
    let onUserInput: Bool
    
    weak var delegate: ExperimentAnalysisDelegate?
    
    private let editBuffers = NSMutableSet()
    
    init(analyses: [ExperimentAnalysisModule], sleep: Double, onUserInput: Bool) {
        self.analyses = analyses
        
        self.sleep = sleep
        self.onUserInput = onUserInput
    }
    
    /**
     Used to register a data buffer that receives data directly from a sensor or from the microphone
     */
    func registerSensorBuffer(dataBuffer: DataBuffer) {
        dataBuffer.addObserver(self)
    }
    
    /**
     Used to register a data buffer that receives data from user input
     */
    func registerEditBuffer(dataBuffer: DataBuffer) {
        dataBuffer.addObserver(self)
        editBuffers.addObject(dataBuffer)
    }
    
    func dataBufferUpdated(buffer: DataBuffer) {
        if !onUserInput || editBuffers.containsObject(buffer) {
            setNeedsUpdate()
        }
    }
    
    private var busy = false
    
    /**
     Schedules an update.
    */
    func setNeedsUpdate() {
        if !busy {
            busy = true
            
            after(0.1, closure: { () -> Void in
                #if DEBUG
                    print("Analysis update")
                #endif
                
                self.delegate?.analysisWillUpdate(self)
                self.update()
                self.delegate?.analysisDidUpdate(self)
                
                self.busy = false
            })
        }
    }
    
    private func update() {
        for analysis in analyses {
            dispatch_async(analysisQueue, { 
                analysis.setNeedsUpdate()
            })
        }
    }
}
