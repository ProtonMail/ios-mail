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
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_TestingToolkit
import XCTest

@testable import ProtonMail

final class MessageInfoProviderTest: XCTestCase {
    private var apiMock: APIServiceMock!
    private var isDarkModeEnableStub: Bool = false
    private var delegateObject: ProviderDelegate!
    private var message: MessageEntity!
    private var sut: MessageInfoProvider!
    private var user: UserManager!

    override func setUpWithError() throws {
        Environment.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        let systemUpTime = SystemUpTimeMock(
            localServerTime: TimeInterval(1635745851),
            localSystemUpTime: TimeInterval(2000),
            systemUpTime: TimeInterval(2000)
        )
        let labelID = LabelID("0")
        apiMock = APIServiceMock()

        user = try Self.prepareUser(apiMock: apiMock)
        message = try Self.prepareEncryptedMessage(
            body: MessageDecrypterTestData.decryptedHTMLMimeBody(),
            mimeType: .multipartMixed,
            user: user
        )

        sut = MessageInfoProvider(message: message, user: user, systemUpTime: systemUpTime, labelID: labelID, isDarkModeEnableClosure: { [weak self] in
            return self?.isDarkModeEnableStub ?? false
        })

        delegateObject = ProviderDelegate()
        sut.set(delegate: delegateObject)
    }

    override func tearDownWithError() throws {
        sut = nil
        isDarkModeEnableStub = false
        apiMock = nil
        delegateObject = nil
        message = nil
        user = nil
    }

    func testBasicData() {
        XCTAssertEqual(sut.initials, "P")
        XCTAssertEqual(sut.senderEmail, "contact@protonmail.ch")
        XCTAssertEqual(sut.time, "May 02, 2018")
        XCTAssertEqual(sut.date, "May 2, 2018 at 4:43:19 PM")
        XCTAssertEqual(sut.originFolderTitle(isExpanded: false), "Inbox")
        XCTAssertEqual(sut.size, "2 KB")
        XCTAssertEqual(sut.simpleRecipient, "To: cc name, feng88@protonmail.com")

        let toList = sut.toData
        XCTAssertEqual(toList?.title, "To:")
        XCTAssertEqual(toList?.recipients.count, 1)
        XCTAssertEqual(toList?.recipients.first?.name, "feng88@protonmail.com")

        let ccList = sut.ccData
        XCTAssertEqual(ccList?.title, "CC:")
        XCTAssertEqual(ccList?.recipients.count, 1)
        XCTAssertEqual(ccList?.recipients.first?.name, "cc name")
    }

    func testPGPChecker_keysAPIFailedAndNoAddressKeys_failsVerification() {
        let expectation1 = expectation(description: "get failed server validation error")
        apiMock.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, completion in
            if path.contains("/keys") {
                completion(nil, .success(["Code": 33101, "Error": "Server failed validation"]))
            } else {
                XCTFail("Unexpected path")
                completion(nil, .failure(NSError.badResponse()))
            }
        }
        user.addresses.removeAll()

        delegateObject.senderContactUpdate.bodyIs { _, contact in
            expectation1.fulfill()
            let text = contact?.encryptionIconStatus?.text
            XCTAssertEqual(text, "Sender Verification Failed")
        }

        sut.initialize()

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

    func testMIMEDecrypt() throws {
        let expectation1 = expectation(description: "decrypt body test")
        expectation1.expectedFulfillmentCount = 3

        sut.initialize()

        delegateObject.contentUpdate.bodyIs { _, _ in
            expectation1.fulfill()
        }
        delegateObject.attachmentsUpdate.bodyIs { _ in
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3) { error in
            XCTAssertNil(error)
        }
        XCTAssertEqual(sut.inlineAttachments?.count, 0)
        XCTAssertEqual(sut.nonInlineAttachments.count, 0)
        XCTAssertEqual(sut.mimeAttachments.count, 2)
        XCTAssertNotNil(sut.contents)
    }
}

extension MessageInfoProviderTest {
    private static func prepareUser(apiMock: APIServiceMock) throws -> UserManager {
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

        let user = UserManager(api: apiMock, role: .member)
        user.userInfo.userAddresses = [address]
        user.userInfo.userKeys = [key]
        user.authCredential.mailboxpassword = keyPair.passphrase
        return user
    }

    private static func prepareEncryptedMessage(
        body: String,
        mimeType: Message.MimeType,
        user: UserManager
    ) throws -> MessageEntity {
        let encryptedBody = try Crypto().encryptNonOptional(
            plainText: body,
            publicKey: user.addressKeys.first!.publicKey
        )

        let parsedObject = testMessageDetailData.parseObjectAny()!
        let coreDataService = CoreDataService(container: MockCoreDataStore.testPersistentContainer)
        let testContext = coreDataService.mainContext
        let messageStub = try GRTJSONSerialization.object(withEntityName: "Message",
                                                          fromJSONDictionary: parsedObject,
                                                          in: testContext) as? Message
        messageStub?.userID = "userID"
        messageStub?.isDetailDownloaded = true
        messageStub?.body = encryptedBody
        messageStub?.mimeType = mimeType.rawValue
        let messageObject = try XCTUnwrap(messageStub)
        return MessageEntity(messageObject)
    }
}

final private class ProviderDelegate: MessageInfoProviderDelegate {

    @FuncStub(update(senderContact:)) var senderContactUpdate
    func update(senderContact: ContactVO?) {
        senderContactUpdate(senderContact)
    }

    func hideDecryptionErrorBanner() {

    }

    func showDecryptionErrorBanner() {

    }

    func updateBannerStatus() {

    }

    @FuncStub(update(content:)) var contentUpdate
    func update(content: WebContents?) {
        contentUpdate(content)
    }

    func update(hasStrippedVersion: Bool) {

    }

    func update(renderStyle: MessageRenderStyle) {

    }

    func sendDarkModeMetric(isApply: Bool) {

    }

    @FuncStub(updateAttachments) var attachmentsUpdate
    func updateAttachments() {
        attachmentsUpdate()
    }
}
