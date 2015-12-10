//
//  ExperimentDeserializer.swift
//  phyphox
//
//  Created by Jonas Gessner on 04.12.15.
//  Copyright © 2015 RWTH Aachen. All rights reserved.
//

import Foundation

func getElemetArrayFromValue(value: AnyObject) -> [AnyObject] {
    var values: [AnyObject] = []
    
    if value.isKindOfClass(NSMutableArray) {
        for item in (value as! NSMutableArray) {
            values.append(item)
        }
    }
    else if value.isKindOfClass(NSArray) {
        values.appendContentsOf(value as! Array)
    }
    else {
        values.append(value)
    }
    
    return values
}

func getElementsWithKey(xml: NSDictionary, key: String) -> [AnyObject]? {
    let read = xml[key]
    
    if let v = read {
        return getElemetArrayFromValue(v)
    }
    
    return nil
}

final class ExperimentDeserializer: NSObject {
    private var dictionary: NSDictionary!
    private let parser: NSXMLParser
    
    init(data: NSData) {
        parser = NSXMLParser(data: data)
        super.init()
    }
    
    init(inputStream: NSInputStream) {
        parser = NSXMLParser(stream: inputStream)
        super.init()
    }
    
    func deserialize() throws -> Experiment {
        XMLDictionaryParser.sharedInstance().attributesMode = XMLDictionaryAttributesMode.Dictionary
        
        dictionary = XMLDictionaryParser.sharedInstance().dictionaryWithParser(parser)
        
        let description = dictionary["description"] as! String
        let category = dictionary["category"] as! String
        let title = dictionary["title"] as! String
        
        if title != "Accelerometer" {
            throw SerializationError.GenericError
        }
        
        let dataContainers = dictionary["data-containers"] as! NSDictionary?
        let buffers = parseDataContainers(dataContainers)
        
        if buffers == nil || buffers.count == 0 {
            throw SerializationError.InvalidExperimentFile
        }
        
        let inputs = dictionary["input"] as! NSDictionary?
        let sensorInputs = parseInputs(inputs, buffers: buffers)
        
        let analysis = dictionary["analysis"] as! NSDictionary?
        parseAnalysis(analysis)
        
        let translations = dictionary["translations"] as! NSDictionary?
        parseTranslations(translations)
        
        let views = dictionary["views"] as! NSDictionary?
        parseViews(views)
        
        let export = dictionary["export"] as! NSDictionary?
        parseExports(export)
        
        let icon = dictionary["icon"] as! String?
        
        
        let experiment = Experiment(title: title, description: description, category: category, local: true)
        
        throw SerializationError.GenericError
    }
    
    func parseDataContainers(dataContainers: NSDictionary?) -> [String: DataBuffer]! {
        if dataContainers != nil {
            let parser = ExperimentDataContainersParser(dataContainers!)
            
            return parser.parse()
        }
        
        return nil
    }
    
    func parseExports(exports: NSDictionary?) {
        if (exports != nil) {
            let parser = ExperimentExportParser(exports!)
            
            parser.parse()
        }
    }
    
    func parseInputs(inputs: NSDictionary?, buffers: [String : DataBuffer]) -> [SensorInput]? {
        if (inputs != nil) {
            let parser = ExperimentInputsParser(inputs!)
            
            return parser.parse(buffers)
        }
        
        return nil
    }
    
    func parseAnalysis(analysis: NSDictionary?) {
        if (analysis != nil) {
            let parser = ExperimentAnalysisParser(analysis!)
            
            parser.parse()
        }
    }
    
    func parseTranslations(translations: NSDictionary?) {
        if (translations != nil) {
            let parser = ExperimentTranslationsParser(translations!)
            
            parser.parse()
        }
    }
    
    func parseViews(views: NSDictionary?) {
        if (views != nil) {
            let parser = ExperimentViewsParser(views!)
            
            parser.parse()
        }
    }
    
    func deserializeAsynchronous(completion: (experiment: Experiment?, error: SerializationError?) -> Void) {
        dispatch_async(serializationQueue) { () -> Void in
            do {
                let experiment = try self.deserialize()
                
                completion(experiment: experiment, error: nil)
            }
            catch {
                completion(experiment: nil, error: error as? SerializationError)
            }
        }
    }
}
