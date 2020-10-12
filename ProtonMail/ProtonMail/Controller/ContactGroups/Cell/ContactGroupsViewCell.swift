//
//  ContactGroupsViewCell.swift
//  ProtonMail
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


import UIKit

protocol ContactGroupsViewCellDelegate : AnyObject {
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
    let normalColor = "#9497CE"
    
    private var labelID = ""
    private var name = ""
    private var count = 0
    private var color = ColorManager.defaultColor
    private weak var delegate: ContactGroupsViewCellDelegate?
    
    // the count of emails in a contact group
    // the assumption of this variable to work properly is that the contact group data won't be updated
    // mid-way through the contact editing process, e.g. we will sort of use the snapshot of the contact group
    // status for the entire duration of contact editing
    private var origCount: Int = 0
    
    // at the time that we started editing the contact, if the email is in this contact group
    // this variable should be set to true
    private var wasSelected: Bool = false
    
    @IBAction func sendEmailButtonTapped(_ sender: UIButton) {
        delegate?.sendEmailToGroup(ID: labelID, name: name)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setCount(_ count: Int) {
        self.count = count
        self.setDetailString()
    }
    
    private func setDetailString() {        
        if self.count <= 1 {
            self.detailLabel.text = String.init(format: LocalString._contact_groups_member_count_description,
                                                self.count)
        } else {
            self.detailLabel.text = String.init(format: LocalString._contact_groups_members_count_description,
                                                self.count)
        }
    }
    
    func config(labelID: String,
                name: String,
                queryString: String,
                count: Int,
                color: String,
                wasSelected: Bool,
                showSendEmailIcon: Bool,
                delegate: ContactGroupsViewCellDelegate? = nil) {
        // setup and save
        self.count = count
        self.origCount = count
        self.labelID = labelID
        self.name = name
        self.color = color
        self.delegate = delegate
        self.wasSelected = wasSelected
        
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
        
        groupImage.image = UIImage(named: "contact_groups_icon")
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
                
                groupImage.image = UIImage(named: "contact_groups_check")
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
