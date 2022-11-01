//
//  LabelColorCell.swift
//  Proton Mail
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

import ProtonCore_UIFoundations
import UIKit

final class LabelColorCell: UICollectionViewCell {

    @IBOutlet private var icon: UIImageView!
    @IBOutlet private var selectedBorder: UIImageView!
    @IBOutlet private var checkMark: UIView!
    @IBOutlet private var checkMarkCenterY: NSLayoutConstraint!
    private var intenseColor: UIColor!

    static var identifier = "LabelColorCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        self.checkMark.roundCorner(5)
    }

    func config(color: UIColor,
                intenseColor: UIColor,
                type: PMLabelType,
                isSelected: Bool) {
        self.icon.tintColor = color
        self.selectedBorder.tintColor = intenseColor
        self.intenseColor = intenseColor
        if type == .folder {
            self.icon.image = IconProvider.folderFilled
            self.selectedBorder.image = IconProvider.folder
            self.checkMarkCenterY.constant = 1
        } else {
            self.icon.image = IconProvider.circleFilled
            self.selectedBorder.image = IconProvider.circle
            self.checkMarkCenterY.constant = 0
        }

        self.setSelected(isSelected: isSelected)
        self.accessibilityIdentifier = "LabelPaletteCell.LabelColorCell"
        self.accessibilityTraits = .image
    }

    func setSelected(isSelected: Bool) {
        self.checkMark.isHidden = !isSelected
        self.selectedBorder.isHidden = !isSelected
    }
}
