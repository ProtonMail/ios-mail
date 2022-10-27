//
//  ContactGroupEditViewCell.swift
//  Proton Mail - Created on 2018/9/6.
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
import UIKit

enum ContactGroupEditViewCellState {
    case detailView
    case editView
    case selectEmailView
    case none
}

struct ContactGroupEditViewCellColor {
    let text: UIColor
    let background: UIColor

    static let deselected: Self = .init(
        text: UIColor.white,
        background: ColorProvider.BrandNorm
    )

    static let selected: Self = .init(
        text: UIColor.gray,
        background: UIColor.white
    )
}

class ContactGroupEditViewCell: UITableViewCell, AccessibleCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var shortNameLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var deleteButtonImage: UIImageView!
    
    var emailID: EmailID = ""
    var name: String = ""
    var state: ContactGroupEditViewCellState = .none

    private weak var viewModel: ContactGroupEditViewModel?

    override func awakeFromNib() {
        super.awakeFromNib()

        shortNameLabel.layer.cornerRadius = shortNameLabel.frame.size.width / 2
    }

    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        if state == .editView,
            let viewModel = self.viewModel {
            viewModel.removeEmail(emailID: emailID)
        }
    }
    
    func config(emailID: EmailID,
                name: String,
                email: String,
                queryString: String,
                state: ContactGroupEditViewCellState,
                viewModel: ContactGroupEditViewModel? = nil) {
        self.emailID = emailID
        self.name = name
        self.state = state
        self.viewModel = viewModel
        deleteButton.setImage(
            IconProvider.crossCircle,
            for: .normal
        )
        deleteButton.imageView?.tintColor = ColorProvider.NotificationError

        // check and set the delete button
        if state != .editView {
            // the delete button is only for edit mode
            deleteButton.isHidden = true
            deleteButtonImage.isHidden = true
        } else {
            guard viewModel != nil else {
                // TODO: handle this
                return
            }
        }

        // set cell selectivity
        if state != .selectEmailView {
            // self.isUserInteractionEnabled = false // button won't work
            self.selectionStyle = .none
        }

        nameLabel.attributedText = NSMutableAttributedString.highlightedString(text: name,
                                                                               search: queryString,
                                                                               font: .highlightSearchTextForTitle)
        emailLabel.attributedText = NSMutableAttributedString.highlightedString(text: email,
                                                                                search: queryString,
                                                                                font: .highlightSearchTextForSubtitle)

        prepareShortName()
        generateCellAccessibilityIdentifiers(email)
    }

    private func prepareShortName() {
        shortNameLabel.text = name.initials()

        shortNameLabel.textColor = ContactGroupEditViewCellColor.deselected.text
        shortNameLabel.backgroundColor = ContactGroupEditViewCellColor.deselected.background

        shortNameLabel.layer.borderWidth = 0
        shortNameLabel.layer.borderColor = UIColor.white.cgColor
    }

    private func prepareCheckmark() {
        // setup image
        let attachment = NSTextAttachment()
        attachment.image = IconProvider.checkmark
        if let image = attachment.image {
            attachment.image = UIImage.resizeWithRespectTo(box: shortNameLabel.frame.size,
                                                           scale: 0.5,
                                                           image: image)
        }
        shortNameLabel.tintColor = ContactGroupEditViewCellColor.selected.text

        // add image (checkmark) to label
        let attachmentString = NSAttributedString(attachment: attachment)
        let myString = NSMutableAttributedString(string: "")
        myString.append(attachmentString)
        shortNameLabel.attributedText = myString

        // the circle
        shortNameLabel.backgroundColor = ContactGroupEditViewCellColor.selected.background

        shortNameLabel.layer.borderWidth = 1.0
        shortNameLabel.layer.borderColor = ContactGroupEditViewCellColor.selected.text.cgColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if state == .selectEmailView {
            if selected {
                // check mark
                prepareCheckmark()
            } else {
                // acronym
                prepareShortName()
            }
        }
    }

}
