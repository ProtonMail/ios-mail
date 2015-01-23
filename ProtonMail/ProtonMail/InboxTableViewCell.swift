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
}