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

final class ContactEditFieldCell: UITableViewCell {

    fileprivate var field: ContactEditField!
    fileprivate var delegate: ContactEditCellDelegate?

    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var valueField: UITextField!

    @IBOutlet weak var sepratorView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.valueField.delegate = self
        self.valueField.tintColor = ColorProvider.TextHint
        backgroundColor = ColorProvider.BackgroundNorm
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        sepratorView.gradient()
    }

    func configCell(obj: ContactEditField, callback: ContactEditCellDelegate?, becomeFirstResponder: Bool = false) {
        self.field = obj
        self.delegate = callback

        typeLabel.attributedText = NSAttributedString(string: self.field.newType.title,
                                                      attributes: FontManager.Default)
        valueField.attributedText = NSAttributedString(string: self.field.newField,
                                                       attributes: FontManager.Default)

        if becomeFirstResponder {
            delay(0.25, closure: {
                self.valueField.becomeFirstResponder()
            })
        }
    }

    @IBAction func typeAction(_ sender: UIButton) {
        delegate?.pick(typeInterface: field, sender: self)
    }
}

extension ContactEditFieldCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.beginEditing(textField: textField)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        field.newField = valueField.attributedText?.string ?? ""
    }
}
