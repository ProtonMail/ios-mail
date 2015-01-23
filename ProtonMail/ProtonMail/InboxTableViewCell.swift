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

class InboxTableViewCell: UITableViewCell {
    
    
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
    
    
    // MARK: - Private constants
    
    private let kCheckboxWidth: CGFloat = 22.0
    
    
    // MARK: - Private attributes
    
    private var isChecked: Bool = false
    
    
    // MARK: - Cell configuration
    
    func configureCell(thread: EmailThread) {
        self.title.text = thread.title
        self.sender.text = thread.sender
        self.time.text = thread.time
        self.encryptedImage.hidden = !thread.isEncrypted
        self.attachImage.hidden = !thread.hasAttachments
        
        if (thread.isFavorite) {
            self.favoriteButton.setImage(UIImage(named: "favorite_main_selected"), forState: UIControlState.Normal)
        } else {
            self.favoriteButton.setImage(UIImage(named: "favorite_main"), forState: UIControlState.Normal)
        }
    }
    
    func showCheckboxOnLeftSide() {
        self.checkboxWidth.constant = kCheckboxWidth
        self.setNeedsUpdateConstraints()        
    }
    
    func checkboxTapped() {
        if (isChecked) {
            checkboxButton.setImage(UIImage(named: "unchecked"), forState: UIControlState.Normal)
        } else {
            checkboxButton.setImage(UIImage(named: "checked"), forState: UIControlState.Normal)
        }
        
        self.isChecked = !self.isChecked
    }
    
    func setCellIsChecked(checked: Bool) {
        self.isChecked = checked
        
        if (checked) {
            self.checkboxButton.setImage(UIImage(named: "checked"), forState: UIControlState.Normal)
        } else {
            self.checkboxButton.setImage(UIImage(named: "unchecked"), forState: UIControlState.Normal)
        }
    }
    
    func isSelected() -> Bool {
        return self.isChecked
    }
}