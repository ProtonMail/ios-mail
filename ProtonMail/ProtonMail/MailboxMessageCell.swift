//
//  MailboxMessageCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/4/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit


class MailboxMessageCell: UITableViewCell {
    /**
    *  Constants
    */
    struct Constant {
        static let identifier = "MailboxMessageCell"
    }
    
    private let kCheckboxWidth : CGFloat = 36.0
    
    @IBOutlet weak var checkboxWidth: NSLayoutConstraint!
    @IBOutlet weak var timeWidth: NSLayoutConstraint!

    
    
    
    // MARK : vars
    private var isChecked : Bool = false
    
    @IBOutlet weak var checkboxButton: UIButton!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var sender: UILabel!
    @IBOutlet weak var time: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    
    
// MARK : 

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
    
    func setCellIsChecked(checked: Bool) {
        self.isChecked = checked
        checkboxButton.selected = checked
    }
    
    func isCheckBoxSelected() -> Bool {
        return self.isChecked
    }
    
    func changeStyleToReadDesign() {
        self.contentView.backgroundColor = UIColor.ProtonMail.MessageCell_Read_Color
        self.title.font = UIFont.robotoLight(size: UIFont.Size.h4)
        self.sender.font = UIFont.robotoLight(size: UIFont.Size.h6)
        self.time.font = UIFont.robotoLight(size: UIFont.Size.h6)
    }
    
    func changeStyleToUnreadDesign() {
        self.contentView.backgroundColor = UIColor.ProtonMail.MessageCell_UnRead_Color
        self.title.font = UIFont.robotoMedium(size: UIFont.Size.h4)
        self.sender.font = UIFont.robotoMedium(size: UIFont.Size.h6)
        self.time.font = UIFont.robotoMedium(size: UIFont.Size.h6)
    }
    
    
    // MARK: - Cell configuration
    
    func configureCell(message: Message) {
        self.title.text = message.subject
        
        if message.location == MessageLocation.outbox {
            self.sender.text = message.recipientList.getDisplayAddress()
        } else {
            self.sender.text = message.displaySender
        }
//
//        self.encryptedImage.hidden = !message.checkIsEncrypted()
//        self.attachImage.hidden = !message.hasAttachments
//        
//        if message.hasAttachments {
//            self.attachmentConstraint.constant = self.kAttachmentWidth
//        } else {
//            self.attachmentConstraint.constant = 0
//        }
//        
//        self.checkboxButton.layer.cornerRadius = kCheckboxButtonCornerRadius
//        self.checkboxButton.layer.masksToBounds = true
//        
//        if message.isStarred {
//            self.starConstraint.constant = self.kStarWidth
//        } else {
//            self.starConstraint.constant = 0
//        }
//        
//        let labels = message.labels.allObjects
//        let lc = labels.count - 1;
//        for i in 0 ... 4 {
//            switch i {
//            case 0:
//                var label : Label? = nil
//                if i <= lc {
//                    label = labels[i] as? Label
//                }
//                self.updateLables(labelView, labelConstraint: label1, label: label)
//            case 1:
//                var label : Label? = nil
//                if i <= lc {
//                    label = labels[i] as? Label
//                }
//                self.updateLables(labelView2, labelConstraint: label2, label: label)
//            case 2:
//                var label : Label? = nil
//                if i <= lc {
//                    label = labels[i] as? Label
//                }
//                self.updateLables(labelView3, labelConstraint: label3, label: label)
//            case 3:
//                var label : Label? = nil
//                if i <= lc {
//                    label = labels[i] as? Label
//                }
//                self.updateLables(labelView4, labelConstraint: label4, label: label)
//            case 4:
//                var label : Label? = nil
//                if i <= lc {
//                    label = labels[i] as? Label
//                }
//                self.updateLables(labelView5, labelConstraint: label5, label: label)
//            default:
//                break;
//            }
//        }
//        
        if (message.isRead) {
            changeStyleToReadDesign()
        } else {
            changeStyleToUnreadDesign()
        }
//
//        if  message.isRepliedAll {
//            showReplyAll()
//        }
//        else if message.isReplied {
//            showReply()
//        }
//        else {
//            hideReply()
//        }
//        
        self.time.text = message.time != nil ? " \(NSDate.stringForDisplayFromDate(message.time))" : ""
        timeWidth.constant = self.time.sizeThatFits(CGSizeZero).width
    }
    
    
    
    
}
