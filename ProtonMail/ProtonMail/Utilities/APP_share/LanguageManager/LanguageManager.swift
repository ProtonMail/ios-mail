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

final class LanguageManager {
    enum Constant {
        static let languageSaveKey = "kProtonMailCurrentLanguageKey"
#if Enterprise
        static let languageAppGroup = "group.com.protonmail.protonmail"
#else
        static let languageAppGroup = "group.ch.protonmail.protonmail"
#endif
    }

    private let userDefault: UserDefaults?

    init(userDefault: UserDefaults? = .init(suiteName: Constant.languageAppGroup)) {
        self.userDefault = userDefault
    }

    func setupCurrentLanguage() {
        if userDefault?.string(forKey: Constant.languageSaveKey) == nil {
            let languages = userDefault?.object(forKey: "AppleLanguages") as? [String]
            if languages?.isEmpty == false,
               let currentLanguage = languages?.first {
                userDefault?.setValue(currentLanguage, forKey: Constant.languageSaveKey)
            }
        }

        guard let currentLanguage = currentLanguageCode() else {
            return
        }
        #if USE_ON_FLY_LOCALIZATION
        Bundle.setLanguage(currentLanguage, isLanguageRTL: isCurrentLanguageRTL())
        #endif
    }

    func currentLanguageCode() -> String? {
        return userDefault?.string(forKey: Constant.languageSaveKey)
    }

    func currentLanguageIndex() -> Int {
        guard let currentCode = currentLanguageCode() else {
            return 0
        }
        return ELanguage.languageCodes.firstIndex(of: currentCode) ?? 0
    }

    func currentLanguage() -> ELanguage {
        let index = currentLanguageIndex()
        return ELanguage.allCases[index]
    }

    func saveLanguage(by code: String) {
        guard ELanguage.languageCodes.contains(code) else {
            userDefault?.set(
                ELanguage.english.languageCode,
                forKey: Constant.languageSaveKey
            )
            return
        }
        userDefault?.set(code, forKey: Constant.languageSaveKey)

        #if USE_ON_FLY_LOCALIZATION
        Bundle.setLanguage(code, isLanguageRTL: isCurrentLanguageRTL())
        #endif
    }

    func isCurrentLanguageRTL() -> Bool {
        let index = currentLanguageIndex()
        return Locale.characterDirection(forLanguage: ELanguage.languageCodes[index]) == .rightToLeft
    }
}
