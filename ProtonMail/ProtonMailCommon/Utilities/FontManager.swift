//
//  FontManager.swift
//  ProtonMail - Created on 2020.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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

import Foundation
import ProtonCore_UIFoundations
import UIKit

struct FontManager {

    static let Headline: [NSAttributedString.Key: Any] = {
        let font = UIFont.boldSystemFont(ofSize: 22)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.35,
            .font: font,
            .foregroundColor: ColorProvider.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()
    
    static let subHeadline: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 22)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.35,
            .font: font,
            .foregroundColor: ColorProvider.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    static let MessageHeader: [NSAttributedString.Key: Any] = {
        let font = UIFont.boldSystemFont(ofSize: 20)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.35,
            .font: font,
            .foregroundColor: ColorProvider.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    static let HeadlineHint: [NSAttributedString.Key: Any] = {
        let font = UIFont.boldSystemFont(ofSize: 22)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.35,
            .font: font,
            .foregroundColor: ColorProvider.TextWeak,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()
    
    static let HeadlineSmall: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.18
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.41,
            .font: font,
            .foregroundColor: ColorProvider.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    static let DefaultStrongBold: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 17, weight: .bold)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.18
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.41,
            .font: font,
            .foregroundColor: ColorProvider.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    static let DefaultStrong: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.18
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.41,
            .font: font,
            .foregroundColor: ColorProvider.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    static let Default: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 17)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.18
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.41,
            .font: font,
            .foregroundColor: ColorProvider.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    static let DefaultWeak: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 17)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.18
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.41,
            .font: font,
            .foregroundColor: ColorProvider.TextWeak,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    static let DefaultDisabled: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 17)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.18
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.41,
            .font: font,
            .foregroundColor: ColorProvider.TextDisabled,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    static let DefaultHint: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 17)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.18
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.41,
            .font: font,
            .foregroundColor: ColorProvider.TextHint,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()
    
    static let DefaultSmallStrong: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.24,
            .font: font,
            .foregroundColor: ColorProvider.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()
    
    static let DefaultSmall: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 15)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.24,
            .font: font,
            .foregroundColor: ColorProvider.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()
    
    static let DefaultSmallWeak: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 15)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.24,
            .font: font,
            .foregroundColor: ColorProvider.TextWeak,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()
    
    static let DefaultSmallHint: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 15)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.24,
            .font: font,
            .foregroundColor: ColorProvider.TextHint,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()
    
    static var DefaultSmallDisabled: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 15)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.24,
            .font: font,
            .foregroundColor: ColorProvider.TextDisabled,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()
    
    static let CaptionStrong: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 13, weight: .semibold) // Check with design, if it's correct one
        //let font = UIFont(name: "SFProDisplay-Semibold", size: 13)!
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.03
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.08,
            .font: font,
            .foregroundColor: ColorProvider.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    static let CaptionStrongInverted: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 13, weight: .semibold) // Check with design, if it's correct one
        //let font = UIFont(name: "SFProDisplay-Semibold", size: 13)!
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.03

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.08,
            .font: font,
            .foregroundColor: ColorProvider.TextInverted,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()
    
    static let Caption: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 13)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.03
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.08,
            .font: font,
            .foregroundColor: ColorProvider.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    static let CaptionInverted: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 13)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.03

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.08,
            .font: font,
            .foregroundColor: ColorProvider.TextInverted,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()
    
    static let CaptionWeak: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 13)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.03
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.08,
            .font: font,
            .foregroundColor: ColorProvider.TextWeak,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()
    
    static let CaptionDisabled: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 13)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.03
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.08,
            .font: font,
            .foregroundColor: ColorProvider.TextDisabled,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()
    
    static let CaptionHint: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 13)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.03
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.08,
            .font: font,
            .foregroundColor: ColorProvider.TextHint,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()
    
    static let OverlineStrong: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 11.0)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07
        
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.07,
            .font: font,
            .foregroundColor: ColorProvider.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    static let OverlineSemiBoldTextInverted: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 11.0, weight: .semibold)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.07,
            .font: font,
            .foregroundColor: ColorProvider.TextInverted,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    static let OverlineSemiBoldText: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 11.0, weight: .semibold)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.07,
            .font: font,
            .foregroundColor: ColorProvider.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    static let OverlineSemiBoldTextWeak: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 11.0, weight: .semibold)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.07,
            .font: font,
            .foregroundColor: ColorProvider.TextWeak,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    static let OverlineRegularInteractionStrong: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 11.0)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.07,
            .font: font,
            .foregroundColor: ColorProvider.InteractionStrong,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    static let OverlineRegularTextWeak: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 11.0)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.07,
            .font: font,
            .foregroundColor: ColorProvider.TextWeak,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    static let body3RegularWeak: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 14)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.07,
            .font: font,
            .foregroundColor: ColorProvider.TextWeak,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    static let body2RegularInverted: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 15)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.24,
            .font: font,
            .foregroundColor: ColorProvider.TextInverted,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()
    
    static let body2RegularNorm: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 15)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: -0.24,
            .font: font,
            .foregroundColor: ColorProvider.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    static let body3RegularNorm: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 14)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.07,
            .font: font,
            .foregroundColor: ColorProvider.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    static let body3RegularTextInverted: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 14)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07

        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 0.07,
            .font: font,
            .foregroundColor: ColorProvider.TextInverted,
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()

    static let body3RegularInteractionNorm: [NSAttributedString.Key: Any] = {
        let font = UIFont.systemFont(ofSize: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        paragraphStyle.lineBreakMode = .byTruncatingTail

        return [
            .kern: -0.24,
            .font: font,
            .foregroundColor: ColorProvider.InteractionNorm,
            .paragraphStyle: paragraphStyle
        ]
    }()

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
