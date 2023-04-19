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

@testable import ProtonMail
import XCTest

class LanguageManagerTests: XCTestCase {
    var sut: LanguageManager!
    var userDefaultMock: UserDefaults!
    var randomSuiteName = String.randomString(10)
    var language: ELanguage!

    override func setUpWithError() throws {
        try super.setUpWithError()
        language = try XCTUnwrap(ELanguage.allCases.randomElement())
        userDefaultMock = .init(suiteName: randomSuiteName)
        sut = .init(userDefault: userDefaultMock)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        userDefaultMock.removePersistentDomain(forName: randomSuiteName)
        userDefaultMock = nil
        language = nil
    }

    func testSetupCurrentLanguage_languageSaveKeyIsNil_saveValueFromAppleLanguages() throws {
        userDefaultMock.set(["en"], forKey: "AppleLanguages")

        sut.setupCurrentLanguage()

        let value = try XCTUnwrap(
            userDefaultMock.string(forKey: LanguageManager.Constant.languageSaveKey)
        )
        XCTAssertEqual(value, "en")
    }

    func testCurrentLanguageIndex() {
        userDefaultMock.set(language.languageCode, forKey: LanguageManager.Constant.languageSaveKey)

        let result = sut.currentLanguageIndex()
        let index = ELanguage.languageCodes.firstIndex(of: language.languageCode)
        XCTAssertEqual(result, index)
    }

    func testCurrentLanguage() {
        userDefaultMock.set(language.languageCode, forKey: LanguageManager.Constant.languageSaveKey)

        XCTAssertEqual(sut.currentLanguage(), language)
    }

    func testSaveLanguageByCode() throws {
        sut.saveLanguage(by: language.languageCode)

        let value = try XCTUnwrap(userDefaultMock.string(forKey: LanguageManager.Constant.languageSaveKey))
        XCTAssertEqual(value, language.languageCode)
    }

    func testSaveLauguageByCode_withUnSupportedCode_languageIsSetToEnglish() throws {
        sut.saveLanguage(by: String.randomString(10))

        let value = try XCTUnwrap(userDefaultMock.string(forKey: LanguageManager.Constant.languageSaveKey))
        XCTAssertEqual(value, ELanguage.english.languageCode)
    }
}
