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

import Foundation
import Groot
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_Services
import ProtonCore_TestingToolkit
@testable import ProtonMail
import XCTest

final class PrepareSendMetadataTests: XCTestCase {
    var sut: PrepareSendMetadata!

    private var mockApiService: APIServiceMock!
    private var mockUserManager: UserManager!
    private var mockResolveSendPreferences: MockResolveSendPreferences!
    private var mockFetchAttachment: MockFetchAttachment!
    private let mockCoreDataService = MockCoreDataContextProvider()

    private let dummyMessageURI = "dummy_uri"
    private let dummyRecipientEmailAddress = "recipient@example.com"
    private let dummyMessageBody = "dummy hello world"
    private let dumyMessagePassword = "dummy_password"
    private let dumyMessagePasswordHint = "dummy_password_hint"
    private let dummyAttachmentId = UUID().uuidString

    private var dummyUserKey: (passphrase: String, publicKey: String, privateKey: String)!
    private var dummySenderAddressKey: Key!
    private lazy var dummyAttachmentFile = { makeAttachmentFile() }()
    private lazy var dummySendPreferences: RecipientSendPreferences = { makeRecipientSendPreferences() }()
    private lazy var dummySenderAddress: Address = { makeAddress(addressKeys: [dummySenderAddressKey]) }()
    private lazy var dummySenderAddressNoKeys: Address = { makeAddress(addressKeys: []) }()

    private let waitTimeout = 2.0

    override func setUp() {
        super.setUp()
        dummyUserKey = try! CryptoKeyHelper.makeKeyPair()
        dummySenderAddressKey = CryptoKeyHelper.makeAddressKey(userKey: dummyUserKey)
        sut = makeSUT()
    }

    override func tearDown() {
        super.tearDown()
        mockApiService = nil
        mockUserManager = nil
        mockResolveSendPreferences = nil
        mockFetchAttachment = nil
        sut = nil
    }

    func testExecution_whenEverythingSucceeds_returnsCorrectMetadata() {
        let messageSendingData = setUpDependenciesForSuccess()
        let expectation = expectation(description: "")
        sut.execute(params: .init(messageSendingData: messageSendingData)) { [unowned self] result in
            let sendMessageMetadata = try! result.get()
            XCTAssert(sendMessageMetadata.messageID == messageSendingData.message.messageID)
            XCTAssert(sendMessageMetadata.timeToExpire == messageSendingData.message.expirationOffset)
            XCTAssert(sendMessageMetadata.decryptedBody == dummyMessageBody)
            XCTAssert(sendMessageMetadata.recipientSendPreferences.count == 1)
            XCTAssert(sendMessageMetadata.attachments.count == 1)
            XCTAssert(sendMessageMetadata.encodedAttachments.keys.count == 1)
            XCTAssert(sendMessageMetadata.password == messageSendingData.message.password)
            XCTAssert(sendMessageMetadata.passwordHint == messageSendingData.message.passwordHint)
            expectation.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    func testExecution_whenNoSenderAddressFound_returnsError() {
        let messageSendingData = setUpDependenciesForError(.noSenderAddressFound)
        let expectation = expectation(description: "")
        sut.execute(params: .init(messageSendingData: messageSendingData)) { result in
            switch result {
            case .failure(let error as PrepareSendMessageMetadataError):
                XCTAssert(error == .noSenderAddressFound)
            default:
                XCTFail()
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    func testExecution_whenNoSenderAddressKeyFound_returnsError() {
        let messageSendingData = setUpDependenciesForError(.noSenderAddressKeyFound)
        let expectation = expectation(description: "")
        sut.execute(params: .init(messageSendingData: messageSendingData)) { result in
            switch result {
            case .failure(let error as PrepareSendMessageMetadataError):
                XCTAssert(error == .noSenderAddressKeyFound)
            default:
                XCTFail()
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    func testExecution_whenCryptoLibThrowsError_returnsError() {
        let messageSendingData = setUpDependenciesForCryptoLibErrorThrow()
        let expectation = expectation(description: "")
        sut.execute(params: .init(messageSendingData: messageSendingData)) { result in
            switch result {
            case .failure(let error as PrepareSendMessageMetadataError):
                XCTFail(error.rawValue)
            case .failure:
                XCTAssert(true)
            default:
                XCTFail()
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }
}

// MARK: Helper functions

extension PrepareSendMetadataTests {

    private func makeSUT() -> PrepareSendMetadata {
        mockApiService = APIServiceMock()
        mockUserManager = makeUserManager(apiMock: mockApiService)
        mockResolveSendPreferences = MockResolveSendPreferences()
        mockFetchAttachment = MockFetchAttachment()

        let dependencies = PrepareSendMetadata.Dependencies(
            userDataSource: mockUserManager,
            resolveSendPreferences: mockResolveSendPreferences,
            fetchAttachment: mockFetchAttachment
        )
        return PrepareSendMetadata(dependencies: dependencies)
    }

    private func setUpDependenciesForSuccess() -> MessageSendingData {
        mockResolveSendPreferences.result = .success([dummySendPreferences])
        mockFetchAttachment.result = .success(dummyAttachmentFile)
        let messageData = makeMessageSendingData(
            senderAddress: dummySenderAddress,
            encryptedBody: makeEncryptedBodyWithCorrectSenderAddressKey()
        )
        return messageData
    }

    private func setUpDependenciesForError(_ error: PrepareSendMessageMetadataError) -> MessageSendingData {
        mockResolveSendPreferences.result = .success([dummySendPreferences])
        mockFetchAttachment.result = .success(dummyAttachmentFile)
        let correctEncryptedBody = makeEncryptedBodyWithCorrectSenderAddressKey()
        let messageSendingData: MessageSendingData
        switch error {
        case .noSenderAddressFound:
            let messageData = makeMessageSendingData(senderAddress: nil, encryptedBody: correctEncryptedBody)
            messageSendingData = messageData
        case .noSenderAddressKeyFound:
            let messageData = makeMessageSendingData(senderAddress: dummySenderAddressNoKeys, encryptedBody: correctEncryptedBody)
            messageSendingData = messageData
        default:
            fatalError()
        }
        return messageSendingData
    }

    private func setUpDependenciesForCryptoLibErrorThrow() -> MessageSendingData {
        mockResolveSendPreferences.result = .success([dummySendPreferences])
        mockFetchAttachment.result = .success(dummyAttachmentFile)
        let messageData = makeMessageSendingData(
            senderAddress: dummySenderAddress,
            encryptedBody: makeEncryptedBodyWithWrongKey()
        )
        return messageData
    }

    private func makeUserManager(apiMock: APIServiceMock) -> UserManager {
        let user = UserManager(api: apiMock, role: .member)
        user.userInfo.userAddresses = [dummySenderAddress]
        user.userInfo.userKeys = [Key(keyID: "1", privateKey: dummyUserKey.privateKey)]
        user.authCredential.mailboxpassword = dummyUserKey.passphrase
        return user
    }

    private func makeAddress(addressKeys: [Key]) -> Address {
        return Address(
            addressID: "",
            domainID: nil,
            email: "sender@example.com",
            send: .active,
            receive: .active,
            status: .enabled,
            type: .externalAddress,
            order: 1,
            displayName: "Sender",
            signature: "a",
            hasKeys: 1,
            keys: addressKeys
        )
    }

    private func makeMessageSendingData(
        senderAddress: Address?,
        encryptedBody: String
    ) -> MessageSendingData {
        let dummyMessage = makeMessage(encryptedBody: encryptedBody)
        let dummyAttachment = makeAttachment()
        dummyMessage.attachments = NSSet(array: [dummyAttachment])

        let messageSendingData = MessageSendingData(
            message: MessageEntity(dummyMessage),
            cachedUserInfo: nil,
            cachedAuthCredential: nil,
            cachedSenderAddress: nil,
            defaultSenderAddress: senderAddress
        )
        return messageSendingData
    }

    private func makeEncryptedBodyWithCorrectSenderAddressKey() -> String {
        return try! dummyMessageBody.encrypt(
            withKey: dummySenderAddressKey,
            userKeys: mockUserManager.userPrivateKeys,
            mailbox_pwd: Passphrase(value: dummyUserKey.passphrase)
        )
    }

    private func makeEncryptedBodyWithWrongKey() -> String {
        let randomKey = Key(keyID: "2", privateKey: dummyUserKey.privateKey)
        return try! dummyMessageBody.encrypt(
            withKey: randomKey,
            userKeys: mockUserManager.userPrivateKeys,
            mailbox_pwd: Passphrase(value: dummyUserKey.passphrase)
        )
    }

    private func makeMessage(encryptedBody: String) -> Message {
        let message = Message(context: mockCoreDataService.mainContext)
        message.messageID = UUID().uuidString
        message.userID = "userID"
        message.body = encryptedBody
        message.toList = "[{\"Address\": \(dummyRecipientEmailAddress), \"Name\": \"\", \"Group\": \"\"}]"
        message.password = dumyMessagePassword
        message.passwordHint = dumyMessagePasswordHint
        return message
    }

    private func makeAttachment() -> Attachment {
        let attachment = Attachment(context: mockCoreDataService.mainContext)
        attachment.attachmentID = dummyAttachmentId
        attachment.localURL = Bundle(for: PrepareSendMetadataTests.self)
            .url(forResource: "plainData", withExtension: "txt")!
        let encryption: (keyPacket: Data, url: URL)! = try! attachment.encrypt(byKey: dummySenderAddressKey)
        attachment.keyPacket = Based64.encode(raw: encryption.keyPacket)
        return attachment
    }

    private func makeAttachmentFile() -> AttachmentFile {
        return AttachmentFile(
            attachmentId: AttachmentID(rawValue: dummyAttachmentId),
            fileUrl: URL(fileURLWithPath: "localfile"),
            encoded: Based64.encode(value: "dummy_attachment")
        )
    }

    private func makeRecipientSendPreferences() -> RecipientSendPreferences {
        let preferences = SendPreferences(
            encrypt: true,
            sign: true,
            pgpScheme: .pgpMIME,
            mimeType: .mime,
            publicKeys: nil,
            isPublicKeyPinned: false,
            hasApiKeys: false,
            hasPinnedKeys: false,
            error: nil
        )
        return RecipientSendPreferences(emailAddress: dummyRecipientEmailAddress, sendPreferences: preferences)
    }
}
