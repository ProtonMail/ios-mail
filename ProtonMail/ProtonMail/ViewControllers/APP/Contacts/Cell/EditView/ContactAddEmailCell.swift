//
//  ContactAddEmailCell.swift
//  Proton Mail - Created on 2018/10/3.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_Foundations
import ProtonCore_UIFoundations

class ContactAddEmailCell: UITableViewCell, AccessibleCell {
    fileprivate var email: ContactEditEmail!
    fileprivate var delegate: ContactEditCellDelegate?
    @IBOutlet var typeLabel: UILabel!
    @IBOutlet var valueField: UITextField!
    @IBOutlet var typeButton: UIButton!
    @IBOutlet var separatorView: UIView!

    @IBAction func selectTypeTapped(_ sender: UIButton) {
        delegate?.pick(typeInterface: email, sender: self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.valueField.delegate = self
        self.valueField.placeholder = LocalString._contacts_email_address_placeholder
        backgroundColor = ColorProvider.BackgroundNorm
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        separatorView.gradient()
    }

    func configCell(obj: ContactEditEmail,
                    callback: ContactEditCellDelegate?,
                    becomeFirstResponder: Bool = false) {
        self.email = obj

        typeLabel.attributedText = NSAttributedString(string: self.email.newType.title,
                                                     attributes: FontManager.Default)
        valueField.attributedText = NSAttributedString(string: self.email.newEmail,
                                                       attributes: FontManager.Default)
        self.delegate = callback

        if becomeFirstResponder {
            delay(0.25, closure: {
                self.valueField.becomeFirstResponder()
            })
        }
        generateCellAccessibilityIdentifiers(self.valueField.placeholder!)
    }
}

extension ContactAddEmailCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.beginEditing(textField: textField)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.attributedText = NSAttributedString(string: textField.attributedText?.string.trim() ?? "",
                                                      attributes: FontManager.Default)
        email.newEmail = valueField.attributedText?.string ?? ""
    }
}
