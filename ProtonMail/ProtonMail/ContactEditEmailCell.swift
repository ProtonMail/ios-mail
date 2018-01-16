//
//  ContactEditEmailCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/4/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation



final class ContactEditEmailCell: UITableViewCell {
    
    fileprivate var email : ContactEditEmail!
    
    fileprivate var delegate : ContactEditCellDelegate?
    
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var valueField: UITextField!
    @IBOutlet weak var sepratorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.valueField.delegate = self
        self.valueField.placeholder = NSLocalizedString("Email address", comment: "contact placeholder")
    }
    
    func configCell(obj : ContactEditEmail, callback : ContactEditCellDelegate?) {
        self.email = obj
        
        typeLabel.text = self.email.newType.title
        valueField.text = self.email.newEmail
        
        self.delegate = callback
    }
    
    @IBAction func typeAction(_ sender: UIButton) {
        delegate?.pick(typeInterface: email, sender: self)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sepratorView.gradient()
    }
}

extension ContactEditEmailCell: UITextFieldDelegate {
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
