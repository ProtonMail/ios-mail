//
//  MailboxMessageCell.swift
//  ProtonMail - Created on 9/4/15.
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
import MCSwipeTableViewCell

class MailboxMessageCell: MCSwipeTableViewCell, AccessibleCell {
    /**
    *  Constants
    */
    struct Constant {
        static let identifier = "MailboxMessageCell"
    }
    
    fileprivate let kCheckboxWidth : CGFloat = 36.0
    fileprivate let kIconsWidth : CGFloat = 18.0
    fileprivate let kReplyWidth : CGFloat = 20.0
    @IBOutlet weak var checkboxWidth: NSLayoutConstraint!
    @IBOutlet weak var timeWidth: NSLayoutConstraint!
    @IBOutlet weak var starWidth: NSLayoutConstraint!
    @IBOutlet weak var attachmentWidth: NSLayoutConstraint!
    @IBOutlet weak var lockWidth: NSLayoutConstraint!
    @IBOutlet weak var expirationWidth: NSLayoutConstraint!
    
    @IBOutlet weak var replyWidth: NSLayoutConstraint!
    @IBOutlet weak var forwardWidth: NSLayoutConstraint!
    
    @IBOutlet weak var locationWidth: NSLayoutConstraint!
    @IBOutlet weak var loctionRightSpace: NSLayoutConstraint!
    
    //var leftLabel : UILabel?
    @IBOutlet weak var labelsView: LabelsView!
    
    @IBOutlet weak var locationLabel: UILabel!
    // MARK : vars
    fileprivate var isChecked : Bool = false
    
    @IBOutlet weak var checkboxButton: UIButton!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var time: UILabel!
    @available(*, deprecated) @IBOutlet weak var lockImage: UIImageView!
    @IBOutlet weak var replyImage: UIImageView!
    
    @IBOutlet weak var attachmentImage: UIImageView!
    @IBOutlet weak var expirationImage: UIImageView!
    @IBOutlet weak var starImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()

        self.checkboxWidth.constant = 0.0
        self.checkboxButton.isAccessibilityElement = false // TODO: check that this action is included into accessibility actions
        
        self.locationLabel.layer.cornerRadius = 2
        
        self.lockImage.isHidden = true
        self.lockWidth.constant = 0.0
    }
    
    private var accessibilityActionBoxes: [MCSwipeCompletionBlockBox] = []
    private func updateAccessibilityCustomActions() {
        self.accessibilityActionBoxes = [completionBlock1, completionBlock2, completionBlock3, completionBlock4].compactMap { MCSwipeCompletionBlockBox($0, self) }
        let labels = [view1, view2, view3, view4].compactMap{ $0 as? UILabel }
        let newPairs = zip(labels, self.accessibilityActionBoxes)
        
        self.accessibilityCustomActions = newPairs.compactMap { label, box in
            return UIAccessibilityCustomAction(name: label.text ?? "",
                                               target: box,
                                               selector: #selector(MCSwipeCompletionBlockBox.execute(_:_:_:)))
        }
    }
    
    override func setSwipeGestureWith(_ view: UIView!, color: UIColor!, mode: MCSwipeTableViewCellMode, state: MCSwipeTableViewCellState, completionBlock: MCSwipeCompletionBlock!) {
        super.setSwipeGestureWith(view, color: color, mode: mode, state: state, completionBlock: completionBlock)
        self.updateAccessibilityCustomActions()
    }
    
    private func updateAccessibilityLabel() {
        self.accessibilityLabel = """
            \(self.title.text ?? ""),
            \(self.labelsView.sender),
            \(self.time.text ?? ""),
            \(self.attachmentImage.isHidden ? "" : LocalString._attachments)
            """
        
        var extendedLabel = ""
        if !self.locationLabel.isHidden, let location = self.locationLabel.text {
            extendedLabel += ", " + LocalString._folder + ": " + location
        }
        if let labels = self.labelsView.labels, !labels.isEmpty {
            let names = labels.map { $0.name }
            extendedLabel += ", " + LocalString._labels + ": " + names.joined(separator: ",")
        }
        if !self.starImage.isHidden {
            extendedLabel += ", " + LocalString._starred
        }
        if !self.expirationImage.isHidden {
            extendedLabel += ", " + LocalString._expires
        }
        self.accessibilityHint = extendedLabel
    }
    
    // MARK : funcs
    
    func showCheckboxOnLeftSide() {
        self.checkboxWidth.constant = kCheckboxWidth
        self.checkboxButton.isHidden = false
        self.setNeedsUpdateConstraints()
    }
    
    func hideCheckboxOnLeftSide() {
        self.checkboxWidth.constant = 0.0
        self.checkboxButton.isHidden = true
        self.setNeedsUpdateConstraints()
    }
    
    func setCellIsChecked(_ checked: Bool) {
        self.isChecked = checked
        checkboxButton.isSelected = checked
    }
    
    func isCheckBoxSelected() -> Bool {
        return self.isChecked
    }
    
    func changeStyleToReadDesign() {
        self.accessibilityValue = nil
        self.backgroundColor = UIColor.ProtonMail.MessageCell_Read_Color
        self.title.font = Fonts.h4.light
        self.time.font = Fonts.h6.light
    }
    
    func changeStyleToUnreadDesign() {
        self.accessibilityValue = LocalString._unread
        self.backgroundColor = UIColor.ProtonMail.MessageCell_UnRead_Color
        self.title.font = Fonts.h4.medium
        self.time.font = Fonts.h6.medium
    }
    
    
    // MARK: - Cell configuration
    func configureCell(_ message: Message, showLocation : Bool, ignoredTitle: String, replacingEmails: [Email]) {
        self.accessibilityActionBoxes = []
        self.title.text = message.subject
    
        var title = ""
        if showLocation {
            title = message.getShowLocationNameFromLabels(ignored: ignoredTitle) ?? ""
        }
        
        if showLocation && !title.isEmpty {
            self.locationLabel.text = " \(title) "
            self.locationLabel.isHidden = false
            locationWidth.constant = self.locationLabel.sizeThatFits(CGSize.zero).width
            loctionRightSpace.constant = 4.0
        } else {
            self.locationLabel.isHidden = true
            locationWidth.constant = 0.0
            loctionRightSpace.constant = 0.0
        }
        
        if message.numAttachments.int32Value > 0 {
            self.attachmentImage.isHidden = false
            self.attachmentWidth.constant = kIconsWidth
        } else {
            self.attachmentImage.isHidden = true
            self.attachmentWidth.constant = 0
        }
        
        if message.starred {
            self.starImage.isHidden = false
            self.starWidth.constant = self.kIconsWidth
        } else {
            self.starImage.isHidden = true
            self.starWidth.constant = 0
        }
        
        if message.expirationTime != nil {
            self.expirationImage.isHidden = false
            self.expirationWidth.constant = self.kIconsWidth
        } else {
            self.expirationImage.isHidden = true
            self.expirationWidth.constant = 0
        }
        
        let predicate = NSPredicate(format: "labelID MATCHES %@", "(?!^\\d+$)^.+$")
        let tempLabels = message.labels.filtered(using: predicate) //TODO:: later need add lables exsiting check 
        var labels : [Label] = []
        for vowel in tempLabels {
            let label = vowel as! Label
            labels.append(label)
        }
        
        if message.contains(label: Message.Location.sent) {
            labelsView.configLables( message.allEmailAddresses(replacingEmails), labels: labels)
        } else if message.draft {
            labelsView.configLables( message.allEmailAddresses(replacingEmails), labels: labels)
        } else {
            labelsView.configLables( message.displaySender(replacingEmails), labels: labels)
        }
        
        if message.unRead {
            changeStyleToUnreadDesign()
        } else {
            changeStyleToReadDesign()
        }
        
        if  message.repliedAll {
            showReplyAll()
        }
        else if message.replied {
            showReply()
        }
        else {
            hideReply()
        }
        
        if  message.forwarded {
            showForward()
        } else {
            hideForward()
        }
        
        if !message.isSending, let t : Date = message.time, let displayString = NSDate.stringForDisplay(from: t) {
            self.time.text = " \(displayString)"
        } else if message.isSending {
            self.time.text = " \(LocalString._mailbox_draft_is_sending)"
        } else {
            self.time.text = " "
        }
        
        timeWidth.constant = self.time.sizeThatFits(CGSize.zero).width
        
        self.updateAccessibilityLabel()
        self.setNeedsUpdateConstraints()
        generateCellAccessibilityIdentifiers(message.subject)
    }
    fileprivate func updateLables (_ labelView : LabelDisplayView, label:Label?) {
        if let label = label {
            if label.name.isEmpty || label.color.isEmpty {
                labelView.isHidden = true
            } else {
                labelView.isHidden = false
                labelView.labelTitle = label.name
                labelView.LabelTintColor = UIColor(hexString: label.color, alpha: 1.0)
            }
        } else {
            labelView.isHidden = true
        }
    }
    
    func showReply() {
        self.replyWidth.constant = kReplyWidth
        self.replyImage.image = UIImage(named: "mail_replied")
    }
    
    func showReplyAll() {
        self.replyWidth.constant = kReplyWidth
        self.replyImage.image = UIImage(named: "mail_repliedall")
        
    }
    
    func hideReply() {
        self.replyWidth.constant = 0
    }
    
    func showForward() {
        self.forwardWidth.constant = kReplyWidth
    }
    
    func hideForward() {
        self.forwardWidth.constant = 0.0
    }
}

extension Message {
    func displaySender(_ replacingEmails: [Email]) -> String {
        guard let sender = senderContactVO else {
            assert(false, "Sender with no name or address")
            return ""
        }
        
        // will this be deadly slow?
        let email = replacingEmails.first { $0.email == sender.email }
        if let contact = email?.contact {
            return contact.name
        }
        
        return sender.name.isEmpty ? sender.email : sender.name
    }
    
    func allEmailAddresses(_ replacingEmails: [Email]) -> String {
        let lists: [String] = self.allEmails.map { address in
            replacingEmails.first(where: { $0.email == address })?.name ?? address
        }
        if lists.isEmpty {
            return ""
        }
        return lists.joined(separator: ",")
    }
}
