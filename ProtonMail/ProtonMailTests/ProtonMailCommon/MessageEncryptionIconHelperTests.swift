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

import Groot
import XCTest
@testable import ProtonMail

class MessageEncryptionIconHelperTests: XCTestCase {

    var mockCoreDataContextProvider: MockCoreDataContextProvider!
    var testMsg: MessageEntity!

    override func setUp() {
        super.setUp()
        mockCoreDataContextProvider = MockCoreDataContextProvider()
    }

    override func tearDown() {
        super.tearDown()
        mockCoreDataContextProvider = nil
    }

    func testGetAuthenticationMap() {
        loadTestMessageData(type: .nonPMSigned)
        let sut = MessageEncryptionIconHelper()

        let result = sut.getAuthenticationMap(headerValue: testMsg.parsedHeaders)
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result.count, 1)
    }

    func testGetEncryptionMap() {
        loadTestMessageData(type: .nonPMSigned)
        let sut = MessageEncryptionIconHelper()

        let result = sut.getEncryptionMap(headerValue: testMsg.parsedHeaders)
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result.count, 1)
    }

    func testGetOrigin() throws {
        loadTestMessageData(type: .nonPMSigned)
        let sut = MessageEncryptionIconHelper()

        let result = try XCTUnwrap(sut.getOrigin(headerValue: testMsg.parsedHeaders))
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result, "internal")
    }

    func testGetContentEncryption() {
        loadTestMessageData(type: .nonPMSigned)
        let sut = MessageEncryptionIconHelper()

        let result = sut.getContentEncryption(headerValue: testMsg.parsedHeaders)
        XCTAssertEqual(result, .onCompose)
    }

    func testGetSentStatusIcon_forMsgSentToNonPMSignedAddress() {
        loadTestMessageData(type: .nonPMSigned)
        let sut = MessageEncryptionIconHelper()
        let expectation1 = expectation(description: "Closure is called")

        sut.sentStatusIconInfo(message: testMsg) { lock, lockType in
            XCTAssertEqual(lock, PGPType.zero_access_store.lockImage)
            XCTAssertEqual(lockType, PGPType.zero_access_store.rawValue)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetSentStatusIcon_forMsgSentToPMAddress() {
        loadTestMessageData(type: .PM)
        let sut = MessageEncryptionIconHelper()
        let expectation1 = expectation(description: "Closure is called")

        sut.sentStatusIconInfo(message: testMsg) { lock, lockType in
            XCTAssertEqual(lock, PGPType.sent_sender_encrypted.lockImage)
            XCTAssertEqual(lockType, PGPType.sent_sender_encrypted.rawValue)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetSentStatusIcon_forMsgSentToNonPMEncSignedAddress() {
        loadTestMessageData(type: .nonPMEncSigned)
        let sut = MessageEncryptionIconHelper()
        let expectation1 = expectation(description: "Closure is called")

        sut.sentStatusIconInfo(message: testMsg) { lock, lockType in
            XCTAssertEqual(lock, PGPType.sent_sender_encrypted.lockImage)
            XCTAssertEqual(lockType, PGPType.sent_sender_encrypted.rawValue)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetSentStatusIcon_forMsgbyEO() {
        loadTestMessageData(type: .eo)
        let sut = MessageEncryptionIconHelper()
        let expectation1 = expectation(description: "Closure is called")

        sut.sentStatusIconInfo(message: testMsg) { lock, lockType in
            XCTAssertEqual(lock, PGPType.sent_sender_encrypted.lockImage)
            XCTAssertEqual(lockType, PGPType.sent_sender_encrypted.rawValue)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetSentStatusIcon_forMsgSentToNonPMAddress() {
        loadTestMessageData(type: .nonPM)
        let sut = MessageEncryptionIconHelper()
        let expectation1 = expectation(description: "Closure is called")

        sut.sentStatusIconInfo(message: testMsg) { lock, lockType in
            XCTAssertEqual(lock, PGPType.zero_access_store.lockImage)
            XCTAssertEqual(lockType, PGPType.zero_access_store.rawValue)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetSentStatusIcon_forMsgSentToPMPinnedAddress() {
        loadTestMessageData(type: .pmPinned)
        let sut = MessageEncryptionIconHelper()
        let expectation1 = expectation(description: "Closure is called")

        sut.sentStatusIconInfo(message: testMsg) { lock, lockType in
            XCTAssertEqual(lock, PGPType.sent_sender_encrypted.lockImage)
            XCTAssertEqual(lockType, PGPType.sent_sender_encrypted.rawValue)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    private func loadTestMessageData(type: PGPTypeTestData) {
        let testData = type.rawValue.parseObjectAny()!
        guard let testMsg = try? GRTJSONSerialization.object(withEntityName: "Message", fromJSONDictionary: testData, in: self.mockCoreDataContextProvider.mainContext) as? Message else {
            XCTFail("The fake data initialize failed")
            return
        }
        self.testMsg = MessageEntity(testMsg)
        _ = self.mockCoreDataContextProvider.mainContext.saveUpstreamIfNeeded()
    }
}
