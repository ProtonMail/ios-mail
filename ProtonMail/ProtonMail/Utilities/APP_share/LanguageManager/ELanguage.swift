// Copyright (c) 2023 Proton Technologies AG
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

enum ELanguage: String, CaseIterable {
    case belarusian
    case catalan
    case chineseSimplified
    case chineseTraditional
    case croatian
    case czech
    case danish
    case dutch
    case english
    case french
    case german
    case greek
    case hungarian
    case icelandic
    case indonesian
    case italian
    case japanese
    case kabyle
    case polish
    case portuguese
    case portugueseBrazil
    case romanian
    case russian
    case spanish
    case swedish
    case turkish
    case ukrainian

    var languageString: String {
        switch self {
        case .chineseSimplified:
            return "Chinese Simplified"
        case .chineseTraditional:
            return "Chinese Traditional"
        default:
            return self.rawValue.capitalized
        }
    }

    var languageCode: String {
        switch self {
        case .belarusian:
            return "be"
        case .catalan:
            return "ca"
        case .chineseSimplified:
            return "zh-Hans"
        case .chineseTraditional:
            return "zh-Hant"
        case .croatian:
            return "hr"
        case .czech:
            return "cs"
        case .danish:
            return "da"
        case .dutch:
            return "nl"
        case .english:
            return "en"
        case .french:
            return "fr"
        case .german:
            return "de"
        case .greek:
            return "el"
        case .hungarian:
            return "hu"
        case .icelandic:
            return "is"
        case .indonesian:
            return "id"
        case .italian:
            return "it"
        case .japanese:
            return "ja"
        case .kabyle:
            return "kab"
        case .polish:
            return "pl"
        case .portuguese:
            return "pt"
        case .portugueseBrazil:
            return "pt-BR"
        case .romanian:
            return "ro"
        case .russian:
            return "ru"
        case .spanish:
            return "es"
        case .swedish:
            return "sv"
        case .turkish:
            return "tr"
        case .ukrainian:
            return "uk"
        }
    }

    var nativeDescription: String {
        switch self {
        case .belarusian:
            return "беларуская мова"
        case .catalan:
            return "Català"
        case .chineseSimplified:
            return "简体中文"
        case .chineseTraditional:
            return "繁體中文"
        case .croatian:
            return "Hrvatski"
        case  .czech:
            return "Čeština"
        case .danish:
            return "Dansk"
        case .dutch:
            return "Dutch"
        case .english:
            return "English"
        case .french:
            return "Français"
        case .german:
            return "Deutsch"
        case .greek:
            return "ελληνικά"
        case .hungarian:
            return "Magyar"
        case .icelandic:
            return "íslenska"
        case .indonesian:
            return "bahasa Indonesia"
        case .italian:
            return "Italiano"
        case .japanese:
            return "日本語"
        case .kabyle:
            return "Taqbaylit"
        case .polish:
            return "Polski"
        case .portuguese:
            return "Português"
        case .portugueseBrazil:
            return "Português do Brasil"
        case .romanian:
            return "Română"
        case .russian:
            return "Русский"
        case .spanish:
            return "Español"
        case .swedish:
            return "Svenska"
        case .turkish:
            return "Türkçe"
        case .ukrainian:
            return "Українська"
        }
    }

    static var languageCodes: [String] {
        return Self.allCases.reduce(into: []) { $0.append($1.languageCode) }
    }

    static var languageStrings: [String] {
        return Self.allCases.reduce(into: []) { $0.append($1.languageString) }
    }
}
