//
//  ExperimentEditView.swift
//  phyphox
//
//  Created by Jonas Gessner on 12.01.16.
//  Copyright © 2016 Jonas Gessner. All rights reserved.
//  By Order of RWTH Aachen.
//

import UIKit

private let spacing: CGFloat = 10.0
private let textFieldWidth: CGFloat = 100.0

final class ExperimentEditView: ExperimentViewModule<EditViewDescriptor>, UITextFieldDelegate {
    let textField: UITextField
    let unitLabel: UILabel?
    
    var edited = false
    
    func formattedValue(_ raw: Double) -> String {
        return (descriptor.decimal ? String(raw) : String(Int(raw)))
    }
    
    required init(descriptor: EditViewDescriptor) {
        textField = UITextField()
        textField.backgroundColor = kLightBackgroundColor
        textField.textColor = kTextColor
        
        textField.returnKeyType = .done
        
        textField.borderStyle = .roundedRect
        
        if descriptor.unit != nil {
            unitLabel = {
                let l = UILabel()
                l.text = descriptor.unit
                l.textColor = kTextColor
                
                l.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.subheadline)
                
                return l
            }()
        }
        else {
            unitLabel = nil
        }
        
        super.init(descriptor: descriptor)

        registerInputBuffer(descriptor.buffer)

        textField.addTarget(self, action: #selector(hideKeyboard(_:)), for: .editingDidEndOnExit)

        textField.delegate = self
        
        textField.addTarget(self, action: #selector(ExperimentEditView.textFieldChanged), for: .editingChanged)
        
        addSubview(textField)
        if let unitLabel = unitLabel {
            addSubview(unitLabel)
        }
        
        label.textAlignment = NSTextAlignment.right
    }
    
    @objc func hideKeyboard(_: UITextField) {
        textField.endEditing(true)
    }
    
    @objc func textFieldChanged() {
        edited = true
    }
    
    func textFieldDidEndEditing(_: UITextField) {
        if edited {
            edited = false

            let rawValue: Double

            if descriptor.decimal {
                if descriptor.signed {
                    rawValue = Double(textField.text ?? "") ?? 0
                }
                else {
                    rawValue = abs(Double(textField.text ?? "") ?? 0)
                }
            }
            else {
                if descriptor.signed {
                    rawValue = floor(Double(textField.text ?? "") ?? 0)
                }
                else {
                    rawValue = floor(abs(Double(textField.text ?? "") ?? 0))
                }
            }

            var value = rawValue/descriptor.factor

            if (descriptor.min.isFinite && value < descriptor.min) {
                value = descriptor.min
            }
            if (descriptor.max.isFinite && value > descriptor.max) {
                value = descriptor.max
            }

            textField.text = formattedValue(rawValue)

            descriptor.buffer.replaceValues([value])
        }
    }
    
    override func update() {
        let value = descriptor.value
        let rawValue = value * descriptor.factor

        textField.text = formattedValue(rawValue)

        super.update()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        //We want to have the gap between label and value centered, so we require atwice the width of the larger half
        let s1 = label.sizeThatFits(size)
        var s2 = textField.sizeThatFits(size)
        s2.width = textFieldWidth
        
        var height = max(s1.height, s2.height)
        
        let left = s1.width + spacing/2.0
        var right = s2.width + spacing/2.0
        
        if unitLabel != nil {
            let s3 = unitLabel!.sizeThatFits(size)
            right += (spacing+s3.width)
            height = max(height, s3.height)
        }
        
        let width = min(2.0 * max(left, right), size.width)
        
        return CGSize(width: width, height: height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let h = label.sizeThatFits(self.bounds.size).height
        let h2 = textField.sizeThatFits(self.bounds.size).height
        let w = (self.bounds.size.width-spacing)/2.0
        
        label.frame = CGRect(origin: CGPoint(x: 0, y: (self.bounds.size.height-h)/2.0), size: CGSize(width: w, height: h))
        
        var actualTextFieldWidth = textFieldWidth
        
        if unitLabel != nil {
            let s3 = unitLabel!.sizeThatFits(self.bounds.size)
            if actualTextFieldWidth + s3.width + spacing > w {
               actualTextFieldWidth = w - s3.width - spacing
            }
            unitLabel!.frame = CGRect(origin: CGPoint(x: (self.bounds.size.width+spacing)/2.0+actualTextFieldWidth+spacing, y: (self.bounds.size.height-s3.height)/2.0), size: s3)
        }
        
        textField.frame = CGRect(origin: CGPoint(x: (self.bounds.size.width+spacing)/2.0, y: (self.bounds.size.height-h2)/2.0), size: CGSize(width: actualTextFieldWidth, height: h2))
    }
}
