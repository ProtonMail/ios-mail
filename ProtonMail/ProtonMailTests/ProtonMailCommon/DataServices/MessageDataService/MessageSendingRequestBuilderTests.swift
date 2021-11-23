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

class MessageSendingRequestBuilderTests: XCTestCase {

    var sut: MessageSendingRequestBuilder!

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testCalculateSendType_internal() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertEqual(sut.calculateSendType(recipientType: 1,
                                             isEO: false,
                                             hasPGPKey: false,
                                             hasPGPEncryption: false,
                                             isMIME: false),
                       .intl)

        XCTAssertEqual(sut.calculateSendType(recipientType: 1,
                                             isEO: false,
                                             hasPGPKey: true,
                                             hasPGPEncryption: true,
                                             isMIME: false),
                       .intl)

        XCTAssertEqual(sut.calculateSendType(recipientType: 1,
                                             isEO: true,
                                             hasPGPKey: false,
                                             hasPGPEncryption: false,
                                             isMIME: false),
                       .intl)
    }

    func testCalculateSendType_eo() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertEqual(sut.calculateSendType(recipientType: 2,
                                             isEO: true,
                                             hasPGPKey: false,
                                             hasPGPEncryption: false,
                                             isMIME: false),
                       .eo)

        XCTAssertEqual(sut.calculateSendType(recipientType: 2,
                                             isEO: true,
                                             hasPGPKey: true,
                                             hasPGPEncryption: true,
                                             isMIME: false),
                       .eo)

    }

    func testCalculateSendType_withExpirationOffsetSet_eo() {
        sut = MessageSendingRequestBuilder(expirationOffset: 100)
        XCTAssertEqual(sut.calculateSendType(recipientType: 2,
                                             isEO: true,
                                             hasPGPKey: true,
                                             hasPGPEncryption: true,
                                             isMIME: true),
                       .eo)
    }

    func testCalculateSendType_pgpMIME() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertEqual(sut.calculateSendType(recipientType: 2,
                                             isEO: false,
                                             hasPGPKey: true,
                                             hasPGPEncryption: true,
                                             isMIME: true),
                       .pgpmime)
    }

    func testCalculateSendType_clearMIME() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertEqual(sut.calculateSendType(recipientType: 2,
                                             isEO: false,
                                             hasPGPKey: false,
                                             hasPGPEncryption: false,
                                             isMIME: true),
                       .cmime)
    }

    func testCalculateSendType_pgpInline() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertEqual(sut.calculateSendType(recipientType: 2,
                                             isEO: false,
                                             hasPGPKey: true,
                                             hasPGPEncryption: true,
                                             isMIME: false),
                       .inlnpgp)
    }

    func testCalculateSendType_clearInline() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertEqual(sut.calculateSendType(recipientType: 2,
                                             isEO: false,
                                             hasPGPKey: false,
                                             hasPGPEncryption: false,
                                             isMIME: false),
                       .cinln)
    }

    func testInit() {
        sut = MessageSendingRequestBuilder(expirationOffset: Int32(100))
        XCTAssertEqual(sut.expirationOffset, Int32(100))

        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertEqual(sut.expirationOffset, Int32(0))
    }

    func testUpdateBodyData_bodySessionAndBodyAlgorithm() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        let testData = "Body".data(using: .utf8)!
        let testSession = "Key".data(using: .utf8)!
        let testAlgo = "algo"
        sut.update(bodyData: testData,
                   bodySession: testSession,
                   algo: testAlgo)
        XCTAssertEqual(sut.bodyDataPacket, testData)
        XCTAssertEqual(sut.bodySession, testSession)
        XCTAssertEqual(sut.bodySessionAlgo, testAlgo)
    }

    func testSetPasswordAndHint() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        let testPassword = "pwd"
        let testHint = "hint"
        sut.set(password: testPassword, hint: testHint)
        XCTAssertEqual(sut.password, testPassword)
        XCTAssertEqual(sut.hint, testHint)
    }

    func testSetClearBody() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        let testClearBody = "body"
        sut.set(clearBody: testClearBody)
        XCTAssertEqual(sut.clearBody, testClearBody)
    }

    func testAddAddress() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertTrue(sut.preAddresses.isEmpty)
        let testAddress = PreAddress(email: "test@test.test",
                                     pubKey: nil,
                                     pgpKey: nil,
                                     recipintType: 1,
                                     isEO: false,
                                     mime: false,
                                     sign: false,
                                     pgpencrypt: false,
                                     plainText: true)
        sut.add(address: testAddress)
        XCTAssertEqual(sut.preAddresses.count, 1)
        XCTAssertEqual(sut.preAddresses[0], testAddress)
    }

    func testAddAttachment() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertTrue(sut.preAttachments.isEmpty)
        let testAttachment = Attachment()
        let testPreAttachment = PreAttachment(id: "id",
                                              session: "key".data(using: .utf8)!,
                                              algo: "algo",
                                              att: testAttachment)
        sut.add(attachment: testPreAttachment)
        XCTAssertEqual(sut.preAttachments.count, 1)
        XCTAssertEqual(sut.preAttachments[0].attachmentId, "id")
    }

    func testContains() {
        sut = MessageSendingRequestBuilder(expirationOffset: nil)
        XCTAssertTrue(sut.preAddresses.isEmpty)
        XCTAssertFalse(sut.contains(type: .pgpmime))

        let pgpMIMEAddress = PreAddress(email: "test@test.com",
                                        pubKey: "key",
                                        pgpKey: "key".data(using: .utf8),
                                        recipintType: 2,
                                        isEO: false,
                                        mime: true,
                                        sign: true,
                                        pgpencrypt: true,
                                        plainText: false)
        sut.add(address: pgpMIMEAddress)
        XCTAssertTrue(sut.contains(type: .pgpmime))
    }
}
