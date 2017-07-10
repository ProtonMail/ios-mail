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
import ProtonMailCommon

class MenuLabelViewCell: UITableViewCell {
    
    @IBOutlet weak var titleImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!
    
    fileprivate var item: Label!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.layoutMargins = UIEdgeInsets.zero;
        self.separatorInset = UIEdgeInsets.zero
        
        let selectedBackgroundView = UIView(frame: CGRect.zero)
        selectedBackgroundView.backgroundColor = UIColor.ProtonMail.Menu_SelectedBackground
        
        self.selectedBackgroundView = selectedBackgroundView
        self.separatorInset = UIEdgeInsets.zero
        self.layoutMargins = UIEdgeInsets.zero
    }
    
    func configCell (_ item : Label!) {
        self.item = item;
        
        unreadLabel.layer.masksToBounds = true;
        unreadLabel.layer.cornerRadius = 12;
        unreadLabel.text = "0";
        
        if item.managedObjectContext != nil {
            let color = UIColor(hexString: item.color, alpha:1)
            
            var image = UIImage(named: "menu_label")
            if item.exclusive {
                image = UIImage(named: "menu_folder")
            }
            titleLabel.text = item.name;
            
            titleImageView.image = image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
            titleImageView.highlightedImage = image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
            titleImageView.tintColor = color
        }
    }
    
    func configUnreadCount () {
        
        let count = lastUpdatedStore.UnreadCountForKey(item.labelID)
        if count > 0 {
            unreadLabel.text = "\(count)";
            unreadLabel.isHidden = false;
        } else {
            unreadLabel.text = "0";
            unreadLabel.isHidden = true;
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            unreadLabel.backgroundColor = UIColor.ProtonMail.Menu_UnreadCountBackground
        }
        
        if highlighted {
            self.backgroundColor = UIColor.ProtonMail.Menu_SelectedBackground
        } else {
            self.backgroundColor = UIColor.ProtonMail.Menu_UnSelectBackground
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            unreadLabel.backgroundColor = UIColor.ProtonMail.Menu_UnreadCountBackground
        }
        
        if selected {
            self.backgroundColor = UIColor.ProtonMail.Menu_SelectedBackground
        } else {
            self.backgroundColor = UIColor.ProtonMail.Menu_UnSelectBackground
        }
    }
}
