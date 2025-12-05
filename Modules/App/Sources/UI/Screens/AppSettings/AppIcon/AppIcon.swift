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
    case weather
    case notes
    case calculator

    static var alternateIcons: [AppIcon] {
        allCases.filter { icon in icon != .default }
    }

    init(rawValue: String?) {
        switch rawValue {
        case Self.appIconNotes: self = .notes
        case Self.appIconWeather: self = .weather
        case Self.appIconCalculator: self = .calculator
        default: self = .default
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
        case .default: ImageResource.appIconPreview
        case .weather: ImageResource.appIconWeatherPreview
        case .notes: ImageResource.appIconNotesPreview
        case .calculator: ImageResource.appIconCalculatorPreview
        }
    }

    private static let appIconNotes: String = "AppIcon-notes"
    private static let appIconWeather: String = "AppIcon-weather"
    private static let appIconCalculator: String = "AppIcon-calculator"
}
