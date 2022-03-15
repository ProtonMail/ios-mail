//
//  GeneralSettingViewCell.swift
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

@IBDesignable class GeneralSettingViewCell: UITableViewCell {
    @IBOutlet weak var LeftText: UILabel!
    @IBOutlet weak var RightText: UILabel!

    static var CellID: String {
        return "\(self)"
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func configCell(_ left: String,
                    leftTextAttributes: [NSAttributedString.Key: Any]? = FontManager.Default,
                    right: String,
                    rightTextAttributes: [NSAttributedString.Key: Any]? = FontManager.Default) {
        LeftText.attributedText = NSMutableAttributedString(string: left, attributes: leftTextAttributes)
        let rightAttribute = rightTextAttributes?.alignment(.right)
        RightText.attributedText = NSMutableAttributedString(string: right, attributes: rightAttribute)

        self.accessibilityLabel = left
    }
}

extension GeneralSettingViewCell: IBDesignableLabeled {
    override func prepareForInterfaceBuilder() {
        self.labelAtInterfaceBuilder()
    }
}
