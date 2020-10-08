//
//  ContactEditEmailCell.swift
//  ProtonMail - Created on 5/4/17.
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


import Foundation



final class ContactEditEmailCell: UITableViewCell, AccessibleCell {
    
    fileprivate var email: ContactEditEmail!
    
    fileprivate var delegate: ContactEditCellDelegate?
    
    @IBOutlet weak var groupButton: UIButton!
    @IBOutlet weak var iconStackView: UIStackView!
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var valueField: UITextField!
    @IBOutlet weak var sepratorView: UIView!
    @IBOutlet weak var horizontalSeparator: UIView!
    
    var firstSetup = true
    
    func configCell(obj: ContactEditEmail,
                    callback: ContactEditCellDelegate?,
                    becomeFirstResponder: Bool = false) {
        self.email = obj
        
        
        typeButton.setTitle(self.email.newType.title,
                            for: .normal)
        valueField.text = self.email.newEmail
        self.delegate = callback
        
        if becomeFirstResponder {
            delay(0.25, closure: {
                self.valueField.becomeFirstResponder()
            })
        }
        
        // setup group icons
        prepareContactGroupIcons(cell: self,
                                 contactGroupColors: self.email.getCurrentlySelectedContactGroupColors(),
                                 iconStackView: iconStackView)
        
        if firstSetup {
            // setup gesture recognizer
            let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                              action: #selector(didTapGroupViewStack(sender:)))
            tapGestureRecognizer.numberOfTapsRequired = 1
            iconStackView.isUserInteractionEnabled = true
            iconStackView.addGestureRecognizer(tapGestureRecognizer)
            
            firstSetup = false
        }
        generateCellAccessibilityIdentifiers(LocalString._contacts_email_address_placeholder)
    }
    
    // called when the contact group selection view is dismissed
    func refreshHandler(updatedContactGroups: Set<String>)
    {
        email.updateContactGroups(updatedContactGroups: updatedContactGroups)
        prepareContactGroupIcons(cell: self,
                                 contactGroupColors: self.email.getCurrentlySelectedContactGroupColors(),
                                 iconStackView: iconStackView)
    }
    
    func getCurrentlySelectedContactGroupsID() -> Set<String> {
        return email.getCurrentlySelectedContactGroupsID()
    }
    

    @IBAction func didTapGroupButton(_ sender: UIButton) {
        delegate?.toSelectContactGroups(sender: self)
    }
    
    @objc func didTapGroupViewStack(sender: UITapGestureRecognizer) {
        delegate?.toSelectContactGroups(sender: self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.valueField.delegate = self
        self.valueField.placeholder = LocalString._contacts_email_address_placeholder
    }
    
    @IBAction func typeAction(_ sender: UIButton) {
        delegate?.pick(typeInterface: email, sender: self)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sepratorView.gradient()
        horizontalSeparator.gradient()
    }
}

extension ContactEditEmailCell: ContactCellShare {}

extension ContactEditEmailCell: UITextFieldDelegate {
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
