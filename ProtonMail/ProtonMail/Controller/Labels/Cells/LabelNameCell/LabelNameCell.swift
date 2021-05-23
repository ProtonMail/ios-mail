//
//  LabelNameCell .swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

import UIKit
import ProtonCore_UIFoundations

protocol LabelNameDelegate: AnyObject {
    func nameChanged(name: String)
}

final class LabelNameCell: UITableViewCell {

    @IBOutlet private var nameField: UITextField!
    private weak var delegate: LabelNameDelegate?
    private let maximum: Int = 100

    override func awakeFromNib() {
        super.awakeFromNib()
        let padding = UIView(frame: .init(x: 0, y: 0, width: 16, height: 96))
        self.nameField.delegate = self
        self.nameField.backgroundColor = .clear
        self.nameField.leftView = padding
        self.nameField.leftViewMode = .always
        self.contentView.backgroundColor = UIColorManager.BackgroundNorm
    }

    func config(name: String, type: PMLabelType, delegate: LabelNameDelegate?) {
        self.nameField.text = name
        self.delegate = delegate

        let labelPlaceHolder = LocalString._labels_label_name_text
        let folderPlaceHolder = LocalString._labels_folder_name_text
        self.nameField.placeholder = type == .folder ? folderPlaceHolder: labelPlaceHolder
    }
}

extension LabelNameCell: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard var text = textField.text,
              let textRange = Range(range, in: text) else {
            return false
        }

        text.replaceSubrange(textRange, with: string)
        if text.count <= self.maximum {
            self.delegate?.nameChanged(name: text)
            return true
        }
        return false
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
