// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_UIFoundations
import UIKit

extension UITextView {
    func set(
        text: String?,
        preferredFont: UIFont.TextStyle,
        weight: UIFont.Weight = .regular,
        textColor: UIColor = ColorProvider.TextNorm
    ) {
        self.text = text
        apply(textStyle: preferredFont, weight: weight, textColor: textColor)
    }

    func set(
        text: NSAttributedString,
        preferredFont: UIFont.TextStyle,
        weight: UIFont.Weight = .regular,
        textColor: UIColor = ColorProvider.TextNorm
    ) {
        self.attributedText = text
        apply(textStyle: preferredFont, weight: weight, textColor: textColor)
    }

    private func apply(textStyle: UIFont.TextStyle, weight: UIFont.Weight, textColor: UIColor) {
        self.font = .preferredFont(for: textStyle, weight: weight)
        self.adjustsFontForContentSizeCategory = true
        self.textColor = textColor
    }
}
