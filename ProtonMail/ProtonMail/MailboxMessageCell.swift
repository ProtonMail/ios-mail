//
//  MailboxMessageCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/4/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit


class MailboxMessageCell: MCSwipeTableViewCell {
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
    @IBOutlet weak var lockImage: UIImageView!
    @IBOutlet weak var replyImage: UIImageView!
    
    @IBOutlet weak var starImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        checkboxWidth.constant = 0.0
        
        locationLabel.layer.cornerRadius = 2;
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
        locationLabel.backgroundColor = UIColor.gray
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        locationLabel.backgroundColor = UIColor.gray
    }
    
    
    // MARK : funcs
    
    func showCheckboxOnLeftSide() {
        self.checkboxWidth.constant = kCheckboxWidth
        //self.titleLeadingConstraint.constant = kTitleMarginLeft
        self.setNeedsUpdateConstraints()
    }
    
    func hideCheckboxOnLeftSide() {
        self.checkboxWidth.constant = 0.0
        //self.titleLeadingConstraint.constant = 0.0
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
        self.contentView.backgroundColor = UIColor.ProtonMail.MessageCell_Read_Color
        self.title.font = UIFont.robotoLight(size: UIFont.Size.h4)
        //self.sender.font = UIFont.robotoLight(size: UIFont.Size.h6)
        self.time.font = UIFont.robotoLight(size: UIFont.Size.h6)
    }
    
    func changeStyleToUnreadDesign() {
        self.contentView.backgroundColor = UIColor.ProtonMail.MessageCell_UnRead_Color
        self.title.font = UIFont.robotoMedium(size: UIFont.Size.h4)
        //self.sender.font = UIFont.robotoMedium(size: UIFont.Size.h6)
        self.time.font = UIFont.robotoMedium(size: UIFont.Size.h6)
        
    }
    
    
    // MARK: - Cell configuration
    func configureCell(_ message: Message, showLocation : Bool, ignoredTitle: String) {
        self.title.text = message.subject
    
        var title = ""
        if showLocation {
            title = message.getShowLocationNameFromLabels(ignored: ignoredTitle) ?? ""
        }
        
        if showLocation && !title.isEmpty {
            self.locationLabel.text = " \(title) "
            locationWidth.constant = self.locationLabel.sizeThatFits(CGSize.zero).width
            loctionRightSpace.constant = 4.0;
        } else {
            locationWidth.constant = 0.0;
            loctionRightSpace.constant = 0.0;
        }
        
        let lockType : LockTypes = message.lockType
        switch (lockType) {
        case .plainTextLock:
            self.lockImage.image = UIImage(named: "mail_lock");
            self.lockImage.isHighlighted = true;
            break
        case .encryptLock:
            self.lockImage.image = UIImage(named: "mail_lock");
            self.lockImage.isHighlighted = false;
            break
        case .pgpLock:
            self.lockImage.image = UIImage(named: "mail_lock-pgpmime");
            self.lockImage.isHighlighted = false;
            break;
        }
        
        if message.numAttachments.int32Value > 0 {
            self.attachmentWidth.constant = kIconsWidth
        } else {
            self.attachmentWidth.constant = 0
        }
        
        if message.isStarred {
            self.starWidth.constant = self.kIconsWidth
        } else {
            self.starWidth.constant = 0
        }
        
        if message.expirationTime != nil {
            self.expirationWidth.constant = self.kIconsWidth
        } else {
            self.expirationWidth.constant = 0
        }
        
        let predicate = NSPredicate(format: "labelID MATCHES %@", "(?!^\\d+$)^.+$")
        let tempLabels = message.labels.filtered(using: predicate) //TODO:: later need add lables exsiting check 
        var labels : [Label] = []
        for vowel in tempLabels {
            let label = vowel as! Label;
            labels.append(label)
        }
        if message.location == MessageLocation.outbox {
            labelsView.configLables( message.recipientList.getDisplayAddress(), labels: labels)
        } else {
            labelsView.configLables( message.displaySender, labels: labels)
        }
        
        if (message.isRead) {
            changeStyleToReadDesign()
        } else {
            changeStyleToUnreadDesign()
        }
        
        if  message.isRepliedAll {
            showReplyAll()
        }
        else if message.isReplied {
            showReply()
        }
        else {
            hideReply()
        }
        
        if  message.isForwarded {
            showForward()
        } else {
            hideForward()
        }
        
        if let t : Date = message.time, let displayString = NSDate.stringForDisplay(from: t) {
            self.time.text = " \(displayString)"
        } else {
            self.time.text = " "
        }
        
        timeWidth.constant = self.time.sizeThatFits(CGSize.zero).width
        
        self.setNeedsUpdateConstraints()
    }
    fileprivate func updateLables (_ labelView : LabelDisplayView, label:Label?) {
        if let label = label {
            if label.name.isEmpty || label.color.isEmpty {
                labelView.isHidden = true;
            } else {
                labelView.isHidden = false;
                labelView.labelTitle = label.name
                labelView.LabelTintColor = UIColor(hexString: label.color, alpha: 1.0)
            }
        } else {
            labelView.isHidden = true;
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
