//
//  ContactTypeAddCustomCell.swift
//  Proton Mail - Created on 9/11/17.
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

import UIKit

final class ContactTypeAddCustomCell: UITableViewCell {

    @IBOutlet weak var value: UILabel!

    @IBOutlet weak var inputField: UITextField!

    func configCell(v: String) {
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
