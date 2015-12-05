//
//  DataBuffer.swift
//  phyphox
//
//  Created by Jonas Gessner on 05.12.15.
//  Copyright © 2015 RWTH Aachen. All rights reserved.
//

import Foundation

/**
 Data buffer used for raw or processed data from sensors.
 */
class DataBuffer: NSObject, SequenceType {
    let name: String
    let size: UInt64
    var staticBuffer: Bool = false
    var count: UInt64 {
        get {
            return queue.count
        }
    }
    
    private let queue: Queue<Double>
    
    init(name: String, size: UInt64) {
        self.name = name
        self.size = size
        queue = Queue<Double>()
        super.init()
    }
    
    func generate() -> AnyGenerator<Double> {
        return queue.generate()
    }
    
    var lastValue: Double? {
        get {
            return queue.tail.value
        }
    }
    
    func append(value: Double!) {
        if (value == nil) {
            return;
        }
        
        if (count >= size) {
            queue.dequeue()
        }
        
        queue.enqueue(value)
    }
    
    func clear() {
        if (!staticBuffer) {
            queue.clear()
        }
    }
    
    func appendFromArray(values: [Double]) {
        for value in values {
            append(value)
        }
    }
    
    func toArray() -> [Double]? {
        return queue.toArray()
    }
}
