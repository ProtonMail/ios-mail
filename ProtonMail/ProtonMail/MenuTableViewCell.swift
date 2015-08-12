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

import Foundation

class MenuTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!
    
    private var item: MenuItem!

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layoutMargins = UIEdgeInsetsZero;
        self.separatorInset = UIEdgeInsetsZero
        
        let selectedBackgroundView = UIView(frame: CGRectZero)
        selectedBackgroundView.backgroundColor = UIColor.ProtonMail.MenuSelectedBackground_2F2E3C
        
        self.selectedBackgroundView = selectedBackgroundView
        self.separatorInset = UIEdgeInsetsZero
        self.layoutMargins = UIEdgeInsetsZero
    }
    
    func configCell (item : MenuItem!) {
        unreadLabel.layer.masksToBounds = true;
        unreadLabel.layer.cornerRadius = 14;
        unreadLabel.text = "0";
        
        titleLabel.text = item.identifier;
        
        let image = UIImage(named: item.image)
        titleImageView.image = image
        titleImageView.highlightedImage = image
        
        unreadLabel.hidden = !item.hasCount
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            unreadLabel.backgroundColor = UIColor.ProtonMail.MenuUnreadCountBackground_8182C3
        }
        
        if highlighted {
            self.backgroundColor = UIColor.ProtonMail.MenuSelectedBackground_2F2E3C
        } else {
            self.backgroundColor = UIColor.ProtonMail.MenuUnSelectBackground_403F4F
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            unreadLabel.backgroundColor = UIColor.ProtonMail.MenuUnreadCountBackground_8182C3
        }
        
        
        if selected {
            self.backgroundColor = UIColor.ProtonMail.MenuSelectedBackground_2F2E3C
        } else {
            self.backgroundColor = UIColor.ProtonMail.MenuUnSelectBackground_403F4F
        }
    }
}