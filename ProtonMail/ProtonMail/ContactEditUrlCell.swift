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
    override func awakeFromNib() {
        super.awakeFromNib()
        self.valueField.delegate = self
        self.valueField.placeholder = NSLocalizedString("Url", comment: "default vcard types")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sepratorView.gradient()
    }
    
    func configCell(obj : ContactEditUrl, callback: ContactEditCellDelegate?, becomeFirstResponder: Bool = false) {
        self.url = obj
        
        typeLabel.text = self.url.newType.title
        valueField.text = self.url.newUrl
        
        self.delegate = callback
        
        if becomeFirstResponder {
            delay(0.25, closure: {
                self.valueField.becomeFirstResponder()
            })
        }
    }
    
    @IBAction func typeAction(_ sender: UIButton) {
        delegate?.pick(typeInterface: url, sender: self)
    }
}

extension ContactEditUrlCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.beginEditing(textField: textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)  {
        url.newUrl = valueField.text!
    }
}
