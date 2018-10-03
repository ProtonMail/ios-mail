//
//  ContactAddEmailCell.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/10/3.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class ContactAddEmailCell: UITableViewCell {
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
        email.newEmail = valueField.text!
    }
}
