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

import CoreData
import XCTest
@testable import ProtonMail

final class MessageEntityTests: XCTestCase {

    var coreDataService: CoreDataService!
    var testContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        coreDataService = CoreDataService(container: MockCoreDataStore.testPersistentContainer)
        testContext = coreDataService.mainContext
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
        {"Address":"sender@protonmail.com","Name":"test00"}
        """
        message.toList = """
        [{"Address":"to1@protonmail.com","Name":"testTO01"},{"Address":"to2@protonmail.com","Name":"testTO02"}]
        """
        message.ccList = """
        [{"Address":"cc1@protonmail.com","Name":"testCC01"},{"Address":"cc2@protonmail.com","Name":"testCC02"}]
        """
        message.bccList = """
        [{"Address":"bcc1@protonmail.com","Name":"testBCC01"},{"Address":"bcc2@protonmail.com","Name":"testBCC02"}]
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
        message.messageStatus = NSNumber(value: 1)
        message.lastModified = Date(timeIntervalSince1970: 1645686077)
        message.orginalMessageID = "originalID-0987"
        message.orginalTime = Date(timeIntervalSince1970: 645686077)
        message.passwordEncryptedBody = "encrypted-0123"
        message.password = "password-0987"
        message.passwordHint = "hint-0123"

        let entity = MessageEntity(message)
        XCTAssertEqual(entity.messageID, MessageID(messageID))
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
        XCTAssertTrue(entity.hasMetaData)
        XCTAssertEqual(entity.lastModified, Date(timeIntervalSince1970: 1645686077))
        XCTAssertEqual(entity.originalMessageID, MessageID("originalID-0987"))
        XCTAssertEqual(entity.originalTime, Date(timeIntervalSince1970: 645686077))
        XCTAssertEqual(entity.passwordEncryptedBody, "encrypted-0123")
        XCTAssertEqual(entity.password, "password-0987")
        XCTAssertEqual(entity.passwordHint, "hint-0123")
        XCTAssertEqual(entity.rawTOList, message.toList)
        XCTAssertEqual(entity.rawCCList, message.ccList)
        XCTAssertEqual(entity.rawBCCList, message.bccList)
        XCTAssertEqual(entity.recipientsTo, ["to1@protonmail.com", "to2@protonmail.com"])
        XCTAssertEqual(entity.recipientsCc, ["cc1@protonmail.com", "cc2@protonmail.com"])
        XCTAssertEqual(entity.recipientsBcc, ["bcc1@protonmail.com", "bcc2@protonmail.com"])
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
        XCTAssertEqual(entity.recipientsCc.count, 2)

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
        XCTAssertEqual(entity.recipientsCc.count, 2)

        let ccList = ContactPickerModelHelper.contacts(from: entity.rawCCList)
        XCTAssertEqual(ccList.count, 1)
        let contact = try XCTUnwrap(ccList.first as? ContactGroupVO)
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

        message.mimeType = "MULTIPART/MIXED"
        entity = MessageEntity(message)
        XCTAssertTrue(entity.isMultipartMixed)

        message.mimeType = "aifjld"
        entity = MessageEntity(message)
        XCTAssertFalse(entity.isMultipartMixed)
    }

    func testMessageLocation() {
        let message = Message(context: testContext)
        message.messageID = UUID().uuidString
        let label1 = Label(context: testContext)
        label1.labelID = "1"
        let label2 = Label(context: testContext)
        label2.labelID = "2"
        let label3 = Label(context: testContext)
        label3.labelID = "sdjfisjfjdsofj"

        var sut = MessageEntity(message)
        sut.setLabels([
            LabelEntity(label: label2),
            LabelEntity(label: label3),
            LabelEntity(label: label1)
        ])

        XCTAssertEqual(sut.messageLocation?.labelID.rawValue, label3.labelID)
    }

    func testOrderedLocation() {
        let message = Message(context: testContext)
        message.messageID = UUID().uuidString
        let label1 = Label(context: testContext)
        label1.labelID = "1"
        let label2 = Label(context: testContext)
        label2.labelID = "2"
        let label3 = Label(context: testContext)
        label3.labelID = "sdjfisjfjdsofj"
        let label4 = Label(context: testContext)
        label4.labelID = "5"
        let label5 = Label(context: testContext)
        label5.labelID = "10"

        var sut = MessageEntity(message)
        sut.setLabels([
            LabelEntity(label: label4),
            LabelEntity(label: label5),
            LabelEntity(label: label2),
            LabelEntity(label: label3),
            LabelEntity(label: label1)
        ])

        XCTAssertEqual(sut.orderedLocation?.labelID.rawValue, label3.labelID)
    }

    func testOrderedLabel() {
        let message = Message(context: testContext)
        message.messageID = UUID().uuidString
        let label1 = Label(context: testContext)
        label1.labelID = "sdfpoapvmsnd"
        label1.order = NSNumber(1)
        label1.type = NSNumber(1)
        let label2 = Label(context: testContext)
        label2.labelID = "saonasinoaisfoiasfj"
        label2.order = NSNumber(2)
        label2.type = NSNumber(1)
        let label3 = Label(context: testContext)
        label3.labelID = "saonasinoaiasdasdsfoiasfj"
        label3.order = NSNumber(3)
        label3.type = NSNumber(2)

        var sut = MessageEntity(message)
        sut.setLabels([
            LabelEntity(label: label3),
            LabelEntity(label: label2),
            LabelEntity(label: label1)
        ])

        XCTAssertEqual(sut.orderedLabel,
                       [
                           LabelEntity(label: label1),
                           LabelEntity(label: label2)
                       ])
    }

    func testCustomFolder() {
        let message = Message(context: testContext)
        message.messageID = UUID().uuidString
        let label1 = Label(context: testContext)
        label1.labelID = "sdfpoapvmsnd"
        label1.order = NSNumber(1)
        label1.type = NSNumber(1)
        let label2 = Label(context: testContext)
        label2.labelID = "saonasinoaisfoiasfj"
        label2.order = NSNumber(2)
        label2.type = NSNumber(1)
        let label3 = Label(context: testContext)
        label3.labelID = "saonasinoaiasdasdsfoiasfj"
        label3.order = NSNumber(3)
        label3.type = NSNumber(3)

        var sut = MessageEntity(message)
        sut.setLabels([
            LabelEntity(label: label3),
            LabelEntity(label: label2),
            LabelEntity(label: label1)
        ])

        XCTAssertEqual(sut.customFolder, LabelEntity(label: label3))
    }

    func testIsCustomFolder() {
        let message = Message(context: testContext)
        message.messageID = UUID().uuidString
        let label1 = Label(context: testContext)
        label1.labelID = "sdfpoapvmsnd"
        label1.order = NSNumber(1)
        label1.type = NSNumber(1)
        let label2 = Label(context: testContext)
        label2.labelID = "saonasinoaisfoiasfj"
        label2.order = NSNumber(2)
        label2.type = NSNumber(1)
        let label3 = Label(context: testContext)
        label3.labelID = "saonasinoaiasdasdsfoiasfj"
        label3.order = NSNumber(3)
        label3.type = NSNumber(3)

        var sut = MessageEntity(message)
        sut.setLabels([
            LabelEntity(label: label3),
            LabelEntity(label: label2),
            LabelEntity(label: label1)
        ])

        XCTAssertTrue(sut.isCustomFolder)
	}
    func testIsScheduledSend() {
        let message = Message(context: testContext)
        message.messageID = UUID().uuidString
        message.flags = NSNumber(value: 1 << 20)

        let sut = MessageEntity(message)

        XCTAssertTrue(sut.isScheduledSend)
    }
}
