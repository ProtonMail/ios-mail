//
//  DomainsTableViewCell.swift
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

@IBDesignable class DomainsTableViewCell: UITableViewCell {
    @IBOutlet weak var domainText: UILabel!
    @IBOutlet weak var defaultMark: UILabel!
    
    func configCell(domainText: String, defaultMark: String) {
        self.domainText.text = domainText
        self.defaultMark.text = defaultMark
        self.accessibilityLabel = domainText
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if #available(iOS 10, *) {
            self.domainText.font = UIFont.preferredFont(forTextStyle: .footnote)
            self.domainText.adjustsFontForContentSizeCategory = true
            
            self.defaultMark.font = UIFont.preferredFont(forTextStyle: .footnote)
            self.defaultMark.adjustsFontForContentSizeCategory = true
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}

extension DomainsTableViewCell: IBDesignableLabeled {
    override func prepareForInterfaceBuilder() {
        self.labelAtInterfaceBuilder()
    }
}
