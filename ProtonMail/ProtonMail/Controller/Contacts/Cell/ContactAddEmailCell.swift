//
//  ContactAddEmailCell.swift
//  ProtonMail - Created on 2018/10/3.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import UIKit

class ContactAddEmailCell: UITableViewCell, AccessibleCell {
    fileprivate var email: ContactEditEmail!
    fileprivate var delegate: ContactEditCellDelegate?
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var valueField: UITextField!
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var separatorView: UIView!
    
    @IBAction func selectTypeTapped(_ sender: UIButton) {
        delegate?.pick(typeInterface: email, sender: self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.valueField.delegate = self
        self.valueField.placeholder = LocalString._contacts_email_address_placeholder
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        separatorView.gradient()
    }
    
    func configCell(obj: ContactEditEmail,
                    callback: ContactEditCellDelegate?,
                    becomeFirstResponder: Bool = false) {
        self.email = obj
        
        typeLabel.text = self.email.newType.title
        valueField.text = self.email.newEmail
        self.delegate = callback
        
        if becomeFirstResponder {
            delay(0.25, closure: {
                self.valueField.becomeFirstResponder()
            })
        }
        generateCellAccessibilityIdentifiers(self.valueField.placeholder!)
    }
}


extension ContactAddEmailCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.beginEditing(textField: textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)  {
        textField.text = textField.text?.trim()
        email.newEmail = valueField.text!
    }
}
