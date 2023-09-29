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

/*
 The main problem this class is solving:

 Extensions such as Share have a separate Bundle.main, and they don't inherit the main app's preferred
 localizations, but instead use the global system setting.
 This is probably intentional by Apple, as the extensions are seen as parts of the system first and parts of the main app second,
 but we have a requirement to keep the Share extension translated.

 Actions:
 1. We need to perform on-the-fly localization of the Share extension whenever it is launched.
 2. To achieve #1, we need to save the preferred language under kProtonMailCurrentLanguageKey to pass that info
 to the extension.

 A second purpose of this class is to use the on-the-fly localization to test all available translations.
 */
final class LanguageManager {
    enum Constants {
        static let languageSaveKey = "kProtonMailCurrentLanguageKey"
#if Enterprise
        static let languageAppGroup = "group.com.protonmail.protonmail"
#else
        static let languageAppGroup = "group.ch.protonmail.protonmail"
#endif
    }

    private let bundle: BundleType
    private let userDefaults: UserDefaults?

    private var preferredLanguageCodeSavedInUserDefaults: String? {
        get {
            userDefaults?.string(forKey: Constants.languageSaveKey)
        }
        set {
            userDefaults?.set(newValue, forKey: Constants.languageSaveKey)
        }
    }

    private var preferredLanguageCodeSelectedInSettings: String? {
        bundle.preferredLocalizations.first
    }

    init(
        bundle: BundleType = Bundle.main,
        userDefaults: UserDefaults? = .init(suiteName: Constants.languageAppGroup)
    ) {
        self.bundle = bundle
        self.userDefaults = userDefaults
    }

    func storePreferredLanguageToBeUsedByExtensions() {
        preferredLanguageCodeSavedInUserDefaults = preferredLanguageCodeSelectedInSettings
    }

    func translateBundleToPreferredLanguageOfTheMainApp() {
        let languageCode = currentLanguageCode()

        guard languageCode != preferredLanguageCodeSelectedInSettings else {
            return
        }

        let isLanguageRTL = Locale.characterDirection(forLanguage: languageCode) == .rightToLeft
        bundle.setLanguage(with: languageCode, isLanguageRTL: isLanguageRTL)
    }

    func currentLanguageCode() -> String {
        preferredLanguageCodeSavedInUserDefaults ?? preferredLanguageCodeSelectedInSettings ?? "en"
    }
}

// sourcery: mock
protocol BundleType {
    var preferredLocalizations: [String] { get }

    func setLanguage(with code: String, isLanguageRTL: Bool)
}

extension Bundle: BundleType {
    func setLanguage(with code: String, isLanguageRTL: Bool) {
        Self.setLanguage(code, isLanguageRTL: isLanguageRTL)
    }
}
