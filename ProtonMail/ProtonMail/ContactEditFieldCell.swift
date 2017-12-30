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
    override func awakeFromNib() {
        super.awakeFromNib()
        self.valueField.delegate = self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sepratorView.gradient()
    }
    
    func configCell(obj : ContactEditField, callback: ContactEditCellDelegate?) {
        self.field = obj
        
        typeLabel.text = self.field.newType.title
        valueField.text = self.field.newField
        
        self.delegate = callback
    }
    
    @IBAction func typeAction(_ sender: UIButton) {
        delegate?.pick(typeInterface: field, sender: self)
    }
}

extension ContactEditFieldCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.beginEditing(textField: textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)  {
        field.newField = valueField.text!
    }
}
