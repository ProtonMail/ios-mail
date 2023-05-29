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

import PromiseKit
import ProtonCore_DataModel
import ProtonCore_TestingToolkit
@testable import ProtonMail
import XCTest

final class ComposerMessageHelperTests: XCTestCase {
    var contextProviderMock: MockCoreDataContextProvider!
    var fakeUser: UserManager!
    var messageDataServiceMock: MockMessageDataService!
    var sut: ComposerMessageHelper!
    var testMessage: Message!
    var cacheServiceMock: MockCacheServiceProtocol!

    override func setUp() {
        super.setUp()
        contextProviderMock = MockCoreDataContextProvider()
        fakeUser = UserManager(api: APIServiceMock(), role: .none)
        messageDataServiceMock = MockMessageDataService()
        testMessage = createTestMessage()
        cacheServiceMock = .init()
        sut = ComposerMessageHelper(
            dependencies: .init(messageDataService: messageDataServiceMock,
                                cacheService: cacheServiceMock,
                                contextProvider: contextProviderMock),
            user: fakeUser)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        sut = nil
        messageDataServiceMock = nil
        fakeUser = nil
        contextProviderMock = nil
        testMessage = nil
        cacheServiceMock = nil

        guard FileManager.default.fileExists(atPath: FileManager.default.temporaryDirectory.absoluteString) else {
            return
        }
        try FileManager.default.removeItem(at: FileManager.default.temporaryDirectory)
    }

    func testSetNewMessageByObjectID() throws {
        let objectID = testMessage.objectID
        XCTAssertNil(sut.draft)
        sut.setNewMessage(objectID: objectID)

        let draft = try XCTUnwrap(sut.draft)
        XCTAssertEqual(draft.messageID.rawValue, testMessage.messageID)
    }

    func testCollectDraft_withNilDraft_NewDraftShouldBeCreated() throws {
        let recipientList = String.randomString(30)
        let bccList = String.randomString(30)
        let ccList = String.randomString(30)
        let sendAddress = Address.dummy
        let title = String.randomString(30)
        let body = String.randomString(30)
        let expiration: TimeInterval = 0
        let password = String.randomString(30)
        let passwordHint = String.randomString(30)
        self.messageDataServiceMock.mockMessage = testMessage
        testMessage.toList = recipientList
        testMessage.bccList = bccList
        testMessage.ccList = ccList
        testMessage.title = title
        testMessage.body = body
        testMessage.addressID = sendAddress.addressID

        sut.collectDraft(recipientList: recipientList,
                         bccList: bccList,
                         ccList: ccList,
                         sendAddress: sendAddress,
                         title: title,
                         body: body,
                         expiration: expiration,
                         password: password,
                         passwordHint: passwordHint)

        let draft = try XCTUnwrap(sut.draft)
        XCTAssertEqual(draft.recipientList, recipientList)
        XCTAssertEqual(draft.bccList, bccList)
        XCTAssertEqual(draft.ccList, ccList)
        XCTAssertEqual(draft.sendAddressID.rawValue, sendAddress.addressID)
        XCTAssertEqual(draft.title, title)
        XCTAssertEqual(draft.body, body)
        XCTAssertEqual(draft.expiration, expiration)
        XCTAssertEqual(draft.password, password)
        XCTAssertEqual(draft.passwordHint, passwordHint)
    }

    func testCollectDraft_withDraft_DraftIsUpdated() throws {
        let recipientList = String.randomString(30)
        let bccList = String.randomString(30)
        let ccList = String.randomString(30)
        let sendAddress = Address.dummy
        let title = String.randomString(30)
        let body = String.randomString(30)
        let expiration: TimeInterval = 0
        let password = String.randomString(30)
        let passwordHint = String.randomString(30)
        sut.setNewMessage(objectID: testMessage.objectID)

        sut.collectDraft(recipientList: recipientList,
                         bccList: bccList,
                         ccList: ccList,
                         sendAddress: sendAddress,
                         title: title,
                         body: body,
                         expiration: expiration,
                         password: password,
                         passwordHint: passwordHint)

        let draft = try XCTUnwrap(sut.draft)
        XCTAssertEqual(draft.recipientList, recipientList)
        XCTAssertEqual(draft.bccList, bccList)
        XCTAssertEqual(draft.ccList, ccList)
        XCTAssertEqual(draft.sendAddressID.rawValue, sendAddress.addressID)
        XCTAssertEqual(draft.title, title)
        XCTAssertEqual(draft.expiration, expiration)
        XCTAssertEqual(draft.password, password)
        XCTAssertEqual(draft.passwordHint, passwordHint)

        let updateMsgArgument = try XCTUnwrap(messageDataServiceMock.callUpdateMessage.lastArguments)
        XCTAssertTrue(messageDataServiceMock.callUpdateMessage.wasCalledExactlyOnce)
        XCTAssertEqual(updateMsgArgument.a1, testMessage)
        XCTAssertEqual(updateMsgArgument.a2, expiration)
        XCTAssertEqual(updateMsgArgument.a3, body)
    }

    func testUploadDraft() throws {
        sut.setNewMessage(objectID: testMessage.objectID)
        sut.uploadDraft()

        XCTAssertTrue(messageDataServiceMock.callSaveDraft.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(messageDataServiceMock.callSaveDraft.lastArguments)
        XCTAssertEqual(argument.a1, testMessage)
    }

    func testMarkAsRead_withReadMsg_markIsNotCalled() {
        testMessage.unRead = false
        sut.setNewMessage(objectID: testMessage.objectID)

        sut.markAsRead()

        XCTAssertTrue(messageDataServiceMock.callMark.wasNotCalled)
    }

    func testMarkAsRead_withUnReadMsg_markIsCalled() throws {
        testMessage.unRead = true
        sut.setNewMessage(objectID: testMessage.objectID)

        sut.markAsRead()

        XCTAssertTrue(messageDataServiceMock.callMark.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(messageDataServiceMock.callMark.lastArguments)
        XCTAssertEqual(argument.a1, [testMessage.objectID])
        XCTAssertEqual(argument.a2, Message.Location.draft.labelID)
        XCTAssertFalse(argument.a3)
    }

    func testMarkAsRead_withNilMsg_markIsNotCalled() {
        sut.markAsRead()

        XCTAssertTrue(messageDataServiceMock.callMark.wasNotCalled)
    }

    func testCopyAndCreateDraft() throws {
        messageDataServiceMock.mockDecrypter = .init(userDataSource: fakeUser)
        messageDataServiceMock.mockDecrypter.callCopy.bodyIs { _, _, _, _ in
            self.testMessage
        }
        let shouldCopyAttachment = Bool.random()
        sut.copyAndCreateDraft(from: testMessage, shouldCopyAttachment: shouldCopyAttachment)

        XCTAssertTrue(messageDataServiceMock.mockDecrypter.callCopy.wasCalledExactlyOnce)
        let arguments = try XCTUnwrap(messageDataServiceMock.mockDecrypter.callCopy.lastArguments)
        XCTAssertEqual(arguments.a1, testMessage)
        XCTAssertEqual(arguments.a2, shouldCopyAttachment)
    }

    func testUpdateAddressID() throws {
        let e = expectation(description: "Closure is called")
        let newAddressID = String.randomString(40)
        sut.setNewMessage(objectID: testMessage.objectID)

        sut.updateAddressID(addressID: newAddressID) {
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertEqual(testMessage.nextAddressID, newAddressID)
        XCTAssertTrue(messageDataServiceMock.callUpdateAttKeyPacket.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(messageDataServiceMock.callUpdateAttKeyPacket.lastArguments)
        XCTAssertEqual(argument.a1, MessageEntity(testMessage))
        XCTAssertEqual(argument.a2, newAddressID)
    }

    func testUpdateExpirationOffset() throws {
        sut.setNewMessage(objectID: testMessage.objectID)
        let e = expectation(description: "Closure is called")
        let expirationTime: TimeInterval = 100.0
        let password = String.randomString(10)
        let hint = String.randomString(10)
        cacheServiceMock.updateExpirationOffsetStub.bodyIs { _, _, _, _, _, callBack in
            callBack?()
        }

        sut.updateExpirationOffset(expirationTime: expirationTime, password: password, passwordHint: hint) {
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(cacheServiceMock.updateExpirationOffsetStub.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(cacheServiceMock.updateExpirationOffsetStub.lastArguments)
        XCTAssertEqual(argument.a1, testMessage.objectID)
        XCTAssertEqual(argument.a2, expirationTime)
        XCTAssertEqual(argument.a3, password)
        XCTAssertEqual(argument.a4, hint)
    }

    func testUpdateMessageByMessageAction_reply_titleWillHasRe() {
        let title = String.randomString(30)
        testMessage.title = title
        sut.setNewMessage(objectID: testMessage.objectID)

        sut.updateMessageByMessageAction(.reply)

        XCTAssertEqual(sut.draft?.title, "\(LocalString._composer_short_reply) \(title)")
        XCTAssertEqual(testMessage.action?.intValue,
                       ComposeMessageAction.reply.rawValue)
    }

    func testUpdateMessageByMessageAction_replyAll_titleWillHasRe() {
        let title = String.randomString(30)
        testMessage.title = title
        sut.setNewMessage(objectID: testMessage.objectID)

        sut.updateMessageByMessageAction(.replyAll)

        XCTAssertEqual(sut.draft?.title, "\(LocalString._composer_short_reply) \(title)")
        XCTAssertEqual(testMessage.action?.intValue,
                       ComposeMessageAction.replyAll.rawValue)
    }

    func testUpdateMessageByMessageAction_forward_titleWillHasFwd() {
        let title = String.randomString(30)
        testMessage.title = title
        sut.setNewMessage(objectID: testMessage.objectID)

        sut.updateMessageByMessageAction(.forward)

        XCTAssertEqual(sut.draft?.title, "\(LocalString._composer_short_forward_shorter) \(title)")
        XCTAssertEqual(testMessage.action?.intValue,
                       ComposeMessageAction.forward.rawValue)
    }

    func testUpdateMessageByMessageAction_other_titleNoChanged() {
        let title = String.randomString(30)
        testMessage.title = title
        sut.setNewMessage(objectID: testMessage.objectID)

        sut.updateMessageByMessageAction(.newDraft)
        XCTAssertEqual(sut.draft?.title, title)

        sut.updateMessageByMessageAction(.newDraftFromShare)
        XCTAssertEqual(sut.draft?.title, title)

        sut.updateMessageByMessageAction(.openDraft)
        XCTAssertEqual(sut.draft?.title, title)
    }

    func testDecryptBody() {
        sut.setNewMessage(objectID: testMessage.objectID)
        messageDataServiceMock.mockDecrypter = .init(userDataSource: fakeUser)
        let decryptedBody = String.randomString(40)
        messageDataServiceMock.mockDecrypter.callDecrypt.bodyIs { _, _ in
            decryptedBody
        }

        let result = sut.decryptBody()

        XCTAssertEqual(result, decryptedBody)
        XCTAssertTrue(messageDataServiceMock.mockDecrypter.callDecrypt.wasCalledExactlyOnce)
    }

    func testGetRawMessageObject() {
        sut.setNewMessage(objectID: testMessage.objectID)

        let result = sut.getRawMessageObject()

        XCTAssertEqual(result, testMessage)
    }

    func testAddPublicKeyIfNeeded_andSameKeyWillNotBeAttachedTwice() throws {
        sut.setNewMessage(objectID: testMessage.objectID)
        let e = expectation(description: "Closure is called")
        let testData = String.randomString(40).data(using: .utf8)!
        let email = "test@proton.me"
        let fingerprint = String.randomString(40)
        let fileName = "publicKey - \(email) - \(fingerprint).asc"

        sut.addPublicKeyIfNeeded(email: email, fingerprint: fingerprint, data: testData, shouldStripMetaDate: false) { attachment in
            XCTAssertNotNil(attachment)
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(messageDataServiceMock.callUpload.wasCalledExactlyOnce)
        XCTAssertEqual(sut.draft?.numAttachments, 1)
        let attachment = try XCTUnwrap(sut.draft?.attachments.first)
        XCTAssertEqual(attachment.name, fileName)
        XCTAssertEqual(attachment.attachmentType, .general)
        XCTAssertEqual(attachment.rawMimeType, "application/pgp-keys")

        // Add same attachment twice
        let e2 = expectation(description: "Closure is called")
        sut.addPublicKeyIfNeeded(email: email, fingerprint: fingerprint, data: testData, shouldStripMetaDate: false) { attachment in
            XCTAssertNil(attachment)
            e2.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(messageDataServiceMock.callUpload.wasCalledExactlyOnce)
        XCTAssertEqual(sut.draft?.numAttachments, 1)
    }

    func testDeleteAttachment() throws {
        sut.setNewMessage(objectID: testMessage.objectID)
        let attachment = createTestAttachment()
        let e = expectation(description: "Closure is called")

        sut.deleteAttachment(.init(attachment)) {
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(messageDataServiceMock.callDelete.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(messageDataServiceMock.callDelete.lastArguments)
        XCTAssertEqual(argument.a1, .init(attachment))
        XCTAssertEqual(argument.a2, sut.draft?.messageID)
    }

    func testRemoveAttachment() throws {
        let fineName = String.randomString(10)
        let testAttachment = createTestAttachment(filename: fineName)
        testAttachment.message = testMessage
        testMessage.numAttachments = .init(value: 1)
        sut.setNewMessage(objectID: testMessage.objectID)
        let e = expectation(description: "Closure is called")
        messageDataServiceMock.callDelete.bodyIs { _, _, _ in
            testAttachment.message = Message(context: self.contextProviderMock.mainContext)
            return Promise()
        }

        sut.removeAttachment(fileName: fineName, isRealAttachment: true) {
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        let draft = try XCTUnwrap(sut.draft)
        XCTAssertEqual(draft.numAttachments, 0)
        XCTAssertTrue(messageDataServiceMock.callDelete.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(messageDataServiceMock.callDelete.lastArguments)
        XCTAssertEqual(argument.a1.name, AttachmentEntity(testAttachment).name)
        XCTAssertEqual(argument.a2, sut.draft?.messageID)
    }

    func testAddAttachment() throws {
        sut.setNewMessage(objectID: testMessage.objectID)
        let data = String.randomString(50).data(using: .utf8)
        let name = String.randomString(10)
        let file = ConcreteFileData(name: name, ext: "", contents: data!)
        let e = expectation(description: "Closure is called")

        sut.addAttachment(file,
                          shouldStripMetaData: false) { attachment in
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        let draft = try XCTUnwrap(sut.draft)
        XCTAssertFalse(draft.attachments.isEmpty)
    }

    func testAddMIMEAttachment() throws {
        sut.setNewMessage(objectID: testMessage.objectID)
        let data = String.randomString(50)
        let fileName = "test"
        let attachment = try createMimeAttachment(fileName: fileName, text: data)
        let e = expectation(description: "Closure is called")

        sut.addMimeAttachments(attachment: attachment,
                               shouldStripMetaData: false) { attachment in
            XCTAssertNotNil(attachment)
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        let draft = try XCTUnwrap(sut.draft)
        XCTAssertFalse(draft.attachments.isEmpty)
        let attachmentToCheck = try XCTUnwrap(draft.attachments.first)
        XCTAssertEqual(attachmentToCheck.name, fileName)
    }

    func testUpdateAttachmentCount_attachmentNumIsUpdated() {
        let attachment = createTestAttachment()
        attachment.message = testMessage
        sut.setNewMessage(objectID: testMessage.objectID)
        XCTAssertEqual(sut.draft?.numAttachments, 0)
        XCTAssertEqual(testMessage.numAttachments.intValue, 0)

        sut.updateAttachmentCount(isRealAttachment: true)

        XCTAssertEqual(sut.draft?.numAttachments, 1)
        XCTAssertEqual(testMessage.numAttachments.intValue, 1)
    }

    func testUpdateAttachmentOrder_attachmentsHaveRightOrder() {
        let attachment1 = createTestAttachment()
        attachment1.message = testMessage
        attachment1.order = Int32(0)
        let attachment2 = createTestAttachment()
        attachment2.message = testMessage
        attachment2.order = Int32(1)
        let attachment3 = createTestAttachment()
        attachment3.message = testMessage
        attachment3.order = Int32(-1)
        sut.setNewMessage(objectID: testMessage.objectID)
        let e = expectation(description: "Closure is called")

        var attachments: [AttachmentEntity] = []
        sut.updateAttachmentOrders { result in
            attachments = result
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        let ids = attachments.map(\.id.rawValue)
        XCTAssertEqual(ids,
                       [
                        attachment1.attachmentID,
                        attachment2.attachmentID,
                        attachment3.attachmentID
                       ])

        let orders = attachments.map { Int32($0.order) }
        XCTAssertEqual(orders,
                       [
                        attachment1.order,
                        attachment2.order,
                        attachment3.order
                       ])
    }
}

private extension ComposerMessageHelperTests {
    func createTestMessage() -> Message {
        var message: Message?
        contextProviderMock.performAndWaitOnRootSavingContext { context in
            message = Message(context: context)
            message?.messageID = UUID().uuidString
            try? context.save()
        }
        return message!
    }

    func createTestAttachment(filename: String? = nil) -> Attachment {
        var attachment: Attachment?
        contextProviderMock.performAndWaitOnRootSavingContext { context in
            attachment = .init(context: context)
            attachment?.attachmentID = UUID().uuidString
            attachment?.fileName = filename ?? String.randomString(10)
            try? context.save()
        }
        return attachment!
    }

    func createMimeAttachment(fileName: String, text: String) throws -> MimeAttachment {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test").appendingPathExtension("txt")
        try text.write(to: url, atomically: true, encoding: .utf8)
        return MimeAttachment(filename: fileName,
                              size: text.data(using: .utf8)?.count ?? 0,
                              mime: "",
                              path: url,
                              disposition: nil)
    }
}
