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
    case notesMono
    case weather
    case weatherMono
    case calculator
    case calculatorMono

    static var alternateIcons: [AppIcon] {
        allCases.filter { icon in icon != .default }
    }

    init(rawValue: String?) {
        switch rawValue {
        case Self.appIconNotes: self = .notes
        case Self.appIconNotesMono: self = .notesMono
        case Self.appIconWeather: self = .weather
        case Self.appIconWeatherMono: self = .weatherMono
        case Self.appIconCalculator: self = .calculator
        case Self.appIconCalculatorMono: self = .calculatorMono
        default: self = .default
        }
    }

    var alternateIconName: String? {
        switch self {
        case .default: nil
        case .notes: Self.appIconNotes
        case .notesMono: Self.appIconNotesMono
        case .weather: Self.appIconWeather
        case .weatherMono: Self.appIconWeatherMono
        case .calculator: Self.appIconCalculator
        case .calculatorMono: Self.appIconCalculatorMono
        }
    }

    var preview: ImageResource {
        switch self {
        case .default: ImageResource.appIconPreview
        case .weather: ImageResource.appIconWeatherPreview
        case .weatherMono: ImageResource.appIconWeatherMonoPreview
        case .notes: ImageResource.appIconNotesPreview
        case .notesMono: ImageResource.appIconNotesMonoPreview
        case .calculator: ImageResource.appIconCalculatorPreview
        case .calculatorMono: ImageResource.appIconCalculatorMonoPreview
        }
    }

    private static let appIconNotes: String = "AppIcon-notes"
    private static let appIconNotesMono: String = "AppIcon-notes-mono"
    private static let appIconWeather: String = "AppIcon-weather"
    private static let appIconWeatherMono: String = "AppIcon-weather-mono"
    private static let appIconCalculator: String = "AppIcon-calculator"
    private static let appIconCalculatorMono: String = "AppIcon-calculator-mono"
}
