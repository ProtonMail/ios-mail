//
//  UIFont+Extension.swift
//  ProtonCore-UIFoundations - Created on 20.07.22.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

extension UIFont {
    public static func preferredFont(for style: TextStyle, weight: Weight) -> UIFont {
        let metrics = UIFontMetrics(forTextStyle: style)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: weight)
        let limit = UIFont.fontLimit(for: style)
        if DFSSetting.limitToXXXLarge {
            return metrics.scaledFont(for: font, maximumPointSize: limit)
        } else {
            return metrics.scaledFont(for: font)
        }
    }

    public static func adjustedFont(
        forTextStyle style: TextStyle,
        weight: Weight = .regular,
        fontSize: CGFloat? = nil
    ) -> UIFont {
        if DFSSetting.enableDFS {
            return .preferredFont(for: style, weight: weight)
        } else {
            let pointSize = UIFont.defaultPointSize(forTextStyle: style)
            let size = fontSize ?? pointSize
            return .systemFont(ofSize: size, weight: weight)
        }
    }

    // From Apple document
    // https://developer.apple.com/design/human-interface-guidelines/foundations/typography/#dynamic-type-sizes
    // Large (Default)
    private static func defaultPointSize(forTextStyle style: TextStyle) -> CGFloat {
        switch style {
        case .largeTitle:
            return 34
        case .title1:
            return 28
        case .title2:
            return 22
        case .title3:
            return 20
        case .headline:
            return 17
        case .subheadline:
            return 15
        case .body:
            return 17
        case .callout:
            return 16
        case .footnote:
            return 13
        case .caption1:
            return 12
        case .caption2:
            return 11
        default:
            return 17
        }
    }

    // From Apple document
    // https://developer.apple.com/design/human-interface-guidelines/foundations/typography/#dynamic-type-sizes
    // xxxLarge
    public static func fontLimit(for style: TextStyle) -> CGFloat {
        switch(style) {
        case .largeTitle:
            return 48
        case .title1:
            return 41
        case .title2:
            return 34
        case .title3:
            return 32
        case .headline:
            return 29
        case .body:
            return 29
        case .callout:
            return 28
        case .subheadline:
            return 28
        case .footnote:
            return 24
        case .caption1:
            return 23
        case .caption2:
            return 22
        default:
            return 22
        }
    }
}
