//
//  ContactEditField.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/25/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


final class ContactEditUrlCell: UITableViewCell {
    
    fileprivate var url : ContactEditUrl!
    fileprivate var delegate : ContactEditCellDelegate?
    
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var valueField: UITextField!
    
    @IBOutlet weak var sepratorView: UIView!
    
    fileprivate var isPaid : Bool = false
    override func awakeFromNib() {
        super.awakeFromNib()
        self.valueField.delegate = self
        self.valueField.placeholder = NSLocalizedString("Url", comment: "default vcard types")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sepratorView.gradient()
    }
    
    func configCell(obj : ContactEditUrl, paid: Bool, callback: ContactEditCellDelegate?, becomeFirstResponder: Bool = false) {
        self.url = obj
        self.isPaid = paid
        
        typeLabel.text = self.url.newType.title
        valueField.text = self.url.newUrl
        
        self.delegate = callback
        
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
        delegate?.pick(typeInterface: url, sender: self)
    }
}

extension ContactEditUrlCell: UITextFieldDelegate {
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
        url.newUrl = valueField.text!
    }
}
