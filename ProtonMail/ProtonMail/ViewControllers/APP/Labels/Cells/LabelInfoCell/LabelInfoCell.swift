//
//  LabelInfoCell.swift
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

final class LabelInfoCell: UITableViewCell {

    @IBOutlet private var iconView: UIImageView!
    @IBOutlet private var infoLabel: UILabel!
    @IBOutlet private var infoLabelHeight: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.iconView.tintColor = ColorProvider.IconHint
        self.contentView.backgroundColor = ColorProvider.BackgroundNorm
        infoLabel.set(text: nil,
                      preferredFont: .subheadline,
                      textColor: ColorProvider.TextHint)
    }

    func config(info: String, icon: UIImage, cellHeight: CGFloat) {
        self.infoLabel.text = info
        self.iconView.image = icon
        self.infoLabelHeight.constant = cellHeight
    }
}
