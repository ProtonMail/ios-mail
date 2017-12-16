//
//  ContactEditOrgCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/24/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation

final class ContactEditInformationCell: UITableViewCell {
    
    fileprivate var information : ContactEditInformation!
    fileprivate var delegate : ContactEditCellDelegate?
    
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var valueField: UITextField!
    
    @IBOutlet weak var sepratorView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.valueField.delegate = self
        self.typeButton.isHidden = true
        self.typeButton.isEnabled = false
        sepratorView.gradient()
    }
    
    func configCell(obj : ContactEditInformation, callback : ContactEditCellDelegate?) {
        self.information = obj
        
        typeLabel.text = self.information.infoType.type
        valueField.placeholder = self.information.infoType.type
        valueField.text = self.information.newValue
        
        self.delegate = callback
    }
    
    @IBAction func typeAction(_ sender: UIButton) {
        //delegate?.pick(typeInterface: org, sender: self)
    }
}

extension ContactEditInformationCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.beginEditing(textField: textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)  {
        information.newValue = valueField.text!
    }
}
