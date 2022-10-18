// Copyright (c) 2022 Proton AG
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

        let iconStatus = sut.sentStatusIconInfo(message: testMsg)
        XCTAssertEqual(iconStatus?.iconColor, .black)
        XCTAssertEqual(iconStatus?.text, LocalString._zero_access_of_msg)
    }

    func testGetSentStatusIcon_forMsgSentToPMAddress() {
        loadTestMessageData(type: .PM)
        let sut = MessageEncryptionIconHelper()

        let iconStatus = sut.sentStatusIconInfo(message: testMsg)
        XCTAssertEqual(iconStatus?.iconColor, .blue)
        XCTAssertEqual(iconStatus?.text, LocalString._end_to_end_encryption_of_sent)
    }

    func testGetSentStatusIcon_forMsgSentToNonPMEncSignedAddress() {
        loadTestMessageData(type: .nonPMEncSigned)
        let sut = MessageEncryptionIconHelper()

        let iconStatus = sut.sentStatusIconInfo(message: testMsg)
        XCTAssertEqual(iconStatus?.iconColor, .green)
        XCTAssertEqual(iconStatus?.text, LocalString._end_to_end_encryption_of_sent)
    }

    func testGetSentStatusIcon_forMsgbyEO() {
        loadTestMessageData(type: .eo)
        let sut = MessageEncryptionIconHelper()

        let iconStatus = sut.sentStatusIconInfo(message: testMsg)
        XCTAssertEqual(iconStatus?.iconColor, .blue)
        XCTAssertEqual(iconStatus?.text, LocalString._end_to_end_encryption_of_sent)
    }

    func testGetSentStatusIcon_forMsgSentToNonPMAddress() {
        loadTestMessageData(type: .nonPM)
        let sut = MessageEncryptionIconHelper()

        let iconStatus = sut.sentStatusIconInfo(message: testMsg)
        XCTAssertEqual(iconStatus?.iconColor, .black)
        XCTAssertEqual(iconStatus?.text, LocalString._zero_access_of_msg)
    }

    func testGetSentStatusIcon_forMsgSentToPMPinnedAddress() {
        loadTestMessageData(type: .pmPinned)
        let sut = MessageEncryptionIconHelper()

        let iconStatus = sut.sentStatusIconInfo(message: testMsg)
        XCTAssertEqual(iconStatus?.iconColor, .blue)
        XCTAssertEqual(iconStatus?.text, LocalString._end_to_send_verified_recipient_of_sent)
    }

    func testGetSentStatusIcon_forMsgSentToPinnedNonEndToEndAddress() {
        loadTestMessageData(type: .pinned)
        let sut = MessageEncryptionIconHelper()

        let iconStatus = sut.sentStatusIconInfo(message: testMsg)
        XCTAssertEqual(iconStatus?.iconColor, .blue)
        XCTAssertEqual(iconStatus?.text, LocalString._zero_access_verified_recipient_of_sent)
    }

    private func loadTestMessageData(type: PGPTypeTestData) {
        let testData = type.rawValue.parseObjectAny()!
        self.testMsg = mockCoreDataContextProvider.enqueue { context in
            guard let testMsg = try? GRTJSONSerialization.object(withEntityName: "Message", fromJSONDictionary: testData, in: context) as? Message else {
                XCTFail("The fake data initialize failed")
                return nil
            }
            return MessageEntity(testMsg)
        }
    }
}
