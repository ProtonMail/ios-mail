// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail

class ConversationStoredSizeHelperTests: XCTestCase {

    var sut: ConversationStoredSizeHelper!
    let messageID = "message"
    let testHeightInfo = HeightStoreInfo(height: 100.0, isHeaderExpanded: false, loaded: true)
    override func setUp() {
        super.setUp()
        sut = ConversationStoredSizeHelper()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testGetStoredSize() {
        sut.storedSize[messageID] = testHeightInfo

        XCTAssertEqual(testHeightInfo, sut.getStoredSize(of: messageID))
    }

    func testResetStoredSize() {
        sut.storedSize[messageID] = testHeightInfo
        XCTAssertNotNil(sut.getStoredSize(of: messageID))

        sut.resetStoredSize(of: messageID)
        XCTAssertNil(sut.getStoredSize(of: messageID))
    }

    func testUpdateStoredSizeIfNeeded_sameHeight_returnFalse() {
        sut.storedSize[messageID] = testHeightInfo
        XCTAssertFalse(sut.updateStoredSizeIfNeeded(newHeightInfo: testHeightInfo, messageID: messageID))
    }

    func testUpdateStoredSizeIfNeeded_nilHeight_returnTrue() {
        XCTAssertTrue(sut.updateStoredSizeIfNeeded(newHeightInfo: testHeightInfo, messageID: messageID))
    }

    func testUpdateStoredSizeIfNeeded_differentHeight_returnTrue() {
        sut.storedSize[messageID] = testHeightInfo
        let newHeight = HeightStoreInfo(height: 500, isHeaderExpanded: false, loaded: true)
        XCTAssertTrue(sut.updateStoredSizeIfNeeded(newHeightInfo: newHeight, messageID: messageID))
    }

    func testUpdateStoredSizeIfNeeded_differentState_returnTrue() {
        sut.storedSize[messageID] = testHeightInfo
        let newHeight = HeightStoreInfo(height: 100, isHeaderExpanded: true, loaded: true)
        XCTAssertTrue(sut.updateStoredSizeIfNeeded(newHeightInfo: newHeight, messageID: messageID))
    }
}
