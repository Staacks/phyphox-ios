//
//  ButtonViewDescriptor.swift
//  phyphox
//
//  Created by Sebastian Kuhlen on 13.11.16.
//  Copyright © 2016 RWTH Aachen. All rights reserved.
//

import Foundation
import CoreGraphics

struct ButtonViewDescriptor: ViewDescriptor, Equatable {
    static func == (lhs: ButtonViewDescriptor, rhs: ButtonViewDescriptor) -> Bool {
        return lhs.label == rhs.label &&
            lhs.translation == rhs.translation &&
            lhs.dataFlow.elementsEqual(rhs.dataFlow, by: { (l, r) -> Bool in
                return l.input == r.input && l.output == r.output
            })
    }

    let dataFlow: [(input: ExperimentAnalysisDataIO, output: DataBuffer)]

    let label: String
    let translation: ExperimentTranslationCollection?

    init(label: String, translation: ExperimentTranslationCollection?, dataFlow: [(input: ExperimentAnalysisDataIO, output: DataBuffer)]) {
        self.dataFlow = dataFlow

        self.label = label
        self.translation = translation
    }
    
    func generateViewHTMLWithID(_ id: Int) -> String {
        return "<div style=\"font-size: 105%;\" class=\"buttonElement\" id=\"element\(id)\"><button onclick=\"$.getJSON('control?cmd=trigger&element=\(id)')\">\(localizedLabel)</button></div>"
    }
}
