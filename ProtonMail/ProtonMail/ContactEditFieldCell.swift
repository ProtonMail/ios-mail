//
//  ContactEditField.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/25/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

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
        if self.isPaid {
            valueField.text = self.field.newField
        } else {
            valueField.text = self.field.newField.hiden()
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.beginEditing(textField: textField)
        guard self.isPaid else {
            self.delegate?.featureBlocked()
            return
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)  {
        guard self.isPaid else {
            self.delegate?.featureBlocked()
            return
        }
        field.newField = valueField.text!
    }
}
