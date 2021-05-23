//
//  ContactEditField.swift
//  ProtonMail - Created on 5/25/17.
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

import ProtonCore_UIFoundations

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
        self.valueField.placeholder = LocalString._contacts_vcard_url_placeholder
        self.valueField.tintColor = UIColorManager.TextHint
        backgroundColor = UIColorManager.BackgroundNorm
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sepratorView.gradient()
    }
    
    func configCell(obj : ContactEditUrl, paid: Bool, callback: ContactEditCellDelegate?, becomeFirstResponder: Bool = false) {
        self.url = obj
        self.isPaid = paid
        self.delegate = callback
        
        typeLabel.attributedText = NSAttributedString(string: self.url.newType.title,
                                                      attributes: FontManager.Default)
        valueField.attributedText = NSAttributedString(string: self.url.newUrl,
                                                       attributes: FontManager.Default)

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
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard self.isPaid else {
            self.delegate?.featureBlocked()
            return false
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.beginEditing(textField: textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)  {
        guard self.isPaid else {
            self.delegate?.featureBlocked()
            return
        }
        url.newUrl = valueField.attributedText?.string ?? ""
    }
}
