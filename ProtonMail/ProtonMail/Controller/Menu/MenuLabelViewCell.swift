//
//  MenuLabelViewCell.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation

class MenuLabelViewCell: UITableViewCell {
    
    @IBOutlet weak var titleImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!
    @IBOutlet weak var separtor: UIView!
    
    fileprivate var item: Label!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.zeroMargin()
        
        let selectedBackgroundView = UIView(frame: CGRect.zero)
        selectedBackgroundView.backgroundColor = UIColor.ProtonMail.Menu_SelectedBackground
        
        self.selectedBackgroundView = selectedBackgroundView
    }
    
    func configCell (_ item : Label!, hideSepartor: Bool) {
        self.item = item;
        
        separtor.isHidden = hideSepartor
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
    
    func configUnreadCount (count: Int) {
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        separtor.isHidden = true
    }
}
