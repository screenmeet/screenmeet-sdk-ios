//
//  CodeTextField.swift
//  SupportHelperAppPrototype
//
//  Created by Vasyl Morarash on 23.12.2019.
//  Copyright © 2019 Projector Inc. All rights reserved.
//

import UIKit

@objc protocol CodeTextFieldDelegate {
    
    func deleteBackwardPressed(textField: CodeTextField)
}

final class CodeTextField: UITextField {
    
    @IBOutlet weak var codeDelegate: CodeTextFieldDelegate?
    
    var fieldWidthConstraint: NSLayoutConstraint?
    
    var fieldHeightConstraint: NSLayoutConstraint?
    
    override func deleteBackward() {
        codeDelegate?.deleteBackwardPressed(textField: self)
        super.deleteBackward()
    }
    
    func setup() {
        textAlignment = .center
        contentVerticalAlignment = .center
        contentHorizontalAlignment = .center
        backgroundColor = .clear
        borderStyle = .none
        keyboardType = .numberPad
        tintColor = textColor
        layer.masksToBounds = false
        layer.cornerRadius = 5
        layer.borderWidth = 0.25
        layer.borderColor = UIColor.lightGray.cgColor
    }
    
    func markActive() {
        layer.borderWidth = 2
        layer.borderColor = UIColor.screenMeetColor.cgColor
    }
    
    func markInactive() {
        layer.borderWidth = 0.25
        layer.borderColor = UIColor.lightGray.cgColor
    }
}

extension UIColor {
    
    static var screenMeetColor = UIColor(red: 253 / 255, green: 167 / 255, blue: 87 / 255, alpha: 1)
}
