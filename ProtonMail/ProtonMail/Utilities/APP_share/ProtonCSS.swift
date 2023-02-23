// Copyright (c) 2022 Proton Technologies AG
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

import Foundation
import ProtonCore_UIFoundations

enum ProtonCSS {
    /// For message detail view, general case
    case viewer
    /// For message detail view, light mode only
    case viewerLightOnly
    /// For composer, general case
    case htmlEditor

    func content() throws -> String {
        switch self {
        case .viewer:
            return try css(fileName: "content")
        case .viewerLightOnly:
            return try lightCSS()
        case .htmlEditor:
            return try css(fileName: "HtmlEditor")
        }
    }

    private func css(fileName: String) throws -> String {
        guard let bundle = Bundle.main.path(forResource: fileName, ofType: "css") else {
            return .empty
        }
        let content = try String(contentsOfFile: bundle, encoding: .utf8)

        var backgroundColor = ColorProvider.BackgroundNorm.toHex()
        var textColor = ColorProvider.TextNorm.toHex()
        var brandColor = ColorProvider.BrandNorm.toHex()

        var darkBackgroundColor = ColorProvider.BackgroundNorm.toHex()
        var darkTextColor = ColorProvider.TextNorm.toHex()
        var darkBrandColor = ColorProvider.BrandNorm.toHex()

        if #available(iOS 13.0, *) {
            let trait = UITraitCollection(userInterfaceStyle: .dark)
            darkBackgroundColor = ColorProvider.BackgroundNorm.resolvedColor(with: trait).toHex()
            darkTextColor = ColorProvider.TextNorm.resolvedColor(with: trait).toHex()
            darkBrandColor = ColorProvider.BrandNorm.resolvedColor(with: trait).toHex()

            let lightTrait = UITraitCollection(userInterfaceStyle: .light)
            backgroundColor = ColorProvider.BackgroundNorm.resolvedColor(with: lightTrait).toHex()
            textColor = ColorProvider.TextNorm.resolvedColor(with: lightTrait).toHex()
            brandColor = ColorProvider.BrandNorm.resolvedColor(with: lightTrait).toHex()
        }

        return content
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "{{proton-background-color}}", with: backgroundColor)
            .replacingOccurrences(of: "{{proton-text-color}}", with: textColor)
            .replacingOccurrences(of: "{{proton-brand-color}}", with: brandColor)
            .replacingOccurrences(of: "{{proton-background-color-dark}}", with: darkBackgroundColor)
            .replacingOccurrences(of: "{{proton-text-color-dark}}", with: darkTextColor)
            .replacingOccurrences(of: "{{proton-brand-color-dark}}", with: darkBrandColor)
    }

    private func lightCSS() throws -> String {
        guard let bundle = Bundle.main.path(forResource: "content_light", ofType: "css") else {
            return .empty
        }

        let content = try String(contentsOfFile: bundle, encoding: .utf8)

        let brandColor: String
        if #available(iOS 13.0, *) {
            let trait = UITraitCollection(userInterfaceStyle: .light)
            brandColor = ColorProvider.BrandNorm.resolvedColor(with: trait).toHex()
        } else {
            brandColor = ColorProvider.BrandNorm.toHex()
        }
        return content
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "{{proton-brand-color}}", with: brandColor)
    }
}
