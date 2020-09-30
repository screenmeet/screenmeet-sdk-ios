//
//  CodeView.swift
//  SupportHelperAppPrototype
//
//  Created by Vasyl Morarash on 20.12.2019.
//  Copyright © 2019 Projector Inc. All rights reserved.
//

import UIKit

@objc protocol CodeViewDelegate {
    
    func codeViewDidChange(codeView: CodeView)
    
    func codeViewFinishChange(codeView: CodeView)
}

final class CodeView: NibLoadedView {
    
    @IBOutlet weak var delegate: CodeViewDelegate?
    
    @IBOutlet private weak var stackView: UIStackView!
    
    var returnKeyTapHandler: (() -> Void)?
    
    var code: String {
        return fields.compactMap { $0.text }.joined()
    }
    
    var isComplete: Bool {
        return code.count == fieldsCount
    }
    
    private var fields: [CodeTextField] = []
    
    var font: UIFont = .systemFont(ofSize: 25.0)
    
    @IBInspectable var fieldSpacing: CGFloat = 5.0 {
        didSet { setupTextFields() }
    }
    
    @IBInspectable var fieldsCount: Int = 6 {
        didSet { setupTextFields() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTextFields()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextFields()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        calculateFieldWidth()
    }
    
    func setupTextFields() {
        fields.forEach { field in
            stackView.removeArrangedSubview(field)
            field.removeFromSuperview()
        }
        
        fields.removeAll()
        
        for _ in 0..<fieldsCount {
            addTextField()
        }
        
        stackView.spacing = fieldSpacing
    }
    
    func addTextField() {
        let text = CodeTextField()
        let isLast = (fields.count + 1) == fieldsCount
        text.delegate = self
        text.codeDelegate = self
        text.setup()

        text.tag = fields.count + 1
        text.returnKeyType = !isLast ? .next : .done
        text.enablesReturnKeyAutomatically = !isLast ? false : true
        text.font = font
        text.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        stackView.addArrangedSubview(text)
        fields.append(text)

        text.translatesAutoresizingMaskIntoConstraints = false
        text.fieldWidthConstraint = NSLayoutConstraint(item: text,
                                                       attribute: .width,
                                                       relatedBy: .equal,
                                                       toItem: nil,
                                                       attribute: .notAnAttribute,
                                                       multiplier: 1,
                                                       constant: 0)
        text.fieldHeightConstraint = NSLayoutConstraint(item: text,
                                                       attribute: .height,
                                                       relatedBy: .equal,
                                                       toItem: nil,
                                                       attribute: .notAnAttribute,
                                                       multiplier: 1,
                                                       constant: 0)
        text.fieldWidthConstraint?.priority = UILayoutPriority(rawValue: 999)
        text.fieldHeightConstraint?.priority = UILayoutPriority(rawValue: 999)
        if let fieldWidthConstraint = text.fieldWidthConstraint, let fieldHeightConstraint = text.fieldHeightConstraint {
            NSLayoutConstraint.activate([fieldWidthConstraint, fieldHeightConstraint])
        }
    }
    
    private func calculateFieldWidth() {
        let count = CGFloat(fieldsCount)
        let textFieldWidth = (frame.width - (fieldSpacing * (count - 1))) / count
        let textFieldHeight = textFieldWidth
        stackView.subviews.forEach { (text) in
            if let text = text as? CodeTextField {
                text.fieldWidthConstraint?.constant = textFieldWidth
                text.fieldHeightConstraint?.constant = textFieldHeight
            }
        }
        layoutIfNeeded()
    }
    
    func clear() {
        fields.forEach { (textField) in
            textField.text = ""
            textField.markInactive()
        }
    }
    
    func firstResponder() {
        let responder = (isComplete ? fields.last : fields.first)
        responder?.becomeFirstResponder()
    }
    
    func setCode(_ code: String) {
        let codeArray = code.compactMap { Int(String($0)) }
        
        if codeArray.count == fieldsCount {
            for i in 0..<fieldsCount {
                let textField = fields[i]
                let number = codeArray[i]
                textField.text = "\(number)"
                textField.markActive()
            }
        }
    }
    
    private func fieldWithTag(_ tag: Int) -> UITextField? {
        return viewWithTag(tag) as? UITextField
    }
    
    private func becomeFirstResponder(textField: UITextField) {
        guard let nextResponder = fieldWithTag(textField.tag + 1) else { return }
        nextResponder.becomeFirstResponder()
    }
}

extension CodeView: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        let firstEmptyField = fields.first { $0.text?.isEmpty ?? true }
        guard textField.text?.isEmpty ?? true else { return true }
        guard firstEmptyField == textField else {
            firstEmptyField?.becomeFirstResponder()
            return false
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        (textField as? CodeTextField)?.markActive()
        textField.selectAll(nil)
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField.text?.isEmpty ?? true {
            (textField as? CodeTextField)?.markInactive()
        }
        return true
    }
    
    @objc func textFieldDidChange(textField: UITextField) {
        delegate?.codeViewDidChange(codeView: self)
        
        guard textField.text?.isEmpty == false else { return }
        becomeFirstResponder(textField: textField)
        
        guard textField.tag == fields.last?.tag, isComplete else { return }
        delegate?.codeViewFinishChange(codeView: self)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard string.isEmpty || Int(string) != nil else { return false }
        guard let text = textField.text else { return true }
        
        let count = text.count + string.count - range.length
        let codeArray = string.compactMap { Int(String($0)) }
        
        if codeArray.count == fieldsCount {
            for i in 0..<fieldsCount {
                let textField = fields[i]
                let number = codeArray[i]
                textField.text = "\(number)"
                textField.markActive()
                textFieldDidChange(textField: textField)
            }
        }
        
        return count <= 1
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let isLast = textField.tag == fieldsCount
        // TODO: Disable return key for done type in case of invalid code
        guard !isLast || isComplete else { return false }
        
        if isLast {
            returnKeyTapHandler?()
        }
        becomeFirstResponder(textField: textField)
        
        return true
    }
}

extension CodeView: CodeTextFieldDelegate {
    
    func deleteBackwardPressed(textField: CodeTextField) {
        guard let text = textField.text, text.isEmpty, let nextResponder = fieldWithTag(textField.tag - 1) else { return }
        
        nextResponder.text = nil
        nextResponder.becomeFirstResponder()
        delegate?.codeViewDidChange(codeView: self)
    }
}
