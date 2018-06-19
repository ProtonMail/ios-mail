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
    func mailboxTableViewCell(_ cell: MailboxTableViewCell, didChangeStarred: Bool)
    func mailBoxTableViewCell(_ cell: MailboxTableViewCell, didChangeChecked: Bool)
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
    
    fileprivate let kCheckboxWidth: CGFloat = 22.0
    fileprivate let kStarWidth : CGFloat = 22.0
    fileprivate let kAttachmentWidth : CGFloat = 24.0
    
    fileprivate let kCheckboxButtonCornerRadius: CGFloat = 1.0
    fileprivate let kCheckboxUncheckedImage: UIImage = UIImage(named: "unchecked")!
    fileprivate let kCheckboxCheckedImage: UIImage = UIImage(named: "checked")!
    fileprivate let kTitleMarginLeft: CGFloat = 16.0
    fileprivate let kReplyImageWidth : CGFloat = 27.0
    
    //MAKR : constants
    
    @IBOutlet weak var label1: NSLayoutConstraint!
    @IBOutlet weak var label2: NSLayoutConstraint!
    @IBOutlet weak var label3: NSLayoutConstraint!
    @IBOutlet weak var label4: NSLayoutConstraint!
    @IBOutlet weak var label5: NSLayoutConstraint!
    
    @IBOutlet weak var timeConstraint: NSLayoutConstraint!
    @IBOutlet weak var attachmentConstraint: NSLayoutConstraint!
    @IBOutlet weak var starConstraint: NSLayoutConstraint!
    
    // MARK: - Private attributes
    
    fileprivate var isChecked: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        checkboxButton.addTarget(self, action: #selector(MailboxTableViewCell.checkboxTapped), for: UIControlEvents.touchUpInside)
        
        labelView.backgroundColor = UIColor.clear;
        labelView2.backgroundColor = UIColor.clear;
        labelView3.backgroundColor = UIColor.clear;
        labelView4.backgroundColor = UIColor.clear;
        labelView5.backgroundColor = UIColor.clear;
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }

    // MARK: - Actions
    
    @IBAction func favoriteButtonAction(_ sender: UIButton) {
    }
    
    @objc func checkboxTapped() {
        if (isChecked) {
            checkboxButton.setImage(kCheckboxUncheckedImage, for: UIControlState())
        } else {
            checkboxButton.setImage(kCheckboxCheckedImage, for: UIControlState())
        }
        self.isChecked = !self.isChecked
        self.delegate?.mailBoxTableViewCell(self, didChangeChecked: self.isChecked)
    }
    
    
    // MARK: - Cell configuration
    
    func configureCell(_ message: Message) {
        self.title.text = message.subject
        
        if message.location == MessageLocation.outbox {
            self.sender.text = message.recipientList.getDisplayAddress()
        } else {
            self.sender.text = message.displaySender
        }
        
        self.encryptedImage.isHidden = !message.checkIsEncrypted()
        self.attachImage.isHidden = !(message.numAttachments.int32Value > 0)
        
        if message.numAttachments.int32Value > 0 {
            self.attachImage.isHidden = false
            self.attachmentConstraint.constant = self.kAttachmentWidth
        } else {
            self.attachImage.isHidden = true
            self.attachmentConstraint.constant = 0
        }
        
        self.checkboxButton.layer.cornerRadius = kCheckboxButtonCornerRadius
        self.checkboxButton.layer.masksToBounds = true
        
        if message.isStarred {
            self.starredImage.isHidden = false
            self.starConstraint.constant = self.kStarWidth
        } else {
            self.starredImage.isHidden = true
            self.starConstraint.constant = 0
        }
        
        let alllabels = message.labels.allObjects
        var labels : [Label] = []
        for l in alllabels {
            if let label = l as? Label, label.exclusive == false {
                labels.append(label)
            }
        }
        
        let lc = labels.count - 1;
        for i in 0 ... 4 {
            switch i {
            case 0:
                var label : Label? = nil
                if i <= lc {
                    label = labels[i]
                }
                self.updateLables(labelView, labelConstraint: label1, label: label)
            case 1:
                var label : Label? = nil
                if i <= lc {
                    label = labels[i]
                }
                self.updateLables(labelView2, labelConstraint: label2, label: label)
            case 2:
                var label : Label? = nil
                if i <= lc {
                    label = labels[i]
                }
                self.updateLables(labelView3, labelConstraint: label3, label: label)
            case 3:
                var label : Label? = nil
                if i <= lc {
                    label = labels[i]
                }
                self.updateLables(labelView4, labelConstraint: label4, label: label)
            case 4:
                var label : Label? = nil
                if i <= lc {
                    label = labels[i]
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
        
        self.time.text = message.time != nil ? " \(NSDate.stringForDisplay(from: message.time as Date!))" : ""
        
        timeConstraint.constant = self.time.sizeThatFits(CGSize.zero).width
        
        
        
        title.isHidden = true
        sender.isHidden = true
        time.isHidden = true
        
        encryptedImage.isHidden = true
        attachImage.isHidden = true
        checkboxButton.isHidden = true
        replyImage.isHidden = true
        starredImage.isHidden = true
        
        labelView.isHidden = true
        labelView2.isHidden = true
        labelView3.isHidden = true
        labelView4.isHidden = true
        labelView5.isHidden = true
    }
    
    fileprivate func updateLables (_ labelView : TableCellLabelView, labelConstraint : NSLayoutConstraint, label:Label?) {
        if let label = label {
            if label.name.isEmpty || label.color.isEmpty {
                labelView.isHidden = true
                labelConstraint.constant = 0
            } else {
                let w = labelView.setText(label.name, color: UIColor(hexString: label.color, alpha: 1.0) )
                labelView.isHidden = false
                labelConstraint.constant = w
            }
        } else {
            labelView.isHidden = true
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
    
    func showImage(_ isShow: Bool){
        if isShow {
            self.titleLeadingConstraint.constant = kReplyImageWidth
            self.replyImage.isHidden = false
        }
        else {
            self.titleLeadingConstraint.constant = 0
            self.replyImage.isHidden = true
        }
    }
    
    func changeStyleToReadDesign() {
        self.contentView.backgroundColor = UIColor(RRGGBB: UInt(0xF2F3F7))
        self.title.font = Fonts.h4.light
        self.sender.font = Fonts.h6.light
        self.time.font = Fonts.h6.light
    }
    
    func changeStyleToUnreadDesign() {
        self.contentView.backgroundColor = UIColor(RRGGBB: UInt(0xFFFFFF))
        self.title.font = Fonts.h4.regular
        self.sender.font = Fonts.h6.regular
        self.time.font = Fonts.h6.regular
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
    
    func setCellIsChecked(_ checked: Bool) {
        self.isChecked = checked
        
        if (checked) {
            self.checkboxButton.setImage(kCheckboxCheckedImage, for: UIControlState())
        } else {
            self.checkboxButton.setImage(kCheckboxUncheckedImage, for: UIControlState())
        }
    }
    
    func isCheckBoxSelected() -> Bool {
        return self.isChecked
    }
    
    
}
