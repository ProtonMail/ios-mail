//
//  UILabel+Extension.swift
//  Proton Mail
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

import UIKit
import ProtonCore_UIFoundations

extension UILabel {

    convenience init(attributedString: NSAttributedString) {
        self.init()
        self.attributedText = attributedString
        self.sizeToFit()
    }

    convenience init(font: UIFont, text: String, textColor: UIColor) {
        self.init()
        self.font = font
        self.numberOfLines = 1
        self.text = text
        self.textColor = textColor
        self.sizeToFit()
    }

    func set(
        text: String?,
        preferredFont: UIFont.TextStyle,
        weight: UIFont.Weight = .regular,
        textColor: UIColor = ColorProvider.TextNorm,
        lineBreakMode: NSLineBreakMode = .byTruncatingTail
    ) {
        self.text = text
        self.font = .preferredFont(for: preferredFont, weight: weight)
        self.adjustsFontForContentSizeCategory = true
        self.textColor = textColor
        self.lineBreakMode = lineBreakMode
    }
}
