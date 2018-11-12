//
//  ContactGroupEditViewCell.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/9/6.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

enum ContactGroupEditViewCellState
{
    case detailView
    case editView
    case selectEmailView
    
    case none
}

struct ContactGroupEditViewCellColor
{
    static let deselected = (text: UIColor.white,
                      background: UIColor(hexString: "9497ce", alpha: 1.0))
    static let selected = (text: UIColor.gray,
                    background: UIColor.white)
}

class ContactGroupEditViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var shortNameLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var deleteButtonImage: UIImageView!
    
    var emailID: String = ""
    var name: String = ""
    var email: String = ""
    var shortName: String = ""
    var state: ContactGroupEditViewCellState = .none
    
    var viewModel: ContactGroupEditViewModel?
    
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
    
    func config(emailID: String,
                name: String,
                email: String,
                queryString: String,
                state: ContactGroupEditViewCellState,
                viewModel: ContactGroupEditViewModel? = nil) {
        self.emailID = emailID
        self.name = name
        self.email = email
        self.state = state
        self.viewModel = viewModel
        
        // check and set the delete button
        if state != .editView {
            // the delete button is only for edit mode
            deleteButton.isHidden = true
            deleteButtonImage.isHidden = true
        } else {
            guard viewModel != nil else {
                // TODO: handle this
//                fatalError("In editing mode, view model must be present")
                PMLog.D("In editing mode, view model must be present")
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
    }
    
    private func prepareShortName() {
        if name.count > 0 {
            shortName = String(name[name.startIndex])
        } else {
            shortName = ""
        }
        shortNameLabel.text = self.shortName
        
        shortNameLabel.textColor = ContactGroupEditViewCellColor.deselected.text
        shortNameLabel.backgroundColor = ContactGroupEditViewCellColor.deselected.background
        
        shortNameLabel.layer.borderWidth = 0
        shortNameLabel.layer.borderColor = UIColor.white.cgColor
    }
    
    private func prepareCheckmark() {
        // setup image
        let attachment = NSTextAttachment()
        attachment.image = UIImage(named: "contact_groups_check")
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
