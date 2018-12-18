//
//  MenuLabelViewCell.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation

class MenuLabelViewCell: UITableViewCell {
    
    @IBOutlet weak var titleImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!
    
    fileprivate var item: Label!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.zeroMargin()
        
        let selectedBackgroundView = UIView(frame: CGRect.zero)
        selectedBackgroundView.backgroundColor = UIColor.ProtonMail.Menu_SelectedBackground
        
        self.selectedBackgroundView = selectedBackgroundView
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
            
            titleImageView.image = image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
            titleImageView.highlightedImage = image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
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
            self.backgroundColor = UIColor.ProtonMail.Menu_UnSelectBackground_Label
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
            self.backgroundColor = UIColor.ProtonMail.Menu_UnSelectBackground_Label
        }
    }
}
