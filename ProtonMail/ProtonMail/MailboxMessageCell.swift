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
    private let kIconsWidth : CGFloat = 18.0
    private let kReplyWidth : CGFloat = 20.0
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
   
    @IBOutlet weak var label1: LabelDisplayView!
    @IBOutlet weak var label2: LabelDisplayView!
    @IBOutlet weak var label3: LabelDisplayView!
    @IBOutlet weak var label4: LabelDisplayView!
    @IBOutlet weak var label5: LabelDisplayView!
    
    @IBOutlet weak var locationLabel: UILabel!
    // MARK : vars
    private var isChecked : Bool = false
    
    @IBOutlet weak var checkboxButton: UIButton!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var sender: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var lockImage: UIImageView!
    @IBOutlet weak var replyImage: UIImageView!
    
    @IBOutlet weak var starImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        checkboxWidth.constant = 0.0
        
        label1.mas_updateConstraints { (make) -> Void in
            make.removeExisting = true
            make.right.equalTo()(self.starImage.mas_left)
            make.bottom.equalTo()(self.starImage.mas_bottom)
            make.top.equalTo()(self.starImage.mas_top)
        }
        
        label2.mas_updateConstraints { (make) -> Void in
            make.removeExisting = true
            make.right.equalTo()(self.label1.mas_left)
            make.bottom.equalTo()(self.label1.mas_bottom)
            make.top.equalTo()(self.label1.mas_top)
        }
        label3.mas_updateConstraints { (make) -> Void in
            make.removeExisting = true
            make.right.equalTo()(self.label2.mas_left)
            make.bottom.equalTo()(self.label2.mas_bottom)
            make.top.equalTo()(self.label2.mas_top)
        }
        label4.mas_updateConstraints { (make) -> Void in
            make.removeExisting = true
            make.right.equalTo()(self.label3.mas_left)
            make.bottom.equalTo()(self.label3.mas_bottom)
            make.top.equalTo()(self.label3.mas_top)
        }
        label5.mas_updateConstraints { (make) -> Void in
            make.removeExisting = true
            make.right.equalTo()(self.label4.mas_left)
            make.bottom.equalTo()(self.label4.mas_bottom)
            make.top.equalTo()(self.label4.mas_top)
        }
        
        locationLabel.layer.cornerRadius = 2;

    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
        locationLabel.backgroundColor = UIColor.grayColor()
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        locationLabel.backgroundColor = UIColor.grayColor()
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
    
    func configureCell(message: Message, showLocation : Bool) {
        self.title.text = message.subject
        
        if showLocation {
            self.locationLabel.text = " \(message.location.title) "
            locationWidth.constant = self.locationLabel.sizeThatFits(CGSizeZero).width
            loctionRightSpace.constant = 4.0;
        } else {
            locationWidth.constant = 0.0;
            loctionRightSpace.constant = 0.0;
        }
        
        if message.location == MessageLocation.outbox {
            self.sender.text = message.recipientList.getDisplayAddress()
        } else {
            self.sender.text = message.displaySender
        }
        
        var encryptedType = message.encryptType
        if encryptedType == EncryptTypes.Internal {
            self.lockImage.highlighted = false;
        } else {
            self.lockImage.highlighted = true;
        }
        
        if message.hasAttachments {
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
        
        let labels = message.labels.allObjects
        let lc = labels.count - 1;
        for i in 0 ... 4 {
            switch i {
            case 0:
                var label : Label? = nil
                if i <= lc {
                    label = labels[i] as? Label
                }
                self.updateLables(label1, label: label)
            case 1:
                var label : Label? = nil
                if i <= lc {
                    label = labels[i] as? Label
                }
                self.updateLables(label2, label: label)
            case 2:
                var label : Label? = nil
                if i <= lc {
                    label = labels[i] as? Label
                }
                self.updateLables(label3, label: label)
            case 3:
                var label : Label? = nil
                if i <= lc {
                    label = labels[i] as? Label
                }
                self.updateLables(label4, label: label)
            case 4:
                var label : Label? = nil
                if i <= lc {
                    label = labels[i] as? Label
                }
                self.updateLables(label5, label: label)
            default:
                break;
            }
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
        
        self.time.text = message.time != nil ? " \(NSDate.stringForDisplayFromDate(message.time))" : ""
        timeWidth.constant = self.time.sizeThatFits(CGSizeZero).width
        
        self.setNeedsUpdateConstraints()
    }
    private func updateLables (labelView : LabelDisplayView, label:Label?) {
        if let label = label {
            if label.name.isEmpty || label.color.isEmpty {
                labelView.hidden = true;
            } else {
                labelView.hidden = false;
                labelView.labelTitle = label.name
                labelView.LabelTintColor = UIColor(hexString: label.color, alpha: 1.0)
            }
        } else {
            labelView.hidden = true;
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
