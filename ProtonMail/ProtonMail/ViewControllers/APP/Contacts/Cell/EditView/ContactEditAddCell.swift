//
//  ContactEditAddCell.swift
//  Proton Mail - Created on 5/4/17.
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

import ProtonCoreFoundations
import ProtonCoreUIFoundations
import UIKit

final class ContactEditAddCell: UITableViewCell, AccessibleCell {
    @IBOutlet var valueLabel: UILabel!

    func configCell(value: String, color: UIColor = ColorProvider.TextNorm) {
        backgroundColor = ColorProvider.BackgroundNorm

        self.valueLabel.attributedText = value.apply(style: FontManager.Default.foregroundColor(color))
        generateCellAccessibilityIdentifiers(value)
    }
    
    override func prepareForReuse() {
        if isEditing { setEditImageColor(ColorProvider.NotificationSuccess) }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if isEditing { setEditImageColor(ColorProvider.NotificationSuccess) }
    }
}

extension ContactEditAddCell {
    static let controlClassName = "UITableViewCellEditControl"

    func setEditImageColor(_ color: UIColor) {
        for view in subviews where view.classForCoder.description() == Self.controlClassName {
            if let imageView = view.subviews.compactMap({ $0 as? UIImageView }).first {
                imageView.image = imageView.image?.withTintColor(color)
            }
        }
    }
}
