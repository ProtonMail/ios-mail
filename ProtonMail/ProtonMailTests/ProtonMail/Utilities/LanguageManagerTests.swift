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

    override func setUpWithError() throws {
        try super.setUpWithError()

        bundle = MockBundleType()
        sut = .init(bundle: bundle)
    }

    override func tearDown() {
        sut = nil
        bundle = nil

        super.tearDown()
    }

    func testCurrentLanguageCode_returnValuePriority() {
        bundle.preferredLocalizationsStub.fixture = []

        XCTAssertEqual(sut.currentLanguageCode(), "en")

        bundle.preferredLocalizationsStub.fixture = ["it"]

        XCTAssertEqual(sut.currentLanguageCode(), "it")
    }
}
