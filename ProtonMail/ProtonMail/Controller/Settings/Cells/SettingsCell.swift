//
//  SettingsCell.swift
//  Proton Mail - Created on 11/16/15.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_Foundations

class SettingsCell: UITableViewCell, AccessibleCell {

    @IBOutlet weak var LeftText: UILabel!
    @IBOutlet weak var RightText: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()

        if #available(iOS 10, *) {
            LeftText.font = UIFont.preferredFont(forTextStyle: .footnote)
            LeftText.adjustsFontForContentSizeCategory = true

            RightText.font = UIFont.preferredFont(forTextStyle: .caption1)
            RightText.adjustsFontForContentSizeCategory = true
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
