//
//  SelectableTableViewCell.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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
//

import PMUIFoundations
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
        iconView.tintColor = UIColorManager.TextNorm
    }
}
