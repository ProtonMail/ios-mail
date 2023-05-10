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
    private var sut: LanguageManager!
    private var bundle: MockBundleType!
    private var userDefaultMock: UserDefaults!
    private let randomSuiteName = String.randomString(10)

    override func setUpWithError() throws {
        try super.setUpWithError()

        bundle = MockBundleType()
        userDefaultMock = .init(suiteName: randomSuiteName)
        sut = .init(bundle: bundle, userDefaults: userDefaultMock)

        // use something different than "en" which happens to be SUT's fallback language
        // this is to better expose some behavior
        bundle.preferredLocalizationsStub.fixture = ["es", "ja"]
    }

    override func tearDown() {
        sut = nil
        bundle = nil
        userDefaultMock.removePersistentDomain(forName: randomSuiteName)
        userDefaultMock = nil

        super.tearDown()
    }

    func testStorePreferredLanguage_overwritesPreviousUserDefaultsEntry() {
        XCTAssertNil(userDefaultMock.string(forKey: LanguageManager.Constants.languageSaveKey))

        sut.storePreferredLanguageToBeUsedByExtensions()

        XCTAssertEqual(userDefaultMock.string(forKey: LanguageManager.Constants.languageSaveKey), "es")

        userDefaultMock.set("de", forKey: LanguageManager.Constants.languageSaveKey)

        sut.storePreferredLanguageToBeUsedByExtensions()

        XCTAssertEqual(userDefaultMock.string(forKey: LanguageManager.Constants.languageSaveKey), "es")
    }

    func testTranslateBundle_whenStoredLanguageIsDifferentThanSelectedLanguage_proceedsWithTranslating() throws {
        userDefaultMock.set("pl", forKey: LanguageManager.Constants.languageSaveKey)

        sut.translateBundleToPreferredLanguageOfTheMainApp()

        XCTAssertEqual(bundle.setLanguageStub.callCounter, 1)
        let arguments = try XCTUnwrap(bundle.setLanguageStub.lastArguments)
        XCTAssertEqual(arguments.a1, "pl")
        XCTAssertEqual(arguments.a2, false)
    }

    func testTranslateBundle_whenStoredAndSelectedLanguagesAreTheSame_doesNothing() {
        userDefaultMock.set(bundle.preferredLocalizations[0], forKey: LanguageManager.Constants.languageSaveKey)
        sut.translateBundleToPreferredLanguageOfTheMainApp()

        XCTAssertEqual(bundle.setLanguageStub.callCounter, 0)
    }

    func testCurrentLanguageCode_returnValuePriority() {
        bundle.preferredLocalizationsStub.fixture = []
        userDefaultMock.removeObject(forKey: LanguageManager.Constants.languageSaveKey)

        XCTAssertEqual(sut.currentLanguageCode(), "en")

        bundle.preferredLocalizationsStub.fixture = ["it"]

        XCTAssertEqual(sut.currentLanguageCode(), "it")

        userDefaultMock.set("nl", forKey: LanguageManager.Constants.languageSaveKey)

        XCTAssertEqual(sut.currentLanguageCode(), "nl")
    }
}
