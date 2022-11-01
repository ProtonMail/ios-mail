// Copyright (c) 2022 Proton AG
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
// settings language item  ***!!! this need match with LanguageManager.h
extension ELanguage {

    var nativeDescription: String {
        get {
            switch self {
            case .english:
                return "English"
            case .german:
                return "Deutsch"
            case .french:
                return "Français"
            case .russian:
                return "Русский"
            case .spanish:
                return "Español"
            case .turkish:
                return "Türkçe"
            case .polish:
                return "Polski"
            case .ukrainian:
                return "Українська"
            case .dutch:
                return "Dutch"
            case .italian:
                return "Italiano"
            case .portugueseBrazil:
                return "Português do Brasil"
            case .chineseSimplified:
                return "简体中文"
            case .chineseTraditional:
                return "繁體中文"
            case .catalan:
                return "Català"
            case .danish:
                return "Dansk"
            case  .czech:
                return "Čeština"
            case .portuguese:
                return "Português"
            case .romanian:
                return "Română"
            case .croatian:
                return "Hrvatski"
            case .hungarian:
                return "Magyar"
            case .icelandic:
                return "íslenska"
            case .kabyle:
                return "Taqbaylit"
            case .swedish:
                return "Svenska"
            case .japanese:
                return "日本語"
            case .indonesian:
                return "bahasa Indonesia"
            case .count:
                return ""
            @unknown default:
                return ""
            }
        }
    }

    // This code needs to match the project language folder
    var code: String {
        get {
            switch self {
            case .english:
                return "en"
            case .german:
                return "de"
            case .french:
                return "fr"
            case .russian:
                return "ru"
            case .spanish:
                 return "es"
            case .turkish:
                return "tr"
            case .polish:
                return "pl"
            case .ukrainian:
                return "uk"
            case .dutch:
                return "nl"
            case .italian:
                return "it"
            case .portugueseBrazil:
                return "pt-BR"
            case .chineseSimplified:
                return "zh-Hans"
            case .chineseTraditional:
                return "zh-Hant"
            case .catalan:
                return "ca"
            case .danish:
                return "da"
            case .czech:
                return "cs"
            case .portuguese:
                return "pt"
            case .romanian:
                return "ro"
            case .croatian:
                return "hr"
            case .hungarian:
                return "hu"
            case .icelandic:
                return "is"
            case .kabyle:
                return "kab"
            case .swedish:
                return "sv"
            case .japanese:
                return "ja"
            case .indonesian:
                return "id"
            case .count:
                return "en"
            @unknown default:
                return "en"
            }
        }
    }

    static func allItems() -> [ELanguage] {
        return [
            .catalan,
            .croatian,
            .czech,
            .chineseSimplified,
            .chineseTraditional,
            .danish,
            .dutch,
            .english,
            .french,
            .german,
            .hungarian,
            .icelandic,
            .indonesian,
            .italian,
            .japanese,
            .kabyle,
            .polish,
            .portuguese,
            .portugueseBrazil,
            .romanian,
            .russian,
            .spanish,
            .swedish,
            .turkish,
            .ukrainian
        ]
    }
}
