//
//  ContactGroupsViewCell.swift
//  Proton Mail
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

protocol ContactGroupsViewCellDelegate: AnyObject {
    func isMultiSelect() -> Bool
    func sendEmailToGroup(ID: String, name: String)
}

class ContactGroupsViewCell: UITableViewCell, AccessibleCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var groupImage: UIImageView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var sendButtonImage: UIImageView!

    let highlightedColor = "#BFBFBF"

    private var labelID = ""
    private var name = ""
    private var count = 0
    private var color = ColorManager.defaultColor
    private weak var delegate: ContactGroupsViewCellDelegate?

    @IBAction func sendEmailButtonTapped(_ sender: UIButton) {
        delegate?.sendEmailToGroup(ID: labelID, name: name)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = ColorProvider.BackgroundNorm
        sendButtonImage.image = IconProvider.paperPlaneHorizontal
        sendButtonImage.tintColor = ColorProvider.IconWeak
    }

    func setCount(_ count: Int) {
        self.count = count
        self.setDetailString()
    }
    
    private func setDetailString() {
        let text = String(format: LocalString._contact_groups_member_count_description, self.count)
        self.detailLabel.attributedText = text.apply(style: FontManager.DefaultSmallWeak)
    }

    func config(labelID: String,
                name: String,
                queryString: String,
                count: Int,
                color: String,
                showSendEmailIcon: Bool,
                delegate: ContactGroupsViewCellDelegate? = nil) {
        // setup and save
        self.count = count
        self.labelID = labelID
        self.name = name
        self.color = color
        self.delegate = delegate

        if showSendEmailIcon == false {
            self.sendButton.isHidden = true
            self.sendButtonImage.isHidden = true
        } else {
            self.sendButton.isHidden = false
            self.sendButtonImage.isHidden = false
        }

        // set cell data
        if let image = sendButton.imageView?.image {
            sendButton.imageView?.contentMode = .center
            sendButton.imageView?.image = UIImage.resize(image: image, targetSize: CGSize.init(width: 20, height: 20))
        }

        self.nameLabel.attributedText = .highlightedString(text: name,
                                                           search: queryString,
                                                           font: .highlightSearchTextForTitle)
        self.setDetailString()
        groupImage.setupImage(tintColor: UIColor.white,
                              backgroundColor: UIColor.init(hexString: color, alpha: 1),
                              borderWidth: 0,
                              borderColor: UIColor.white.cgColor)
        generateCellAccessibilityIdentifiers(name)
    }

    private func reset() {
        self.selectionStyle = .default

        groupImage.image = IconProvider.users
        groupImage.setupImage(contentMode: .center,
                              renderingMode: .alwaysTemplate,
                              scale: 0.5,
                              makeCircleBorder: true,
                              tintColor: UIColor.white,
                              backgroundColor: UIColor.init(hexString: color, alpha: 1),
                              borderWidth: 0,
                              borderColor: UIColor.white.cgColor)
    }

    func getLabelID() -> String {
        return labelID
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if let delegate = delegate {
            if delegate.isMultiSelect() && selected {
                // in multi-selection
                self.selectionStyle = .none

                groupImage.image = IconProvider.checkmark
                groupImage.setupImage(contentMode: .center,
                                      renderingMode: .alwaysOriginal,
                                      scale: 0.5,
                                      makeCircleBorder: true,
                                      tintColor: UIColor.white,
                                      backgroundColor: UIColor.white,
                                      borderWidth: 1.0,
                                      borderColor: UIColor.gray.cgColor)
            } else if delegate.isMultiSelect() == false && selected {
                // normal selection
                groupImage.backgroundColor = UIColor(hexColorCode: highlightedColor)
            } else {
                reset()
            }
        }
    }
}
