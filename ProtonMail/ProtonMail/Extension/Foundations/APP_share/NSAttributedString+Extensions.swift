//
//  NSAttributedString+Extensions.swift
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
//  along with Proton Mail. If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_Foundations
import UIKit
import ProtonCore_UIFoundations

extension NSAttributedString {

    static var empty: NSAttributedString {
        .init(string: "")
    }

    /**
     - parameters:
     - text: original string
     - search: search term to be highlighted in the string
     */
    class func highlightedString(text: String,
                                 textAttributes: [NSAttributedString.Key: Any]? = nil,
                                 search: String,
                                 font: UIFont) -> NSAttributedString {
        let resultText = text
        let searchTerm = search
        var attributes = textAttributes ?? FontManager.Default
        attributes = attributes.addTruncatingTail()
        let attributedString = NSMutableAttributedString(string: resultText,
                                                         attributes: attributes)
        let highlightedColor: UIColor = ColorProvider.BrandNorm
        let pattern = "(\(searchTerm))"
        let range = NSMakeRange(0, resultText.count)
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            regex.enumerateMatches(
                in: resultText,
                options: NSRegularExpression.MatchingOptions(),
                range: range,
                using: { (textCheckingResult, matchingFlags, stop) -> Void in
                    let subRange = textCheckingResult?.range
                    attributedString.addAttribute(.foregroundColor, value: highlightedColor, range: subRange!)
                    attributedString.addAttribute(.font, value: font, range: subRange!)
            })

            return attributedString
        } catch {
            return attributedString
        }
    }
}
