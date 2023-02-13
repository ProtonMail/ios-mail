// Copyright (c) 2022 Proton Technologies AG
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

import XCTest
@testable import ProtonMail

private final class LocalizationPreviewUIMock: LocalizationPreviewUIProtocol {
    private(set) var updateTimes: Int = 0
    func updateTable() {
        updateTimes += 1
    }
}

final class LocalizationPreviewVMTests: XCTestCase {
    private var sut: LocalizationPreviewVM!
    private var uiMock: LocalizationPreviewUIMock!

    override func setUpWithError() throws {
        sut = LocalizationPreviewVM()
        uiMock = LocalizationPreviewUIMock()
        sut.setUp(uiDelegate: uiMock)
    }

    override func tearDownWithError() throws {
        sut = nil
        uiMock = nil
    }

    func testLocalizationWontCrash() throws {
        sut.prepareData()
        XCTAssertEqual(uiMock.updateTimes, 1)
        XCTAssertGreaterThan(sut.keys.count, 0)
    }
}
