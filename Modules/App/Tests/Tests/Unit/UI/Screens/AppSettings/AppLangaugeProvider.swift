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

@testable import ProtonMail
import Testing

class AppLanguageProviderTests {

    var sut: AppLangaugeProvider!
    var stubbedLocale: Locale!
    private var bundleSpy: BundleSpy!

    init() {
        stubbedLocale = .init(identifier: "en")
        bundleSpy = BundleSpy()
        sut = AppLangaugeProvider(
            currentLocale: stubbedLocale,
            mainBundle: bundleSpy
        )
    }

    deinit {
        stubbedLocale = nil
        bundleSpy = nil
        sut = nil
    }

    @Test
    func appLanguageWhenThereAreNoPreferedLanguages_ItReturnsCurrentLocaleLanguage() {
        #expect(sut.appLangauge == "English")
    }

    @Test
    func appLanguageWhenThereThereArePreferedLanguages_ItReturnsFirstPrefferedLanguage() {
        bundleSpy.preferredLocalizationsStub = ["pl"]
        #expect(sut.appLangauge == "Polish")
    }

}

class BundleSpy: Bundle, @unchecked Sendable {

    var preferredLocalizationsStub: [String] = ["en"]

    override var preferredLocalizations: [String] {
        preferredLocalizationsStub
    }

}
