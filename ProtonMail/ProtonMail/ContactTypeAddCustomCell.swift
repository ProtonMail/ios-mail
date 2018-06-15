//
//  ContactTypeAddCustomCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/11/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


final class ContactTypeAddCustomCell: UITableViewCell {
    
    @IBOutlet weak var value: UILabel!
    
    @IBOutlet weak var inputField: UITextField!
    
    func configCell(v : String) {
        value.text = v
    }
    
    func setMark() {
        inputField.becomeFirstResponder()
        
        value.isHidden = true
        inputField.isHidden = false
        
    }
    
    func unsetMark() {
        inputField.resignFirstResponder()
        
        value.isHidden = false
        inputField.isHidden = true
        
        value.text = inputField.text
        
    }
    
    func getValue() -> String {
        return inputField.text ?? LocalString._contacts_custom_type
    }
    
    
    
}
