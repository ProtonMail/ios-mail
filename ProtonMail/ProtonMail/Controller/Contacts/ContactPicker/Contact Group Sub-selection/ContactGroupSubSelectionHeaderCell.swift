//
//  ContactGroupSubSelectionHeaderCell.swift
//  ProtonMail - Created on 2018/10/13.
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


import UIKit

class ContactGroupSubSelectionHeaderCell: UITableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBOutlet weak var selectionIcon: UIImageView!
    @IBOutlet weak var contactGroupIcon: UIImageView!
    @IBOutlet weak var contactGroupName: UILabel!
    
    private var delegate: ContactGroupSubSelectionViewModelHeaderCellDelegate!
    private var isAllSelected: Bool = false {
        didSet {
            if self.isAllSelected {
                selectionIcon.image = UIImage.init(named: "mail_check-active")
            } else {
                selectionIcon.image = UIImage.init(named: "mail_check")
            }
        }
    }
    
    func config(groupName: String,
                groupColor: String?,
                delegate: ContactGroupSubSelectionViewModelHeaderCellDelegate) {
        contactGroupName.text = groupName
        self.delegate = delegate
        
        if let color = groupColor {
            contactGroupIcon.setupImage(scale: 0.8,
                                        makeCircleBorder: true,
                                        tintColor: UIColor.white,
                                        backgroundColor: UIColor.init(hexString: color, alpha: 1))
        } else {
            contactGroupIcon.isHidden = true
        }
        
        self.isAllSelected = delegate.isAllSelected()
        
        self.selectionStyle = .none
    }
    
    func rowTapped() {
        self.isAllSelected = !self.isAllSelected
        
        if isAllSelected {
            delegate.selectAll()
        } else {
            delegate.deSelectAll()
        }
    }
}
