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
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_TestingToolkit

final class MessageInfoProviderTest: XCTestCase {
    private var systemUpTime: SystemUpTimeMock!
    private var labelID: LabelID!
    private var message: MessageEntity!
    private var user: UserManager!
    private var apiMock: APIServiceMock!
    private var coreDataService: CoreDataService!
    private var testContext: NSManagedObjectContext!
    private var sut: MessageInfoProvider!
    private var isDarkModeEnableStub: Bool = false
    private var delegateObject: ProviderDelegate!

    override func setUpWithError() throws {
        Environment.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        systemUpTime = SystemUpTimeMock(localServerTime: TimeInterval(1635745851),
                                        localSystemUpTime: TimeInterval(2000),
                                        systemUpTime: TimeInterval(2000))
        labelID = LabelID("0")
        apiMock = APIServiceMock()
        coreDataService = CoreDataService(container: MockCoreDataStore.testPersistentContainer)

        testContext = coreDataService.mainContext
        let parsedObject = testMessageDetailData.parseObjectAny()!
        let messageStub = try GRTJSONSerialization.object(withEntityName: "Message",
                                                          fromJSONDictionary: parsedObject,
                                                          in: testContext) as? Message
        messageStub?.userID = "userID"
        messageStub?.isDetailDownloaded = true
        try testContext.save()

        message = MessageEntity(try XCTUnwrap(messageStub))
        user = UserManager(api: apiMock, role: .member)
    }

    override func tearDownWithError() throws {
        systemUpTime = nil
        labelID = nil
        message = nil
        apiMock = nil
        user = nil
        coreDataService = nil

        testContext = nil
        sut = nil
        isDarkModeEnableStub = false
        delegateObject = nil
    }

    func testBasicData() {
        sut = MessageInfoProvider(message: message, user: user, systemUpTime: systemUpTime, labelID: labelID, isDarkModeEnableClosure: { [weak self] in
            return self?.isDarkModeEnableStub ?? false
        })
        XCTAssertEqual(sut.initials.string, "P")
        XCTAssertEqual(sut.senderEmail.string, "contact@protonmail.ch")
        XCTAssertEqual(sut.time.string, "May 02, 2018")
        XCTAssertEqual(sut.date?.string, "May 2, 2018 at 4:43:19 PM")
        XCTAssertEqual(sut.originFolderTitle(isExpanded: false)?.string, "Inbox")
        XCTAssertEqual(sut.size?.string, "2 KB")
        XCTAssertEqual(sut.simpleRecipient?.string, "To: cc name, feng88@protonmail.com")

        let toList = sut.toData
        XCTAssertEqual(toList?.title.string, "To:")
        XCTAssertEqual(toList?.recipients.count, 1)
        XCTAssertEqual(toList?.recipients.first?.name.string, "feng88@protonmail.com")

        let ccList = sut.ccData
        XCTAssertEqual(ccList?.title.string, "CC:")
        XCTAssertEqual(ccList?.recipients.count, 1)
        XCTAssertEqual(ccList?.recipients.first?.name.string, "cc name")
    }

    func testPGP_keysAPI_failed() {
        let expectation1 = expectation(description: "get failed server validation error")
        apiMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                completion?(nil, ["Code": 33101, "Error": "Server failed validation"], nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }

        sut = MessageInfoProvider(message: message, user: user, systemUpTime: systemUpTime, labelID: labelID, isDarkModeEnableClosure: { [weak self] in
            return self?.isDarkModeEnableStub ?? false
        })
        delegateObject = ProviderDelegate()
        sut.set(delegate: delegateObject)

        delegateObject.senderContactUpdate = { contact in
            expectation1.fulfill()
            let text = contact?.encryptionIconStatus?.text
            XCTAssertEqual(text, "Sender Verification Failed")
        }
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

    private func prepareMessageForDecryptTest() throws {
        let keyPair = try MailCrypto.generateRandomKeyPair()
        let key = Key(keyID: "1", privateKey: keyPair.privateKey)
        key.signature = "signature is needed to make this a V2 key"
        let address = Address(
            addressID: "",
            domainID: nil,
            email: "",
            send: .active,
            receive: .active,
            status: .enabled,
            type: .externalAddress,
            order: 1,
            displayName: "",
            signature: "a",
            hasKeys: 1,
            keys: [key]
        )

        user = UserManager(api: apiMock, role: .member)
        user.userinfo.userAddresses = [address]
        user.userinfo.userKeys = [key]
        user.auth.mailboxpassword = keyPair.passphrase

        let body = MessageDecrypterTestData.decryptedHTMLMimeBody()
        let messageObject = try self.prepareEncryptedMessage(body: body, mimeType: .multipartMixed)
        message = MessageEntity(messageObject)
    }

    func testMIMEDecrypt() throws {
        try prepareMessageForDecryptTest()

        let expectation1 = expectation(description: "decrypt body test")
        expectation1.expectedFulfillmentCount = 3
        sut = MessageInfoProvider(message: message, user: user, systemUpTime: systemUpTime, labelID: labelID, isDarkModeEnableClosure: { [weak self] in
            return self?.isDarkModeEnableStub ?? false
        })
        delegateObject = ProviderDelegate()
        sut.set(delegate: delegateObject)

        delegateObject.contentUpdate = { _ in
            expectation1.fulfill()
        }
        delegateObject.attachmentsUpdate = {
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 500) { error in
            XCTAssertNil(error)
        }
        XCTAssertEqual(sut.inlineAttachments?.count, 0)
        XCTAssertEqual(sut.nonInlineAttachments.count, 0)
        XCTAssertEqual(sut.mimeAttachments.count, 2)
        XCTAssertNotNil(sut.contents)
    }
}

extension MessageInfoProviderTest {
    private func prepareEncryptedMessage(body: String, mimeType: Message.MimeType) throws -> Message {
        let encryptedBody = try Crypto().encryptNonOptional(
            plainText: body,
            publicKey: user.addressKeys.first!.publicKey
        )

        let parsedObject = testMessageDetailData.parseObjectAny()!
        let messageStub = try GRTJSONSerialization.object(withEntityName: "Message",
                                                          fromJSONDictionary: parsedObject,
                                                          in: testContext) as? Message
        messageStub?.userID = "userID"
        messageStub?.isDetailDownloaded = true
        messageStub?.body = encryptedBody
        messageStub?.mimeType = mimeType.rawValue
        return try XCTUnwrap(messageStub)
    }
}

final private class ProviderDelegate: MessageInfoProviderDelegate {

    var senderContactUpdate: ((ContactVO?) -> Void)?
    func update(senderContact: ContactVO?) {
        senderContactUpdate?(senderContact)
    }

    func hideDecryptionErrorBanner() {

    }

    func showDecryptionErrorBanner() {

    }

    func updateBannerStatus() {

    }

    var contentUpdate: ((WebContents?) -> Void)?
    func update(content: WebContents?) {
        contentUpdate?(content)
    }

    func update(hasStrippedVersion: Bool) {

    }

    func update(renderStyle: MessageRenderStyle) {

    }

    func sendDarkModeMetric(isApply: Bool) {

    }

    var attachmentsUpdate: (() -> Void)?
    func updateAttachments() {
        attachmentsUpdate?()
    }
}
