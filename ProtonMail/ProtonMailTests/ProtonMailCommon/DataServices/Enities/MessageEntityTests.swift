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

import CoreData
import XCTest
@testable import ProtonMail

final class MessageEntityTests: XCTestCase {

    var coreDataService: CoreDataService!
    var testContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        coreDataService = CoreDataService(container: CoreDataStore.shared.memoryPersistentContainer)
        testContext = coreDataService.rootSavingContext
    }

    override func tearDownWithError() throws {
        coreDataService = nil
        testContext = nil
    }

    func testInitialization() {
        let message = Message(context: testContext)
        let messageID = UUID().uuidString
        message.messageID = messageID
        message.action = NSNumber(value: 2)
        message.addressID = "addressID-0123"
        message.body = "body-0987"
        message.conversationID = "conversationID-0123"
        message.expirationTime = .distantPast
        message.header = "header-0987"
        message.numAttachments = NSNumber(value: 3)
        message.sender = """
        { "Address": "sender@protonmail.com", "Name": "test00"}
        """
        message.size = 300
        message.spamScore = 101
        message.time = .distantFuture
        message.title = "title-0123"
        message.unRead = true
        message.userID = "userID-0987"
        message.order = NSNumber(value: 100)
        message.nextAddressID = "nextAddressID-0123"
        message.expirationOffset = 50
        message.isSoftDeleted = true
        message.isDetailDownloaded = true
        message.isSending = true
        message.messageStatus = NSNumber(value: 1)
        message.lastModified = Date(timeIntervalSince1970: 1645686077)
        message.orginalMessageID = "originalID-0987"
        message.orginalTime = Date(timeIntervalSince1970: 645686077)
        message.passwordEncryptedBody = "encrypted-0123"
        message.password = "password-0987"
        message.passwordHint = "hint-0123"

        let entity = MessageEntity(message)
        XCTAssertEqual(entity.messageID, MessageID(messageID))
        XCTAssertEqual(entity.action, .forward)
        XCTAssertEqual(entity.addressID, AddressID("addressID-0123"))
        XCTAssertEqual(entity.body, "body-0987")
        XCTAssertEqual(entity.conversationID, ConversationID("conversationID-0123"))
        XCTAssertEqual(entity.expirationTime, .distantPast)
        XCTAssertEqual(entity.numAttachments, 3)
        XCTAssertEqual(entity.sender?.email, "sender@protonmail.com")
        XCTAssertEqual(entity.sender?.name, "test00")
        XCTAssertEqual(entity.size, 300)
        XCTAssertEqual(entity.spamScore, .dmarcFail)
        XCTAssertEqual(entity.time, .distantFuture)
        XCTAssertEqual(entity.title, "title-0123")
        XCTAssertTrue(entity.unRead)
        XCTAssertEqual(entity.userID, UserID("userID-0987"))
        XCTAssertEqual(entity.order, 100)
        XCTAssertEqual(entity.nextAddressID, AddressID("nextAddressID-0123"))
        XCTAssertEqual(entity.expirationOffset, 50)
        XCTAssertTrue(entity.isSoftDeleted)
        XCTAssertTrue(entity.isDetailDownloaded)
        XCTAssertTrue(entity.isSending)
        XCTAssertTrue(entity.hasMetaData)
        XCTAssertEqual(entity.lastModified, Date(timeIntervalSince1970: 1645686077))
        XCTAssertEqual(entity.originalMessageID, MessageID("originalID-0987"))
        XCTAssertEqual(entity.originalTime, Date(timeIntervalSince1970: 645686077))
        XCTAssertEqual(entity.passwordEncryptedBody, "encrypted-0123")
        XCTAssertEqual(entity.password, "password-0987")
        XCTAssertEqual(entity.passwordHint, "hint-0123")
    }

    func testContactsConvert() throws {
        let message = Message(context: testContext)
        message.messageID = UUID().uuidString
        message.ccList = """
        [
                {
                  "Name": "test01",
                  "Address": "test01@protonmail.com",
                  "Group": ""
                },
                {
                  "Name": "test02",
                  "Address": "test02@protonmail.com",
                  "Group": ""
                }
              ]
        """
        var entity = MessageEntity(message)
        XCTAssertEqual(entity.ccList.count, 2)
        for (idx, item) in entity.ccList.enumerated() {
            guard let contact = item as? ContactVO else {
                XCTFail("Should be ContactVO")
                continue
            }
            if idx == 0 {
                contact.name = "test01"
                contact.email = "test01@protonmail.com"
            } else {
                contact.name = "test02"
                contact.email = "test02@protonmail.com"
            }
        }

        message.ccList = """
        [
                {
                  "Name": "test01",
                  "Address": "test01@protonmail.com",
                  "Group": "testGroup"
                },
                {
                  "Name": "test02",
                  "Address": "test02@protonmail.com",
                  "Group": "testGroup"
                }
              ]
        """
        entity = MessageEntity(message)
        XCTAssertEqual(entity.ccList.count, 1)
        let contact = try XCTUnwrap(entity.ccList.first as? ContactGroupVO)
        XCTAssertEqual(contact.contactTitle, "testGroup")
        let mails = contact.getSelectedEmailData()
        XCTAssertEqual(mails.count, 2)
        for data in mails {
            if data.name == "test01" {
                XCTAssertEqual(data.email, "test01@protonmail.com")
            } else {
                XCTAssertEqual(data.name, "test02")
                XCTAssertEqual(data.email, "test02@protonmail.com")
            }
        }
    }

    func testParseUnsubscribeMethods() throws {
        let message = Message(context: testContext)
        message.unsubscribeMethods = """
        {
            "OneClick": "one click method",
            "HttpClient": "http client method",
            "Mailto": {
                "ToList": ["a", "b", "c"],
                "Subject": "This is a subject",
                "Body": "This is a body"
            }
        }
        """
        var entity = MessageEntity(message)
        let method = try XCTUnwrap(entity.unsubscribeMethods)
        XCTAssertEqual(method.oneClick, "one click method")
        XCTAssertEqual(method.httpClient, "http client method")
        XCTAssertEqual(method.mailTo?.toList, ["a", "b", "c"])
        XCTAssertEqual(method.mailTo?.subject, "This is a subject")
        XCTAssertEqual(method.mailTo?.body, "This is a body")

        message.unsubscribeMethods = "jfelkdfl"
        entity = MessageEntity(message)
        XCTAssertNil(entity.unsubscribeMethods)

        message.unsubscribeMethods = nil
        entity = MessageEntity(message)
        XCTAssertNil(entity.unsubscribeMethods)
    }

    func testParsedHeader() throws {
        let message = Message(context: testContext)
        message.parsedHeaders = """
        {
            "Return-Path": "<793-XLJ>",
            "X-Original-To": "test01@protonmail.com",
            "Delivered-To": "test01@protonmail.com",
            "Authentication-Results": [
              "mailin010.protonmail.ch; dkim=pass",
              "mailin010.protonmail.ch; dmarc=none",
              "mailin010.protonmail.ch; spf=pass",
              "mailin010.protonmail.ch; arc=none",
              "mailin010.protonmail.ch; dkim=pass"
            ],
            "number": 3
        }
        """
        let entity = MessageEntity(message)
        let dict = entity.parsedHeaders
        XCTAssertEqual(dict.keys.count, 5)
        XCTAssertEqual(dict["Return-Path"] as? String, "<793-XLJ>")
        XCTAssertEqual(dict["X-Original-To"] as? String, "test01@protonmail.com")
        XCTAssertEqual(dict["Delivered-To"] as? String, "test01@protonmail.com")
        XCTAssertEqual(dict["number"] as? Int, 3)
        let authResults: [String] = try XCTUnwrap(dict["Authentication-Results"] as? [String])
        XCTAssertEqual(authResults.count, 5)
        XCTAssertEqual(authResults[2], "mailin010.protonmail.ch; spf=pass")
        XCTAssertEqual(authResults[4], "mailin010.protonmail.ch; dkim=pass")
    }
}

// MARK: extend variables tests
extension MessageEntityTests {
    func testIsInternal() {
        let message = Message(context: testContext)
        message.messageID = UUID().uuidString
        message.flags = NSNumber(value: 1157)
        var entity = MessageEntity(message)
        XCTAssertTrue(entity.isInternal)

        message.flags = NSNumber(value: 255)
        entity = MessageEntity(message)
        XCTAssertTrue(entity.isInternal)

        message.flags = NSNumber(value: 254)
        entity = MessageEntity(message)
        XCTAssertFalse(entity.isInternal)

        message.flags = NSNumber(value: 251)
        entity = MessageEntity(message)
        XCTAssertFalse(entity.isInternal)

        message.flags = NSNumber(value: 251)
        entity = MessageEntity(message)
        XCTAssertFalse(entity.isInternal)
    }

    func testIsExternal() {
        let message = Message(context: testContext)
        message.messageID = UUID().uuidString
        message.flags = NSNumber(value: 1)
        var entity = MessageEntity(message)
        XCTAssertTrue(entity.isExternal)

        message.flags = NSNumber(value: 16897)
        entity = MessageEntity(message)
        XCTAssertTrue(entity.isExternal)

        message.flags = NSNumber(value: 133)
        entity = MessageEntity(message)
        XCTAssertFalse(entity.isExternal)

        message.flags = NSNumber(value: 8325)
        entity = MessageEntity(message)
        XCTAssertFalse(entity.isExternal)

        message.flags = NSNumber(value: 0)
        entity = MessageEntity(message)
        XCTAssertFalse(entity.isExternal)
    }

    func testIsE2E() {
        let message = Message(context: testContext)
        message.messageID = UUID().uuidString
        message.flags = NSNumber(value: 8)
        var entity = MessageEntity(message)
        XCTAssertTrue(entity.isE2E)

        message.flags = NSNumber(value: 38408)
        entity = MessageEntity(message)
        XCTAssertTrue(entity.isE2E)

        message.flags = NSNumber(value: 38400)
        entity = MessageEntity(message)
        XCTAssertFalse(entity.isE2E)

        message.flags = NSNumber(value: 0)
        entity = MessageEntity(message)
        XCTAssertFalse(entity.isE2E)
    }

    func testIsPGPMime() {
        let message = Message(context: testContext)
        message.messageID = UUID().uuidString
        message.mimeType = "multipart/mixed"
        message.flags = NSNumber(value: 9289)
        var entity = MessageEntity(message)
        XCTAssertTrue(entity.isPGPMime)
        XCTAssertEqual(message.isPgpMime, entity.isPGPMime)

        message.flags = NSNumber(value: 9)
        entity = MessageEntity(message)
        XCTAssertTrue(entity.isPGPMime)
        XCTAssertEqual(message.isPgpMime, entity.isPGPMime)

        message.flags = NSNumber(value: 8)
        entity = MessageEntity(message)
        XCTAssertFalse(entity.isPGPMime)
        XCTAssertEqual(message.isPgpMime, entity.isPGPMime)

        message.flags = NSNumber(value: 1)
        entity = MessageEntity(message)
        XCTAssertFalse(entity.isPGPMime)
        XCTAssertEqual(message.isPgpMime, entity.isPGPMime)

        message.flags = NSNumber(value: 0)
        entity = MessageEntity(message)
        XCTAssertFalse(entity.isPGPMime)
        XCTAssertEqual(message.isPgpMime, entity.isPGPMime)

        message.flags = NSNumber(value: 9)
        message.mimeType = "text/html"
        entity = MessageEntity(message)
        XCTAssertFalse(entity.isPGPMime)
        XCTAssertEqual(message.isPgpMime, entity.isPGPMime)
    }

    func testISPGPInline() {
        let message = Message(context: testContext)
        message.messageID = UUID().uuidString
        message.mimeType = "text/html"
        message.flags = NSNumber(value: 9289)
        var entity = MessageEntity(message)
        XCTAssertTrue(entity.isPGPInline)
        XCTAssertEqual(message.isPgpInline, entity.isPGPInline)

        message.flags = NSNumber(value: 9)
        entity = MessageEntity(message)
        XCTAssertTrue(entity.isPGPInline)
        XCTAssertEqual(message.isPgpInline, entity.isPGPInline)

        message.mimeType = "multipart/mixed"
        message.flags = NSNumber(value: 13)
        entity = MessageEntity(message)
        XCTAssertTrue(entity.isPGPInline)
        XCTAssertEqual(message.isPgpInline, entity.isPGPInline)

        message.flags = NSNumber(value: 9)
        entity = MessageEntity(message)
        XCTAssertFalse(entity.isPGPInline)
        XCTAssertEqual(message.isPgpInline, entity.isPGPInline)

        message.flags = NSNumber(value: 12)
        entity = MessageEntity(message)
        XCTAssertTrue(entity.isPGPInline)
        XCTAssertEqual(message.isPgpInline, entity.isPGPInline)
    }

    func testIsSignedMime() {
        let message = Message(context: testContext)
        message.messageID = UUID().uuidString
        message.mimeType = "multipart/mixed"
        message.flags = NSNumber(value: 3)
        var entity = MessageEntity(message)
        XCTAssertTrue(entity.isSignedMime)

        message.flags = NSNumber(value: 129)
        entity = MessageEntity(message)
        XCTAssertTrue(entity.isSignedMime)

        message.flags = NSNumber(value: 9)
        entity = MessageEntity(message)
        XCTAssertFalse(entity.isSignedMime)

        message.mimeType = "text/html"
        message.flags = NSNumber(value: 9)
        entity = MessageEntity(message)
        XCTAssertFalse(entity.isSignedMime)
    }

    func testIsPlainText() {
        let message = Message(context: testContext)
        message.messageID = UUID().uuidString
        message.mimeType = "text/plain"
        var entity = MessageEntity(message)
        XCTAssertTrue(entity.isPlainText)
        XCTAssertEqual(message.isPlainText, entity.isPlainText)

        message.mimeType = "TEXT/PLAIN"
        entity = MessageEntity(message)
        XCTAssertTrue(entity.isPlainText)
        XCTAssertEqual(message.isPlainText, entity.isPlainText)

        message.mimeType = "aifjld"
        entity = MessageEntity(message)
        XCTAssertFalse(entity.isPlainText)
        XCTAssertEqual(message.isPlainText, entity.isPlainText)
    }

    func testIsMultipartMixed() {
        let message = Message(context: testContext)
        message.messageID = UUID().uuidString
        message.mimeType = "multipart/mixed"
        var entity = MessageEntity(message)
        XCTAssertTrue(entity.isMultipartMixed)
        XCTAssertEqual(message.isMultipartMixed, entity.isMultipartMixed)

        message.mimeType = "MULTIPART/MIXED"
        entity = MessageEntity(message)
        XCTAssertTrue(entity.isMultipartMixed)
        XCTAssertEqual(message.isMultipartMixed, entity.isMultipartMixed)

        message.mimeType = "aifjld"
        entity = MessageEntity(message)
        XCTAssertFalse(entity.isMultipartMixed)
        XCTAssertEqual(message.isMultipartMixed, entity.isMultipartMixed)
    }
}
