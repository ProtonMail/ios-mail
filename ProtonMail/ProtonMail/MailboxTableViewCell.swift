//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import UIKit

@objc protocol MailboxTableViewCellDelegate {
    func mailboxTableViewCell(cell: MailboxTableViewCell, didChangeStarred: Bool)
    func mailBoxTableViewCell(cell: MailboxTableViewCell, didChangeChecked: Bool)
}


class MailboxTableViewCell: UITableViewCell {
    
    weak var delegate: MailboxTableViewCellDelegate?
    
    // MARK: - View Outlets
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var sender: UILabel!
    @IBOutlet weak var time: UILabel!
    //@IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var encryptedImage: UIImageView!
    @IBOutlet weak var attachImage: UIImageView!
    @IBOutlet weak var checkboxButton: UIButton!
    @IBOutlet weak var replyImage: UIImageView!
    @IBOutlet weak var starredImage: UIImageView!
    
    @IBOutlet weak var labelView: TableCellLabelView!
    @IBOutlet weak var labelView2: TableCellLabelView!
    @IBOutlet weak var labelView3: TableCellLabelView!
    @IBOutlet weak var labelView4: TableCellLabelView!
    @IBOutlet weak var labelView5: TableCellLabelView!
    
    // MARK: - Constraint Outlets
    
    @IBOutlet weak var checkboxWidth: NSLayoutConstraint!
    @IBOutlet var titleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var replyWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleHorSpaceConstraint: NSLayoutConstraint!
    
    // MARK: - Private constants
    
    private let kCheckboxWidth: CGFloat = 22.0
    private let kCheckboxButtonCornerRadius: CGFloat = 1.0
    private let kCheckboxUncheckedImage: UIImage = UIImage(named: "unchecked")!
    private let kCheckboxCheckedImage: UIImage = UIImage(named: "checked")!
    private let kTitleMarginLeft: CGFloat = 16.0
    private let kReplyImageWidth : CGFloat = 27.0
    private let kAttachmentWidth : CGFloat = 14.0
    
    //MAKR : constants
    
    @IBOutlet weak var label1: NSLayoutConstraint!
    @IBOutlet weak var label2: NSLayoutConstraint!
    @IBOutlet weak var label3: NSLayoutConstraint!
    @IBOutlet weak var label4: NSLayoutConstraint!
    @IBOutlet weak var label5: NSLayoutConstraint!
    
    @IBOutlet weak var timeConstraint: NSLayoutConstraint!
    @IBOutlet weak var attachmentConstraint: NSLayoutConstraint!
    
    // MARK: - Private attributes
    
    private var isChecked: Bool = false
    private var isStarred: Bool = false {
        didSet {
            let image = UIImage(named: isStarred ? "mail_starred-active" : "mail_starred")
            self.starredImage.image = image
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        checkboxButton.addTarget(self, action: "checkboxTapped", forControlEvents: UIControlEvents.TouchUpInside)
        
        labelView.backgroundColor = UIColor.clearColor();
        labelView2.backgroundColor = UIColor.clearColor();
        labelView3.backgroundColor = UIColor.clearColor();
        labelView4.backgroundColor = UIColor.clearColor();
        labelView5.backgroundColor = UIColor.clearColor();
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - Actions
    
    @IBAction func favoriteButtonAction(sender: UIButton) {
//        self.isStarred = !self.isStarred
//        
//        // TODO: display activity indicator
//        
//        delegate?.mailboxTableViewCell(self, didChangeStarred: isStarred)
    }
    
    func checkboxTapped() {
        if (isChecked) {
            checkboxButton.setImage(kCheckboxUncheckedImage, forState: UIControlState.Normal)
        } else {
            checkboxButton.setImage(kCheckboxCheckedImage, forState: UIControlState.Normal)
        }
        
        self.isChecked = !self.isChecked
        self.delegate?.mailBoxTableViewCell(self, didChangeChecked: self.isChecked)
    }
    
    
    // MARK: - Cell configuration
    
    func configureCell(message: Message) {
        self.title.text = message.subject
        
        if message.location == MessageLocation.outbox {
            self.sender.text = message.recipientList.getDisplayAddress()
        } else {
            self.sender.text = message.displaySender
        }
        
        self.encryptedImage.hidden = !message.checkIsEncrypted()
        self.attachImage.hidden = !message.hasAttachments
        
        if message.hasAttachments {
            self.attachmentConstraint.constant = self.kAttachmentWidth
        } else {
            self.attachmentConstraint.constant = 0
        }
        
        self.checkboxButton.layer.cornerRadius = kCheckboxButtonCornerRadius
        self.checkboxButton.layer.masksToBounds = true
        self.isStarred = message.isStarred
        
        let labels = message.labels.allObjects
        let lc = labels.count - 1;
        for i in 0 ... 4 {
            switch i {
            case 0:
                var label : Label? = nil
                if i <= lc {
                    label = labels[i] as? Label
                }
                self.updateLables(labelView, labelConstraint: label1, label: label)
            case 1:
                var label : Label? = nil
                if i <= lc {
                    label = labels[i] as? Label
                }
                self.updateLables(labelView2, labelConstraint: label2, label: label)
            case 2:
                var label : Label? = nil
                if i <= lc {
                    label = labels[i] as? Label
                }
                self.updateLables(labelView3, labelConstraint: label3, label: label)
            case 3:
                var label : Label? = nil
                if i <= lc {
                    label = labels[i] as? Label
                }
                self.updateLables(labelView4, labelConstraint: label4, label: label)
            case 4:
                var label : Label? = nil
                if i <= lc {
                    label = labels[i] as? Label
                }
                self.updateLables(labelView5, labelConstraint: label5, label: label)
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
        
        self.time.text = message.time != nil ? " \(NSDate.stringForDisplayFromDate(message.time))" : ""
        
        timeConstraint.constant = self.time.sizeThatFits(CGSizeZero).width
    }
    
    private func updateLables (labelView : TableCellLabelView, labelConstraint : NSLayoutConstraint, label:Label?) {
        if let label = label {
            if label.name.isEmpty || label.color.isEmpty {
                labelConstraint.constant = 0
            } else {
                let w = labelView.setText(label.name, color: UIColor(hexString: label.color, alpha: 1.0) )
                labelConstraint.constant = w
            }
        } else {
            labelConstraint.constant = 0
        }
    }
    
    func showReply() {
        self.replyWidthConstraint.constant = 20
        self.titleHorSpaceConstraint.constant = 6
        self.replyImage.image = UIImage(named: "reply")
        self.setNeedsUpdateConstraints()
    }
    
    func showReplyAll() {
        self.replyWidthConstraint.constant = 20
        self.titleHorSpaceConstraint.constant = 6
        self.replyImage.image = UIImage(named: "replyall")
        self.setNeedsUpdateConstraints()
    }
    
    func hideReply() {
        self.replyWidthConstraint.constant = 0.0
        self.titleHorSpaceConstraint.constant = 0.0
        self.setNeedsUpdateConstraints()
    }
    
    func showImage(isShow: Bool){
        if isShow {
            self.titleLeadingConstraint.constant = kReplyImageWidth
            self.replyImage.hidden = false
        }
        else {
            self.titleLeadingConstraint.constant = 0
            self.replyImage.hidden = true
        }
    }
    
    func changeStyleToReadDesign() {
        self.contentView.backgroundColor = UIColor(RRGGBB: UInt(0xF2F3F7))
        self.title.font = UIFont.robotoLight(size: UIFont.Size.h4)
        self.sender.font = UIFont.robotoLight(size: UIFont.Size.h6)
        self.time.font = UIFont.robotoLight(size: UIFont.Size.h6)
    }
    
    func changeStyleToUnreadDesign() {
        self.contentView.backgroundColor = UIColor(RRGGBB: UInt(0xFFFFFF))
        self.title.font = UIFont.robotoRegular(size: UIFont.Size.h4)
        self.sender.font = UIFont.robotoRegular(size: UIFont.Size.h6)
        self.time.font = UIFont.robotoRegular(size: UIFont.Size.h6)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        delegate = nil
    }
    
    func showCheckboxOnLeftSide() {
        self.checkboxWidth.constant = kCheckboxWidth
        self.titleLeadingConstraint.constant = kTitleMarginLeft
        self.setNeedsUpdateConstraints()        
    }
    
    func hideCheckboxOnLeftSide() {
        self.checkboxWidth.constant = 0.0
        self.titleLeadingConstraint.constant = 0.0
        self.setNeedsUpdateConstraints()
    }
    
    func setCellIsChecked(checked: Bool) {
        self.isChecked = checked
        
        if (checked) {
            self.checkboxButton.setImage(kCheckboxCheckedImage, forState: UIControlState.Normal)
        } else {
            self.checkboxButton.setImage(kCheckboxUncheckedImage, forState: UIControlState.Normal)
        }
    }
    
    func isCheckBoxSelected() -> Bool {
        return self.isChecked
    }
    
    
}