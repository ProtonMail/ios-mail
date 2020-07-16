//
//  MenuTableViewCell.swift
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

class MenuTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!
    @IBOutlet weak var separtor: UIView!
    
    fileprivate var item: MenuItem!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.zeroMargin()
        
        let selectedBackgroundView = UIView(frame: CGRect.zero)
        selectedBackgroundView.backgroundColor = UIColor.ProtonMail.Menu_SelectedBackground
        
        self.selectedBackgroundView = selectedBackgroundView
        
        if #available(iOS 13.0, *) {
            // iOS 13 does not change contentView's color according to selectedBackgroundView
            // Third-Party Apps > UIKit > New Features > first point
            // https://developer.apple.com/documentation/ios_ipados_release_notes/ios_13_release_notes
            self.contentView.backgroundColor = .clear
        }
    }
    
    func configCell (_ item : MenuItem!, hideSepartor: Bool) {
        self.item = item;
        unreadLabel.layer.masksToBounds = true;
        unreadLabel.layer.cornerRadius = 12;
        unreadLabel.text = "0";
        
        titleLabel.text = item.localizedTitle;
        
        let defaultImage = UIImage(named: item.image)
        let selectedImage = UIImage(named: item.imageSelected)
        titleImageView.image = defaultImage
        titleImageView.highlightedImage = selectedImage
        
        unreadLabel.isHidden = !item.hasCount
        
        separtor.isHidden = hideSepartor
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
    
    func hideCount () {
        unreadLabel.text = "0";
        unreadLabel.isHidden = true;
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            unreadLabel.backgroundColor = UIColor.ProtonMail.Menu_UnreadCountBackground
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            unreadLabel.backgroundColor = UIColor.ProtonMail.Menu_UnreadCountBackground
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        separtor.isHidden = true
    }
}
