//
//  ExperimentInputsParser.swift
//  phyphox
//
//  Created by Jonas Gessner on 10.12.15.
//  Copyright © 2015 RWTH Aachen. All rights reserved.
//

import Foundation

final class ExperimentInputsParser: ExperimentMetadataParser {
    let sensors: [NSDictionary]?
    let audio: [NSDictionary]?
    
    required init(_ inputs: NSDictionary) {
        sensors = getElementsWithKey(inputs, key: "sensor") as! [NSDictionary]?
        audio = getElementsWithKey(inputs, key: "audio") as! [NSDictionary]?
    }
    
    func mapTypeStringToSensorType(type: String) -> SensorType? {
        if type == "pressure" {
            return .Pressure
        }
        else if type == "accelerometer" {
            return .Accelerometer
        }
        else if type == "linear_acceleration" {
            return .LinearAcceleration
        }
        else if type == "gyroscope" {
            return .Gyroscope
        }
        else if type == "light" {
            return .Light
        }
        else if type == "magnetic_field" {
            return .MagneticField
        }
        
        return nil
    }
    
    func sensorTypeFromXML(xml: [String: AnyObject]?, key: String) -> SensorType? {
        if xml == nil {
            return nil
        }
        
        let typeString = xml![key] as! String?
        
        if typeString == nil {
            print("Error! Empty sensor type")
            return nil
        }
        
        let sensorType = mapTypeStringToSensorType(typeString!)
        
        if sensorType == nil {
            print("Error! Invalid sensor type: \(typeString)")
            return nil
        }
        
        return sensorType
    }
    
    func parse(buffers: [String : DataBuffer], analysis: ExperimentAnalysis?) -> ([ExperimentSensorInput]?, [ExperimentAudioInput]?) {
        if sensors == nil && audio == nil {
            return (nil, nil)
        }
        
        let motionSession = MotionSession()
        
        var sensorsOut: [ExperimentSensorInput]?
        
        if sensors != nil {
            sensorsOut = []
            
            for sensor in sensors! {
                let attributes = sensor[XMLDictionaryAttributesKey] as! [String: String]
                
                let average = boolFromXML(attributes, key: "average", defaultValue: false)
                
                let rate = 1.0/floatTypeFromXML(attributes, key: "rate", defaultValue: 0.0) //Hz to s
                
                let sensorType = sensorTypeFromXML(attributes, key: "type")
                
                if sensorType == nil {
                    print("Error! Sensor type not set")
                    continue
                }
                
                let outputs = getElementsWithKey(sensor, key: "output") as! [[String: AnyObject]]
                
                var xBuffer, yBuffer, zBuffer, tBuffer: DataBuffer?
                
                for output in outputs {
                    let attributes = output[XMLDictionaryAttributesKey] as! [String: String]
                    
                    let name = output[XMLDictionaryTextKey] as! String
                    
                    var component = attributes["component"]
                    
                    if sensorType == .Pressure && component != "t" {
                        component = "z" //Pressure is always only z (on Android it seems to be x)
                    }
                    
                    let buf = buffers[name]
                    
                    if component == "x" {
                        xBuffer = buf
                    }
                    else if component == "y" {
                        yBuffer = buf
                    }
                    else if component == "z" {
                        zBuffer = buf
                    }
                    else if component == "t" {
                        tBuffer = buf
                    }
                    else {
                        print("Error! Invalid sensor parameter: \(component)")
                        continue
                    }
                    
                    //Register for updates
                    if buf != nil && analysis != nil {
                        analysis!.registerSensorBuffer(buf!)
                    }
                }
                
                if average && rate == 0.0 {
                    print("Error! Averaging is enabled but rate is 0")
                }
                
                let sensor = ExperimentSensorInput(sensorType: sensorType!, motionSession: motionSession, rate: rate, average: average, xBuffer: xBuffer, yBuffer: yBuffer, zBuffer: zBuffer, tBuffer: tBuffer)
                
                sensorsOut!.append(sensor)
            }
        }
        
        var audioOut: [ExperimentAudioInput]?
        
        if audio != nil {
            audioOut = []
            
            for audioIn in audio! {
                let attributes = audioIn[XMLDictionaryAttributesKey] as! [String: String]?
                
                let sampleRate = intTypeFromXML(attributes, key: "rate", defaultValue: UInt(48000))
                
                let output = getElementsWithKey(audioIn, key: "output")!
                
                var outBuffers: [DataBuffer] = []
                outBuffers.reserveCapacity(output.count)
                
                for out in output {
                    let bufferName = (out as? String ?? (out as! [String: AnyObject])[XMLDictionaryTextKey] as! String)
                    
                    let buffer = buffers[bufferName]!
                    
                    if analysis != nil {
                        analysis!.registerSensorBuffer(buffer)
                    }
                    
                    outBuffers.append(buffer)
                }
                
                let input = ExperimentAudioInput(sampleRate: sampleRate, outBuffers: outBuffers)
                
                audioOut!.append(input)
            }
        }
        
        return ((sensorsOut?.count > 0 ? sensorsOut : nil), (audioOut?.count > 0 ? audioOut : nil))
    }
}
