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
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var encryptedImage: UIImageView!
    @IBOutlet weak var attachImage: UIImageView!
    @IBOutlet weak var checkboxButton: UIButton!
    
    
    // MARK: - Constraint Outlets
    
    @IBOutlet weak var checkboxWidth: NSLayoutConstraint!
    @IBOutlet var titleLeadingConstraint: NSLayoutConstraint!
    
    
    // MARK: - Private constants
    
    private let kCheckboxWidth: CGFloat = 22.0
    private let kCheckboxButtonCornerRadius: CGFloat = 1.0
    private let kCheckboxUncheckedImage: UIImage = UIImage(named: "unchecked")!
    private let kCheckboxCheckedImage: UIImage = UIImage(named: "checked")!
    private let kTitleMarginLeft: CGFloat = 16.0
    
    
    // MARK: - Private attributes
    
    private var isChecked: Bool = false
    private var isStarred: Bool = false {
        didSet {
            self.favoriteButton.selected = isStarred
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        checkboxButton.addTarget(self, action: "checkboxTapped", forControlEvents: UIControlEvents.TouchUpInside)
    }

    
    // MARK: - Actions
    
    @IBAction func favoriteButtonAction(sender: UIButton) {
        self.isStarred = !self.isStarred
        
        // TODO: display activity indicator
        
        delegate?.mailboxTableViewCell(self, didChangeStarred: isStarred)
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
    
    func configureCell(thread: Message) {
        self.title.text = thread.title
        self.sender.text = thread.sender
        self.time.text = NSDate.stringForDisplayFromDate(thread.time)
        self.encryptedImage.hidden = !thread.isEncrypted
        self.attachImage.hidden = !thread.hasAttachment
        self.checkboxButton.layer.cornerRadius = kCheckboxButtonCornerRadius
        self.checkboxButton.layer.masksToBounds = true
        self.isStarred = thread.isStarred
        
        if (thread.isRead) {
            changeStyleToReadDesign()
        } else {
            changeStyleToUnreadDesign()
        }
    }
    
    func changeStyleToReadDesign() {
        self.contentView.backgroundColor = UIColor.ProtonMail.Gray_E8EBED
        self.title.font = UIFont.robotoLight(size: UIFont.Size.h4)
        self.sender.font = UIFont.robotoLight(size: UIFont.Size.h6)
        self.time.font = UIFont.robotoLight(size: UIFont.Size.h6)
    }
    
    func changeStyleToUnreadDesign() {
        self.contentView.backgroundColor = UIColor.ProtonMail.Gray_FCFEFF
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
    
    func isSelected() -> Bool {
        return self.isChecked
    }
}