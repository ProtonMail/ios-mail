//
//  ContactEditPhoneCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/24/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation

final class ContactEditPhoneCell: UITableViewCell {
    
    fileprivate var phone : ContactEditPhone!
    fileprivate var delegate : ContactEditCellDelegate?
    
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var valueField: UITextField!
    @IBOutlet weak var sepratorView: UIView!
    
    fileprivate var isPaid: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.valueField.delegate = self
        self.valueField.placeholder = NSLocalizedString("Phone number", comment: "contact placeholder")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sepratorView.gradient()
    }
    
    func configCell(obj : ContactEditPhone, paid: Bool, callback : ContactEditCellDelegate?, becomeFirstResponder: Bool = false) {
        self.phone = obj
        self.isPaid = paid
        self.delegate = callback
        
        typeLabel.text = self.phone.newType.title
        if self.isPaid {
            valueField.text = self.phone.newPhone
        } else {
            valueField.text = self.phone.newPhone.hiden()
        }
        
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
            delegate?.featureBlocked()
            return
        }
        delegate?.pick(typeInterface: phone, sender: self)
    }
}

extension ContactEditPhoneCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.beginEditing(textField: textField)
        guard self.isPaid else {
            self.delegate?.featureBlocked()
            return
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)  {
        guard self.isPaid else {
            delegate?.featureBlocked()
            return
        }
        
        phone.newPhone = valueField.text!
    }
}
