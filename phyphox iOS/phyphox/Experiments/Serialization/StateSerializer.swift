//
//  SimpleStateSerializer.swift
//  phyphox
//
//  Created by Sebastian Kuhlen on 26.05.17.
//  Copyright © 2017 RWTH Aachen. All rights reserved.
//

import Foundation

final class StateSerializer {
    
    enum stateError: Error {
        case SourceError(String)
    }
    
    class func writeStateFile(customTitle: String, target: String, experiment: Experiment, callback: @escaping (_ errorMessage: String?, _ fileURL: URL?) -> Void) -> Void {
        let str: String
        do {
            str = try serializeState(customTitle: customTitle, experiment: experiment)
        } catch stateError.SourceError(let error) {
            mainThread {
                callback("State error: \(error).", nil)
            }
            return
        } catch {
            mainThread {
                callback("Unknown error.", nil)
            }
            return
        }

        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            autoreleasepool {
                do { try FileManager.default.removeItem(atPath: target) } catch {}
                
                let fileURL = URL(fileURLWithPath: target)
                
                do {
                    try str.write(toFile: target, atomically: true, encoding: String.Encoding.utf8)
                } catch {
                    mainThread {
                        callback("Error: Could not write to file.", nil)
                    }
                    return
                }
                
                mainThread {
                    callback(nil, fileURL)
                }
            }
        }
    }
    
    class func serializeState(customTitle: String, experiment: Experiment) throws -> String {
        let formatter = NumberFormatter()
        formatter.maximumSignificantDigits = 10
        formatter.minimumSignificantDigits = 1
        formatter.decimalSeparator = "."
        formatter.numberStyle = .scientific
        
        func format(_ n: Double) -> String {
            return formatter.string(from: NSNumber(value: n as Double))!
        }
        
        let sourceStr = String(data: experiment.sourceData!, encoding: String.Encoding.utf8)
        let dataContainersBlockStart = sourceStr?.range(of: "<data-containers>", options: .caseInsensitive)
        let dataContainersBlockStop = sourceStr?.range(of: "</data-containers>", options: .caseInsensitive)
        if dataContainersBlockStop == nil || dataContainersBlockStart == nil {
            throw stateError.SourceError("No valid data containers block found.")
        }
        let endLocation = String(sourceStr![dataContainersBlockStop!.lowerBound...]).range(of: "</phyphox>", options: .caseInsensitive)
        if dataContainersBlockStop == nil || dataContainersBlockStart == nil || endLocation == nil {
            throw stateError.SourceError("No valid data containers block found.")
        }
        
        var newBlock = ""
        for buffer in experiment.buffers.1! {
            newBlock += "<container "
            newBlock += "size=\"\(buffer.size)\" "
            newBlock += "static=\"\(buffer.staticBuffer ? "true" : "false")\" "
            newBlock += "init=\""
            for (i, v) in buffer.toArray().enumerated() {
                if i > 0 {
                    newBlock += ","
                }
                newBlock += format(v)
            }
            newBlock += "\" "
            newBlock += ">"
            newBlock += buffer.name
            newBlock += "</container>\n"
        }
        let customTitle = "<state-title>\(customTitle.replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;"))</state-title>"
        return sourceStr![..<dataContainersBlockStart!.upperBound] + "\n" + newBlock + "\n" + sourceStr![dataContainersBlockStop!.lowerBound..<endLocation!.lowerBound] + "\n" + customTitle + "\n" + "</phyphox>"
    }
}