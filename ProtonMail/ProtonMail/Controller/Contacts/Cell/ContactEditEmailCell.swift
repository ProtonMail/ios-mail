//
//  ContactEditEmailCell.swift
//  ProtonMail - Created on 5/4/17.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation



final class ContactEditEmailCell: UITableViewCell {
    
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
        email.newEmail = valueField.text!
    }
}
