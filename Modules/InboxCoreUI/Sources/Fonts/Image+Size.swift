//
// Copyright (c) 2026 Proton Technologies AG
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

import SwiftUI
import UIKit

public extension Image {
    func size(_ style: Font.TextStyle) -> some View {
        let uiFont = DynamicImageSize.cappedFont(forTextStyle: style.toUIFontTextStyle())
        return
            self
            .resizable()
            .scaledToFit()
            .frame(width: uiFont.pointSize, height: uiFont.pointSize)
    }
}

private extension Font.TextStyle {
    func toUIFontTextStyle() -> UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        @unknown default: return .body
        }
    }
}

private enum DynamicImageSize {
    static func cappedFont(forTextStyle style: UIFont.TextStyle) -> UIFont {
        let currentCategory = UIApplication.shared.preferredContentSizeCategory
        let cappedCategory = min(currentCategory, DynamicFontSize.largestSupportedSizeCategory)
        return UIFont.preferredFont(
            forTextStyle: style,
            compatibleWith: UITraitCollection(preferredContentSizeCategory: cappedCategory)
        )
    }
}
