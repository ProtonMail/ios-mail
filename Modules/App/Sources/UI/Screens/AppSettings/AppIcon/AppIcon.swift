// Copyright (c) 2025 Proton Technologies AG
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

enum AppIcon: CaseIterable, Hashable {
    case `default`
    case notes
    case weather
    case calculator

    init(rawValue: String?) {
        switch rawValue {
        case Self.appIconNotes: self = .notes
        case Self.appIconWeather: self = .weather
        case Self.appIconCalculator: self = .calculator
        default: self = .default
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .default: return L10n.Settings.AppIcon.primary
        case .notes: return L10n.Settings.AppIcon.notes
        case .weather: return L10n.Settings.AppIcon.weather
        case .calculator: return L10n.Settings.AppIcon.calculator
        }
    }

    var alternateIconName: String? {
        switch self {
        case .default: nil
        case .notes: Self.appIconNotes
        case .weather: Self.appIconWeather
        case .calculator: Self.appIconCalculator
        }
    }

    var preview: ImageResource {
        switch self {
        case .default: return ImageResource.appIconPreview
        case .weather: return ImageResource.appIconWeatherPreview
        case .notes: return ImageResource.appIconNotesPreview
        case .calculator: return ImageResource.appIconCalculatorPreview
        }
    }

    private static let appIconNotes: String = "AppIcon-notes"
    private static let appIconWeather: String = "AppIcon-weather"
    private static let appIconCalculator: String = "AppIcon-calculator"
}
