//
//  SettingsAccountCell.swift
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

class SettingsAccountCell: UITableViewCell {
    @IBOutlet private weak var shortNameView: UIView!
    @IBOutlet private weak var shortNameLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var mailLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!

    static var CellID: String {
        return "\(self)"
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.shortNameView.layer.cornerRadius = 8.0
        self.shortNameView.layer.masksToBounds = true
        self.shortNameView.backgroundColor = ColorProvider.BrandNorm
        self.shortNameLabel.adjustsFontSizeToFitWidth = true

        let pressView = UIView(frame: .zero)
        pressView.backgroundColor = ColorProvider.BackgroundSecondary
        self.selectedBackgroundView = pressView

        self.iconImageView.image = IconProvider.chevronRight
        self.iconImageView?.tintColor = ColorProvider.TextHint
    }

    func configure(name: String, email: String) {
        let nameAttribute = FontManager.DefaultSmall.addTruncatingTail()
        self.nameLabel.attributedText = NSAttributedString(string: name, attributes: nameAttribute)

        let emailAttribute = FontManager.CaptionWeak.addTruncatingTail()
        self.mailLabel.attributedText = NSAttributedString(string: email, attributes: emailAttribute)

        self.shortNameLabel.text = name.initials()
    }
}
