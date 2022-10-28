// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import CoreData
import XCTest

@testable import ProtonMail

class MainQueueHandlerHelperTests: XCTestCase {
    private var testContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()

        let contextProviderMock = MockCoreDataContextProvider()
        testContext = contextProviderMock.viewContext
    }

    override func tearDown() {
        super.tearDown()

        testContext = nil
    }

    func testRemoveAllAttachmentsNotUploaded_withOneAttNotUploaded_allAttsAreRemovedFromMsg() throws {
        // Prepare test data
        let testAtt = Attachment(context: testContext)
        testAtt.attachmentID = ""
        let testMsg = Message(context: testContext)
        testAtt.message = testMsg
        testMsg.numAttachments = NSNumber.init(value: 1)
        try testContext.save()

        let sut = MainQueueHandlerHelper.removeAllAttachmentsNotUploaded
        sut(testMsg, testContext)

        XCTAssertEqual(testMsg.numAttachments.intValue, 0)
        XCTAssertEqual(testMsg.attachments.count, 0)
    }

    func testRemoveAllAttachmentsNotUploaded_withNoAtt_noAttExist() throws {
        // Prepare test data
        let testMsg = Message(context: testContext)
        testMsg.numAttachments = NSNumber(value: 0)
        try testContext.save()

        let sut = MainQueueHandlerHelper.removeAllAttachmentsNotUploaded
        sut(testMsg, testContext)

        XCTAssertEqual(testMsg.numAttachments.intValue, 0)
        XCTAssertEqual(testMsg.attachments.count, 0)
    }

    func testRemoveAllAttachmentsNotUploaded_withOneAttUploaded_noAttExist() throws {
        // Prepare test data
        let testAtt = Attachment(context: testContext)
        testAtt.attachmentID = UUID().uuidString
        let testMsg = Message(context: testContext)
        testAtt.message = testMsg
        testMsg.numAttachments = NSNumber(value: 1)
        try testContext.save()

        let sut = MainQueueHandlerHelper.removeAllAttachmentsNotUploaded
        sut(testMsg, testContext)

        XCTAssertEqual(testMsg.numAttachments.intValue, 1)
        XCTAssertEqual(testMsg.attachments.count, 1)
    }
}
