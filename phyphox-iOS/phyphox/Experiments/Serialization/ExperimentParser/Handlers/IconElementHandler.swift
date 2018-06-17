//
//  IconElementHandler.swift
//  phyphox
//
//  Created by Jonas Gessner on 11.04.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation

extension RawRepresentable where RawValue == String, Self: LosslessStringConvertible {
    var description: String {
        return rawValue
    }
}

final class IconElementHandler: ResultElementHandler, ChildlessElementHandler {
    typealias Result = ExperimentIcon

    var results = [Result]()

    func beginElement(attributeContainer: XMLElementAttributeContainer) throws {
    }

    // Bug in Swift 4.1 compiler (https://bugs.swift.org/browse/SR-7153). Make private again when compiling with Swift 4.2
    /*private*/ enum Attribute: String, XMLAttributeKey {
        case format
    }

    private enum Format: String {
        case base64
        case string
    }

    func endElement(with text: String, attributeContainer: XMLElementAttributeContainer) throws {
        guard !text.isEmpty else { throw XMLElementParserError.missingText }

        let attributes = attributeContainer.attributes(keyedBy: Attribute.self)

        let format: Format = try attributes.optionalAttribute(for: .format) ?? .string

        switch format {
        case .base64:
            guard let data = Data(base64Encoded: text, options: []) else { throw XMLElementParserError.unreadableData }

            if let image = UIImage(data: data) {
                results.append(.image(image))
            }
        case .string:
            results.append(.string(text))
        }
    }
}