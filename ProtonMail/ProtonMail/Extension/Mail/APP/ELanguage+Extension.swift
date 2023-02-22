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
            case .belarusian:
                return "беларуская мова"
            case .catalan:
                return "Català"
            case .chineseSimplified:
                return "简体中文"
            case .chineseTraditional:
                return "繁體中文"
            case .count:
                return ""
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
            @unknown default:
                return ""
            }
        }
    }

    // This code needs to match the project language folder
    var code: String {
        get {
            switch self {
            case .belarusian:
                return "be"
            case .catalan:
                return "ca"
            case .chineseSimplified:
                return "zh-Hans"
            case .chineseTraditional:
                return "zh-Hant"
            case .count:
                return "en"
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
            @unknown default:
                return "en"
            }
        }
    }

    static func allItems() -> [ELanguage] {
        return [
            .belarusian,
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
            .greek,
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
