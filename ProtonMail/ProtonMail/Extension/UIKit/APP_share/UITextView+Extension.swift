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
        let copiedText = NSMutableAttributedString(attributedString: text)
        let wholeRange = NSRange(location: 0, length: (text.string as NSString).length)
        copiedText.addAttribute(.foregroundColor, value: textColor, range: wholeRange)
        text.enumerateAttribute(.backgroundColor, in: wholeRange) { value, range, _ in
            if value == nil { return }
            copiedText.addAttribute(.foregroundColor, value: String.highlightTextColor, range: range)
        }
        self.attributedText = copiedText
        self.font = .adjustedFont(forTextStyle: preferredFont, weight: weight)
        self.adjustsFontForContentSizeCategory = true

    }

    private func apply(textStyle: UIFont.TextStyle, weight: UIFont.Weight, textColor: UIColor) {
        self.font = .preferredFont(for: textStyle, weight: weight)
        self.adjustsFontForContentSizeCategory = true
        self.textColor = textColor
    }

    func setStyledTextWithLink(text: String, textLink: String, linkUrl: String) {
        let fullText = String.localizedStringWithFormat(text, textLink)
        let attr = FontManager.CaptionWeak.lineBreakMode(.byWordWrapping)
        let attributedString = NSMutableAttributedString(string: fullText, attributes: attr)
        if let subrange = fullText.range(of: textLink) {
            let nsRange = NSRange(subrange, in: fullText)
            attributedString.addAttribute(.link, value: linkUrl, range: nsRange)
            linkTextAttributes = [.foregroundColor: ColorProvider.InteractionNorm as UIColor]
        }
        attributedText = attributedString
    }
}
