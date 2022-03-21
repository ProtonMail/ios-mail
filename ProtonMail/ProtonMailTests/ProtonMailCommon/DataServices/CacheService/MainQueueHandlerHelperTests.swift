// Copyright (c) 2022 Proton Technologies AG
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

class MainQueueHandlerHelperTests: XCTestCase {

    var contextProviderMock: MockCoreDataContextProvider!
    override func setUp() {
        super.setUp()
        contextProviderMock = MockCoreDataContextProvider()
    }

    override func tearDown() {
        super.tearDown()
        contextProviderMock = nil
    }

    func testRemoveAllAttachmentsNotUploaded_withOneAttNotUploaded_allAttsAreRemovedFromMsg() throws {
        // Prepare test data
        let testAtt = Attachment(context: contextProviderMock.rootSavingContext)
        testAtt.attachmentID = ""
        let testMsg = Message(context: contextProviderMock.rootSavingContext)
        testAtt.message = testMsg
        testMsg.numAttachments = NSNumber.init(value: 1)
        try contextProviderMock.rootSavingContext.save()

        let sut = MainQueueHandlerHelper.removeAllAttachmentsNotUploaded
        sut(testMsg, contextProviderMock.rootSavingContext)

        XCTAssertEqual(testMsg.numAttachments.intValue, 0)
        XCTAssertEqual(testMsg.attachments.count, 0)
    }

    func testRemoveAllAttachmentsNotUploaded_withNoAtt_noAttExist() throws {
        // Prepare test data
        let testMsg = Message(context: contextProviderMock.rootSavingContext)
        testMsg.numAttachments = NSNumber(value: 0)
        try contextProviderMock.rootSavingContext.save()

        let sut = MainQueueHandlerHelper.removeAllAttachmentsNotUploaded
        sut(testMsg, contextProviderMock.rootSavingContext)

        XCTAssertEqual(testMsg.numAttachments.intValue, 0)
        XCTAssertEqual(testMsg.attachments.count, 0)
    }

    func testRemoveAllAttachmentsNotUploaded_withOneAttUploaded_noAttExist() throws {
        // Prepare test data
        let testAtt = Attachment(context: contextProviderMock.rootSavingContext)
        testAtt.attachmentID = UUID().uuidString
        let testMsg = Message(context: contextProviderMock.rootSavingContext)
        testAtt.message = testMsg
        testMsg.numAttachments = NSNumber(value: 1)
        try contextProviderMock.rootSavingContext.save()

        let sut = MainQueueHandlerHelper.removeAllAttachmentsNotUploaded
        sut(testMsg, contextProviderMock.rootSavingContext)

        XCTAssertEqual(testMsg.numAttachments.intValue, 1)
        XCTAssertEqual(testMsg.attachments.count, 1)
    }
}
