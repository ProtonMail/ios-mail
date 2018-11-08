//
//  ContactGroupsViewCell.swift
//  ProtonMail
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

import UIKit

protocol ContactGroupsViewCellDelegate : AnyObject {
    func isMultiSelect() -> Bool
    func sendEmailToGroup(ID: String, name: String)
}

class ContactGroupsViewCell: UITableViewCell {
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
