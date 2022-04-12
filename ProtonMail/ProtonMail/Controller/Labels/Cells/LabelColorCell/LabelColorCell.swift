//
//  LabelColorCell.swift
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

import UIKit

final class LabelColorCell: UICollectionViewCell {

    @IBOutlet private var icon: UIImageView!
    @IBOutlet private var checkMark: UIImageView!

    static var identifier = "LabelColorCell"

    func config(color: UIColor, type: PMLabelType, isSelected: Bool) {
        self.icon.tintColor = color
        if type == .folder {
            self.icon.image = Asset.icFolderFilled.image
        } else {
            self.icon.image = Asset.icCircle.image
        }

        self.setSelected(isSelected: isSelected)
        self.accessibilityIdentifier = "LabelPaletteCell.LabelColorCell"
        self.accessibilityTraits = .image
    }

    func setSelected(isSelected: Bool) {
        self.checkMark.isHidden = !isSelected
    }

}
