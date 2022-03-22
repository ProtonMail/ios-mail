//
//  SelectableTableViewCell.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton AG
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
//

import ProtonCore_UIFoundations
import UIKit

class SelectableTableViewCell: UITableViewCell {
    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var itemNameLabel: UILabel!

    static var CellID: String {
        return "\(self)"
    }

    func configure(icon: UIImage, title: String, isSelected: Bool) {
        self.accessoryType = isSelected ? .checkmark : .none
        itemNameLabel.attributedText = title.apply(style: FontManager.Default)
        iconView.image = icon
        iconView.tintColor = ColorProvider.TextNorm
    }
}
