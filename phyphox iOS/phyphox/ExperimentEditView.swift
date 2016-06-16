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
private let textFieldWidth: CGFloat = 60.0

final class ExperimentEditView: ExperimentViewModule<EditViewDescriptor>, UITextFieldDelegate, DataBufferObserver {
    let textField: UITextField
    let unitLabel: UILabel?
    
    var edited = false
    
    func formattedValue(raw: Double) -> String {
        return (descriptor.decimal ? String(Int(raw)) : String(raw))
    }
    
    required init(descriptor: EditViewDescriptor) {
        textField = UITextField()
        textField.backgroundColor = kLightBackgroundColor
        textField.textColor = kTextColor
        
        textField.returnKeyType = .Done
        
        textField.borderStyle = .RoundedRect
        
        if descriptor.unit != nil {
            unitLabel = {
                let l = UILabel()
                l.text = descriptor.unit
                l.textColor = kTextColor
                
                l.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
                
                return l
            }()
        }
        else {
            unitLabel = nil
        }
        
        super.init(descriptor: descriptor)
        
        descriptor.buffer.addObserver(self)
        
        textField.addTarget(self, action: #selector(hideKeyboard(_:)), forControlEvents: .EditingDidEndOnExit)
        
        updateTextField(textField, write: false)
        
        textField.delegate = self
        
        textField.addTarget(self, action: #selector(ExperimentEditView.textFieldChanged), forControlEvents: .EditingChanged)
        
        addSubview(textField)
        if unitLabel != nil {
            addSubview(unitLabel!)
        }
        
        label.textAlignment = NSTextAlignment.Right
    }
    
    override func unregisterFromBuffer() {
        descriptor.buffer.removeObserver(self)
    }
    
    func hideKeyboard(_: UITextField) {
        textField.endEditing(true)
    }
    
    func textFieldChanged() {
        edited = true
    }
    
    func textFieldDidEndEditing(_: UITextField) {
        if edited {
            updateTextField(textField, write: true)
            edited = false
        }
    }
    
    func dataBufferUpdated(buffer: DataBuffer) {
        updateTextField(textField, write: false, forceReadFromBuffer: true)
    }
    
    func updateTextField(_: UITextField, write: Bool, forceReadFromBuffer: Bool = false) {
        let val: Double
        
        if forceReadFromBuffer || textField.text?.characters.count == 0 || Double(textField.text!) == nil {
            val = descriptor.value
            
            textField.text = formattedValue(val*self.descriptor.factor)
        }
        else {
            let rawVal: Double
            
            if descriptor.decimal {
                if descriptor.signed {
                    rawVal = floor(Double(textField.text!)!)
                }
                else {
                    rawVal = floor(abs(Double(textField.text!)!))
                }
            }
            else {
                if descriptor.signed {
                    rawVal = Double(textField.text!)!
                }
                else {
                    rawVal = abs(Double(textField.text!)!)
                }
            }
            
            val = rawVal/self.descriptor.factor
            
            textField.text = formattedValue(rawVal)
        }
        
        if write {
            descriptor.buffer.replaceValues([val])
        }
    }
    
    override func sizeThatFits(size: CGSize) -> CGSize {
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
        
        let width = 2.0 * max(left, right)
        
        return CGSize(width: width, height: height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let h = label.sizeThatFits(self.bounds.size).height
        let h2 = textField.sizeThatFits(self.bounds.size).height
        let w = (self.bounds.size.width-spacing)/2.0
        
        label.frame = CGRect(origin: CGPoint(x: 0, y: (self.bounds.size.height-h)/2.0), size: CGSize(width: w, height: h))
        textField.frame = CGRect(origin: CGPoint(x: (self.bounds.size.width+spacing)/2.0, y: (self.bounds.size.height-h2)/2.0), size: CGSize(width: textFieldWidth, height: h2))
        
        if unitLabel != nil {
            let s3 = unitLabel!.sizeThatFits(self.bounds.size)
            unitLabel!.frame = CGRect(origin: CGPoint(x: CGRectGetMaxX(textField.frame)+spacing, y: (self.bounds.size.height-s3.height)/2.0), size: s3)
        }
    }
}