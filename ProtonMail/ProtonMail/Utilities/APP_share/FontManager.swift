//
//  FontManager.swift
//  Proton Mail - Created on 2020.
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

import Foundation
import ProtonCore_UIFoundations
import UIKit

struct FontManager {

    static var Headline: [NSAttributedString.Key: Any] {
        let font = UIFont.adjustedFont(forTextStyle: .title2, weight: .bold)
        let foregroundColor: UIColor = ColorProvider.TextNorm
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.35,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var subHeadline: [NSAttributedString.Key: Any] {
        let font = UIFont.adjustedFont(forTextStyle: .title2)
        let foregroundColor: UIColor = ColorProvider.TextNorm
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.35,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var MessageHeader: [NSAttributedString.Key: Any] {
        let font = UIFont.adjustedFont(forTextStyle: .title3)
        let foregroundColor: UIColor = ColorProvider.TextNorm
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.35,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var HeadlineSmall: [NSAttributedString.Key: Any] {
        let font = UIFont.adjustedFont(forTextStyle: .headline)
        let foregroundColor: UIColor = ColorProvider.TextNorm
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.18

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.41,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var DefaultStrong: [NSAttributedString.Key: Any] {
        let font = UIFont.adjustedFont(forTextStyle: .body)
        let foregroundColor: UIColor = ColorProvider.TextNorm
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.18

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.41,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var Default: [NSAttributedString.Key: Any] {
        let font = UIFont.adjustedFont(forTextStyle: .body)
        let foregroundColor: UIColor = ColorProvider.TextNorm
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.18

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.41,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var DefaultWeak: [NSAttributedString.Key: Any] {
        let font = UIFont.adjustedFont(forTextStyle: .body)
        let foregroundColor: UIColor = ColorProvider.TextWeak
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.18

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.41,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var DefaultSmallStrong: [NSAttributedString.Key: Any] {
        let font = UIFont.adjustedFont(forTextStyle: .subheadline)
        let foregroundColor: UIColor = ColorProvider.TextNorm
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.24,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var DefaultSmall: [NSAttributedString.Key: Any] {
        let font = UIFont.adjustedFont(forTextStyle: .subheadline)
        let foregroundColor: UIColor = ColorProvider.TextNorm
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.24,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var DefaultSmallWeak: [NSAttributedString.Key: Any] {
        let font = UIFont.adjustedFont(forTextStyle: .subheadline)
        let foregroundColor: UIColor = ColorProvider.TextWeak
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.24,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var CaptionStrong: [NSAttributedString.Key: Any] {
        let font = UIFont.adjustedFont(forTextStyle: .footnote, weight: .semibold) // Check with design, if it's correct one
        // let font = UIFont(name: "SFProDisplay-Semibold", size: 13)!
        let foregroundColor: UIColor = ColorProvider.TextNorm
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.03

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.08,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var CaptionStrongInverted: [NSAttributedString.Key: Any] {
        let font = UIFont.adjustedFont(forTextStyle: .footnote, weight: .semibold) // Check with design, if it's correct one
        // let font = UIFont(name: "SFProDisplay-Semibold", size: 13)!
        let foregroundColor: UIColor = ColorProvider.TextInverted
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.03

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.08,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var Caption: [NSAttributedString.Key: Any] {
        let font = UIFont.adjustedFont(forTextStyle: .footnote)
        let foregroundColor: UIColor = ColorProvider.TextNorm
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.03

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.08,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var CaptionInverted: [NSAttributedString.Key: Any] {
        let font = UIFont.adjustedFont(forTextStyle: .footnote)
        let foregroundColor: UIColor = ColorProvider.TextInverted
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.03

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.08,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var CaptionWeak: [NSAttributedString.Key: Any] {
        let font = UIFont.adjustedFont(forTextStyle: .footnote)
        let foregroundColor: UIColor = ColorProvider.TextWeak
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.03

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.08,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var OverlineRegularInteractionStrong: [NSAttributedString.Key: Any] {
        let font = UIFont.adjustedFont(forTextStyle: .caption2)
        let foregroundColor: UIColor = ColorProvider.InteractionStrong
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.07,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var OverlineRegularTextWeak: [NSAttributedString.Key: Any] {
        let font = UIFont.adjustedFont(forTextStyle: .caption2)
        let foregroundColor: UIColor = ColorProvider.TextWeak
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.07,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var body3RegularWeak: [NSAttributedString.Key: Any] {
        // The original font size is 14, but font style doesn't have style with 14px
        // Round down to 13 px, .footnote
        let font = UIFont.adjustedFont(forTextStyle: .footnote)
        let foregroundColor: UIColor = ColorProvider.TextWeak
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.07,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var body2RegularInverted: [NSAttributedString.Key: Any] {
        let font = UIFont.adjustedFont(forTextStyle: .subheadline)
        let foregroundColor: UIColor = ColorProvider.TextInverted
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.24,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var body3RegularNorm: [NSAttributedString.Key: Any] {
        // The original font size is 14, but font style doesn't have style with 14px
        // Round down to 13 px, .footnote
        let font = UIFont.adjustedFont(forTextStyle: .footnote)
        let foregroundColor: UIColor = ColorProvider.TextNorm
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.07,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var body3RegularTextInverted: [NSAttributedString.Key: Any] {
        // The original font size is 14, but font style doesn't have style with 14px
        // Round down to 13 px, .footnote
        let font = UIFont.adjustedFont(forTextStyle: .footnote)
        let foregroundColor: UIColor = ColorProvider.TextInverted
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.07,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    static var body1BoldNorm: [NSAttributedString.Key: Any] {
        let font = UIFont.adjustedFont(forTextStyle: .body)
        let foregroundColor: UIColor = ColorProvider.TextNorm
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.18

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.24,
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }
}

extension String {

    func apply(style: [NSAttributedString.Key: Any]) -> NSAttributedString {
        NSAttributedString(string: self, attributes: style)
    }

}

extension Dictionary where Key == NSAttributedString.Key, Value == Any {
    func addTruncatingTail(mode: NSLineBreakMode = .byTruncatingTail) -> Self {
        var attributes = self
        if let style = attributes[NSAttributedString.Key.paragraphStyle] as? NSMutableParagraphStyle,
           let newStyle = style.mutableCopy() as? NSMutableParagraphStyle {
            newStyle.lineBreakMode = mode
            attributes[NSAttributedString.Key.paragraphStyle] = newStyle
        } else {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = mode
            attributes[NSAttributedString.Key.paragraphStyle] = paragraphStyle
        }
        return attributes
    }

    func lineBreakMode(_ mode: NSLineBreakMode = .byTruncatingTail) -> Self {
        var attributes = self
        if let style = attributes[NSAttributedString.Key.paragraphStyle] as? NSMutableParagraphStyle,
           let newStyle = style.mutableCopy() as? NSMutableParagraphStyle {
            newStyle.lineBreakMode = mode
            attributes[NSAttributedString.Key.paragraphStyle] = newStyle
        } else {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = mode
            attributes[NSAttributedString.Key.paragraphStyle] = paragraphStyle
        }
        return attributes
    }

    func link(url: String) -> Self {
        self + [.link: url]
    }

    func foregroundColor(_ color: UIColor) -> Self {
        var attributes = self
        attributes[.foregroundColor] = color
        return attributes
    }

    func alignment(_ alignment: NSTextAlignment) -> Self {
        var attributes = self
        if let style = attributes[NSAttributedString.Key.paragraphStyle] as? NSMutableParagraphStyle,
           let newStyle = style.mutableCopy() as? NSMutableParagraphStyle {
            newStyle.alignment = alignment
            attributes[NSAttributedString.Key.paragraphStyle] = newStyle
        } else {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = alignment
            attributes[NSAttributedString.Key.paragraphStyle] = paragraphStyle
        }
        return attributes
    }

}
