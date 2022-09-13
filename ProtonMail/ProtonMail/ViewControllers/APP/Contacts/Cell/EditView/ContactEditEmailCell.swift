//
//  ContactEditEmailCell.swift
//  Proton Mail - Created on 5/4/17.
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

final class ContactEditEmailCell: UITableViewCell, AccessibleCell {
    fileprivate var email: ContactEditEmail!

    fileprivate weak var delegate: ContactEditCellDelegate?

    @IBOutlet var groupButton: UIButton!
    @IBOutlet var iconStackView: UIStackView!
    @IBOutlet var typeButton: UIButton!
    @IBOutlet var valueField: UITextField!
    @IBOutlet var sepratorView: UIView!
    @IBOutlet var horizontalSeparator: UIView!

    var firstSetup = true

    func configCell(obj: ContactEditEmail,
                    callback: ContactEditCellDelegate?,
                    becomeFirstResponder: Bool = false) {
        backgroundColor = ColorProvider.BackgroundNorm

        self.email = obj

        typeButton.setAttributedTitle(self.email.newType.title.apply(style: .DefaultSmall), for: .normal)

        groupButton.setAttributedTitle("Group".apply(style: .DefaultSmall), for: .normal)

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
    func refreshHandler(updatedContactGroups: Set<String>) {
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
        self.valueField.tintColor = ColorProvider.TextHint
        self.valueField.placeholder = LocalString._contacts_email_address_placeholder
        self.valueField.font = FontManager.Default[.font] as? UIFont
        self.valueField.textColor = FontManager.Default[.foregroundColor] as? UIColor
    }

    @IBAction func typeAction(_ sender: UIButton) {
        delegate?.pick(typeInterface: email)
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

    func textFieldDidEndEditing(_ textField: UITextField) {
        email.newEmail = valueField.text ?? ""
    }
}
