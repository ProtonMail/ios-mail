//
//  ContactEditField.swift
//  ProtonMail - Created on 5/25/17.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation


final class ContactEditFieldCell: UITableViewCell {
    
    fileprivate var field : ContactEditField!
    fileprivate var delegate : ContactEditCellDelegate?
    
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var valueField: UITextField!
    
    @IBOutlet weak var sepratorView: UIView!
    
    fileprivate var isPaid : Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.valueField.delegate = self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sepratorView.gradient()
    }
    
    func configCell(obj : ContactEditField, paid: Bool, callback: ContactEditCellDelegate?, becomeFirstResponder: Bool = false) {
        self.field = obj
        self.isPaid = paid
        self.delegate = callback
    
        typeLabel.text = self.field.newType.title
        valueField.text = self.field.newField

        if self.isPaid {
            if becomeFirstResponder {
                delay(0.25, closure: {
                    self.valueField.becomeFirstResponder()
                })
            }
        }
    }
    
    @IBAction func typeAction(_ sender: UIButton) {
        guard self.isPaid else {
            self.delegate?.featureBlocked()
            return
        }
        delegate?.pick(typeInterface: field, sender: self)
    }
}

extension ContactEditFieldCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard self.isPaid else {
            self.delegate?.featureBlocked()
            return false
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.beginEditing(textField: textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)  {
        guard self.isPaid else {
            self.delegate?.featureBlocked()
            return
        }
        field.newField = valueField.text!
    }
}
