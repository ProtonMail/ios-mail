//
//  LabelInfoCell.swift
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
import ProtonCore_UIFoundations

final class LabelInfoCell: UITableViewCell {

    @IBOutlet private var iconView: UIImageView!
    @IBOutlet private var infoLabel: UILabel!
    @IBOutlet private var infoLabelHeight: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.iconView.tintColor = UIColorManager.IconHint
        self.contentView.backgroundColor = UIColorManager.BackgroundNorm
    }

    func config(info: String, icon: UIImage, cellHeight: CGFloat) {
        self.infoLabel.attributedText = info.apply(style: FontManager.DefaultSmallHint)
        self.iconView.image = icon
        self.infoLabelHeight.constant = cellHeight
    }
}
