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
    
    var emailID: String?
    var name: String = ""
    var email: String = ""
    var shortName: String = ""
    var state: ContactGroupEditViewCellState = .none
    
    var viewModel: ContactGroupEditViewModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        shortNameLabel.layer.cornerRadius = 20.0
    }
    
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        if state == .editView,
            let viewModel = self.viewModel,
            let emailID = emailID {
            viewModel.removeEmail(emailID: emailID)
        }
    }
    
    func config(emailID: String? = nil,
                name: String,
                email: String,
                state: ContactGroupEditViewCellState,
                viewModel: ContactGroupEditViewModel? = nil) {
        self.emailID = emailID
        self.name = name
        self.email = email
        self.state = state
        self.viewModel = viewModel
        
        // check and set the delete button
        if state != .editView {
            deleteButton.isHidden = true // the delete button is only for edit mode
        } else {
            guard viewModel != nil else {
                // TODO: handle this
                fatalError("In editing mode, view model must be present")
            }
            
            guard emailID != nil else {
                // TODO: handle this
                fatalError("In editing mode, emailID must be present")
            }
        }
        
        // set cell selectivity
        if state != .selectEmailView {
            // self.isUserInteractionEnabled = false // button won't work
            self.selectionStyle = .none
        }
        
        nameLabel.text = name
        emailLabel.text = email
        
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
    
    // TODO: fix this
    private func prepareCheckmark() {        
        shortNameLabel.text = "v" // lol
        
        shortNameLabel.textColor = ContactGroupEditViewCellColor.selected.text
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
