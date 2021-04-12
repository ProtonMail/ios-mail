//
//  PMFontAttributes.swift
//  ProtonMail - Created on 29.07.20.
//
//  Copyright (c) 2020 Proton Technologies AG
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
//

import UIKit

/// When needing customization, this typealias can make life easier to access the attributes.
public typealias PMFontAttributes = [NSAttributedString.Key: Any]

/// Sample usage:
/// `let str = NSAttributedString(string: "your string", attributes: .Headline )`
///
/// ```
/// let attributes = PMFontAttributes.Headline
/// attributes.alignment = .center
/// let str = NSAttributedString(string: "your string", attributes: attributes )
/// ```
///
/// Then, `label.attributedText = str`
extension Dictionary where Key == NSAttributedString.Key, Value: Any {

    // MARK: Headline
    public static var Headline: [NSAttributedString.Key: Any] {
        let font = UIFont.boldSystemFont(ofSize: 22)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.35,
            .font: font,
            .foregroundColor: UIColorManager.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    public static var HeadlineHint: [NSAttributedString.Key: Any] {
        let font = UIFont.boldSystemFont(ofSize: 22)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.35,
            .font: font,
            .foregroundColor: UIColorManager.TextWeak,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    public static var HeadlineSmall: [NSAttributedString.Key: Any] {
        let font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.18

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.41,
            .font: font,
            .foregroundColor: UIColorManager.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    // MARK: Default

    public static var DefaultStrong: [NSAttributedString.Key: Any] {
        let font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.18

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.41,
            .font: font,
            .foregroundColor: UIColorManager.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    public static var Default: [NSAttributedString.Key: Any] {
        let font = UIFont.systemFont(ofSize: 17)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.18

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.41,
            .font: font,
            .foregroundColor: UIColorManager.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    public static var DefaultWeak: [NSAttributedString.Key: Any] {
        let font = UIFont.systemFont(ofSize: 17)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.18

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.41,
            .font: font,
            .foregroundColor: UIColorManager.TextWeak,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    public static var DefaultHint: [NSAttributedString.Key: Any] {
        let font = UIFont.systemFont(ofSize: 17)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.18

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.41,
            .font: font,
            .foregroundColor: UIColorManager.TextHint,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    public static var DefaultDisabled: [NSAttributedString.Key: Any] {
        let font = UIFont.systemFont(ofSize: 17)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.18

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.41,
            .font: font,
            .foregroundColor: UIColorManager.TextDisabled,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    public static var DefaultInverted: [NSAttributedString.Key: Any] {
        let font = UIFont.systemFont(ofSize: 17)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.18

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.41,
            .font: font,
            .foregroundColor: UIColorManager.TextInverted,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    // MARK: DefaultSmall

    public static var DefaultSmallStrong: [NSAttributedString.Key: Any] {
        let font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12
        paragraphStyle.lineBreakMode = .byTruncatingTail

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.24,
            .font: font,
            .foregroundColor: UIColorManager.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    public static var DefaultSmall: [NSAttributedString.Key: Any] {
        let font = UIFont.systemFont(ofSize: 15)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.24,
            .font: font,
            .foregroundColor: UIColorManager.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    public static var DefaultSmallWeek: [NSAttributedString.Key: Any] {
        let font = UIFont.systemFont(ofSize: 15)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.24,
            .font: font,
            .foregroundColor: UIColorManager.TextWeak,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    public static var DefaultSmallDisabled: [NSAttributedString.Key: Any] {
        let font = UIFont.systemFont(ofSize: 15)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.24,
            .font: font,
            .foregroundColor: UIColorManager.TextDisabled,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    public static var DefaultSmallInverted: [NSAttributedString.Key: Any] {
        let font = UIFont.systemFont(ofSize: 15)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.24,
            .font: font,
            .foregroundColor: UIColorManager.TextInverted,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    // MARK: Caption

    public static var CaptionStrong: [NSAttributedString.Key: Any] {
        let font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.03

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.08,
            .font: font,
            .foregroundColor: UIColorManager.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    public static var Caption: [NSAttributedString.Key: Any] {
        let font = UIFont(name: "SFProDisplay-Regular", size: 13)!
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.03

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.08,
            .font: font,
            .foregroundColor: UIColorManager.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    public static var CaptionWeak: [NSAttributedString.Key: Any] {
        let font = UIFont.systemFont(ofSize: 13)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.03

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.08,
            .font: font,
            .foregroundColor: UIColorManager.TextWeak,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    public static var CaptionHint: [NSAttributedString.Key: Any] {
        let font = UIFont.systemFont(ofSize: 13)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.03

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.08,
            .font: font,
            .foregroundColor: UIColorManager.TextHint,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }

    // MARK: Helper

    public var paragraphStyle: NSParagraphStyle? {
        self[.paragraphStyle] as? NSParagraphStyle
    }

    public var mutableParagraphStyle: NSMutableParagraphStyle? {
        paragraphStyle?.mutableCopy() as? NSMutableParagraphStyle
    }

    public var alignment: NSTextAlignment? {
        get { paragraphStyle?.alignment }
        set( value ) {
            let paragraphStyle = mutableParagraphStyle ?? NSMutableParagraphStyle()
            paragraphStyle.alignment = value ?? .natural
            self[.paragraphStyle] = paragraphStyle as? Value
        }
    }

    public var lineHeightMultiple: CGFloat? {
        get { paragraphStyle?.lineHeightMultiple }
        set( value ) {
            let paragraphStyle = mutableParagraphStyle ?? NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = value ?? 1.0
            self[.paragraphStyle] = paragraphStyle as? Value
        }
    }

    public var foregroundColor: UIColor? {
        get { self[.foregroundColor] as? UIColor }
        set( color ) { self[.foregroundColor] = color as? Value }
    }
}
