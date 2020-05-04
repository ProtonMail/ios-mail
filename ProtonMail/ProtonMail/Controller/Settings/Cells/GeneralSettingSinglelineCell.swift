//
//  GeneralSettingSinglelineCell.swift
//  ProtonMail - Created on 3/17/15.
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

class GeneralSettingSinglelineCell: UITableViewCell {
    @IBOutlet weak var LeftText: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if #available(iOS 10, *) {
            LeftText.font = UIFont.preferredFont(forTextStyle: .footnote)
            LeftText.adjustsFontForContentSizeCategory = true
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configCell(_ left:String) {
        LeftText.text = left
        self.accessibilityLabel = left
    }
}
