//
//  SettingsAccountCell.swift
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

        self.shortNameView.layer.cornerRadius = 2.0
        self.shortNameView.layer.masksToBounds = true
        self.shortNameLabel.adjustsFontSizeToFitWidth = true

        let pressView = UIView(frame: .zero)
        pressView.backgroundColor = ColorProvider.BackgroundSecondary
        self.selectedBackgroundView = pressView

        self.iconImageView.image = #imageLiteral(resourceName: "cell_right_arrow").withRenderingMode(.alwaysTemplate)
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
