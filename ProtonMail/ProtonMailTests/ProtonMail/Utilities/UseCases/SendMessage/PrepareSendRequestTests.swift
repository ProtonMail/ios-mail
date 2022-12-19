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
import GoLibs
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_TestingToolkit
@testable import ProtonMail
import XCTest

final class PrepareSendRequestTests: XCTestCase {
    var sut: PrepareSendRequest!

    private var dummyUserKey: (passphrase: String, publicKey: String, privateKey: String)!
    /// Key for the email address sending the message
    private var dummySenderKey: Key!
    private var dummyWrongSenderKey: Key!
    private let dummyRecipientEmailAddress = "recipient@example.com"
    private var dummyRecipientPublicKey: CryptoKey = try! XCTUnwrap(CryptoKey(fromArmored: OpenPGPDefines.publicKey))
    private var dummyTimeToExpire: Int!
    private var dummyDeliveryTime: Date!
    private var dummySendDelay: Int!
    private var dummyMessageId: String!

    private let waitTimeout = 2.0

    override func setUp() {
        super.setUp()
        dummyUserKey = try! CryptoKeyHelper.makeKeyPair()
        dummySenderKey = CryptoKeyHelper.makeAddressKey(userKey: dummyUserKey)
        dummyWrongSenderKey = Key(keyID: "1", privateKey: try! MailCrypto.generateRandomKeyPair().privateKey)
        dummyTimeToExpire = (-1..<20).randomElement()!
        dummyDeliveryTime = Date().addingTimeInterval(100)
        dummySendDelay = (0..<10).randomElement()!
        dummyMessageId = UUID().uuidString
        sut = PrepareSendRequest()
    }

    override func tearDown() {
        super.tearDown()
        dummyUserKey = nil
        dummySenderKey = nil
        dummyWrongSenderKey = nil
        dummyTimeToExpire = nil
        dummyDeliveryTime = nil
        dummySendDelay = nil
        dummyMessageId = nil
        sut = nil
    }

    func testExecution_whenAnCryptoLibraryErrorIsThrown_returnsError() {

        let expectation = expectation(description: "")
        let params = makeParams(for: .errorIsThrown)
        sut.execute(params: params) { result in
            switch result {
            case .failure:
                XCTAssert(true)
            case .success:
                XCTFail()
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    func testExecution_whenSendingMessageToProtonAccount() {

        let expectation = expectation(description: "")
        let params = makeParams(for: .protonAccount)
        sut.execute(params: params) { [unowned self] result in
            let request: SendMessageRequest = try! result.get()

            // messagePackage
            XCTAssert(request.messagePackage.count == 1)
            let messagePackage = request.messagePackage.first!
            XCTAssert(messagePackage.email == dummyRecipientEmailAddress)
            XCTAssert(messagePackage.sign == 0)
            XCTAssert(messagePackage.scheme == .proton)
            XCTAssert(messagePackage.plainText == false)

            XCTAssert(request.clearBody == nil)

            assertCommonAttributes(for: request, originalEncryptedBody: params.sendMetadata.encryptedBody)
            assertMimeAttributes(for: request, areFilled: false)
            assertPlaintextAttributes(for: request, areFilled: false)

            expectation.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    func testExecution_whenSendingMessageToExternalAccount_withoutSigning() {

        let expectation = expectation(description: "")
        let params = makeParams(for: .externalAccountWithoutSigning)
        sut.execute(params: params) { [unowned self] result in
            let request: SendMessageRequest = try! result.get()

            // messagePackage
            XCTAssert(request.messagePackage.count == 1)
            let messagePackage = request.messagePackage.first!
            XCTAssert(messagePackage.email == dummyRecipientEmailAddress)
            XCTAssert(messagePackage.sign == 0)
            XCTAssert(messagePackage.scheme == .cleartextInline)
            XCTAssert(messagePackage.plainText == false)

            XCTAssert(request.clearBody != nil)

            assertCommonAttributes(for: request, originalEncryptedBody: params.sendMetadata.encryptedBody)
            assertMimeAttributes(for: request, areFilled: false)
            assertPlaintextAttributes(for: request, areFilled: false)

            expectation.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    func testExecution_whenSendingMessageToExternalAccount_plaintTextWithoutSigning() {

        let expectation = expectation(description: "")
        let params = makeParams(for: .externalAccountPlaintextWithoutSigning)
        sut.execute(params: params) { [unowned self] result in
            let request: SendMessageRequest = try! result.get()

            // messagePackage
            XCTAssert(request.messagePackage.count == 1)
            let messagePackage = request.messagePackage.first!
            XCTAssert(messagePackage.email == dummyRecipientEmailAddress)
            XCTAssert(messagePackage.sign == 0)
            XCTAssert(messagePackage.scheme == .cleartextInline)
            XCTAssert(messagePackage.plainText == true)

            XCTAssert(request.clearBody != nil)

            assertCommonAttributes(for: request, originalEncryptedBody: params.sendMetadata.encryptedBody)
            assertMimeAttributes(for: request, areFilled: false)
            assertPlaintextAttributes(for: request, areFilled: true)

            expectation.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    func testExecution_whenSendingMessageToExternalAccount_withSigning() {

        let expectation = expectation(description: "")
        let params = makeParams(for: .externalAccountSigning)
        sut.execute(params: params) { [unowned self] result in
            let request: SendMessageRequest = try! result.get()

            // messagePackage
            XCTAssert(request.messagePackage.count == 1)
            let messagePackage = request.messagePackage.first!
            XCTAssert(messagePackage.email == dummyRecipientEmailAddress)
            XCTAssert(messagePackage.sign == 1)
            XCTAssert(messagePackage.scheme == .cleartextMIME)
            XCTAssert(messagePackage.plainText == false)

            XCTAssert(request.clearBody != nil)

            assertCommonAttributes(for: request, originalEncryptedBody: params.sendMetadata.encryptedBody)
            assertMimeAttributes(for: request, areFilled: true)
            assertPlaintextAttributes(for: request, areFilled: false)

            expectation.fulfill()
        }
        waitForExpectations(timeout: waitTimeout)
    }

    // TODO: There are missing tests for some use cases
    /// Missing tests that would be good to have:
    ///    - Tests for **message with password**: Getting error "gopenpgp: unable to encrypt session key with password: wrong session key size"
    ///    UserInfo={NSLocalizedDescription=gopenpgp: unable to encrypt session key with password: wrong session key size
    ///    - Tests for **message using the public key of the recipient**: I could not attahc a public key to one of my contacts to run in the
    ///    actual application to get the expected results.
    ///

    private func assertCommonAttributes(for request: SendMessageRequest, originalEncryptedBody: Data) {
        XCTAssert(request.messageID == dummyMessageId)
        XCTAssert(request.expirationTime == dummyTimeToExpire)
        XCTAssert(request.deliveryTime == dummyDeliveryTime)
        XCTAssert(request.delaySeconds == dummySendDelay)
        XCTAssert(request.clearAtts == nil)
        XCTAssert(request.body == Based64.encode(raw: originalEncryptedBody))
    }

    private func assertMimeAttributes(for request: SendMessageRequest, areFilled: Bool) {
        if areFilled {
            XCTAssert(request.clearMimeBody != nil)
            XCTAssert(request.mimeDataPacket.isEmpty == false)
        } else {
            XCTAssert(request.clearMimeBody == nil)
            XCTAssert(request.mimeDataPacket.isEmpty == true)
        }
    }

    private func assertPlaintextAttributes(for request: SendMessageRequest, areFilled: Bool) {
        if areFilled {
            XCTAssert(request.clearPlainTextBody != nil)
            XCTAssert(request.plainTextDataPacket.isEmpty == false)
        } else {
            XCTAssert(request.clearPlainTextBody == nil)
            XCTAssert(request.plainTextDataPacket.isEmpty == true)
        }
    }
}

extension PrepareSendRequestTests {

    private enum TestCaseConfiguration {
        case protonAccount
        case externalAccountSigning
        case externalAccountWithoutSigning
        case externalAccountPlaintextWithoutSigning
        case externalAccountWithPassword
        case errorIsThrown

        var pgpScheme: PGPScheme {
            switch self {
            case .protonAccount:
                return .proton
            case .externalAccountSigning:
                return .cleartextMIME
            case .externalAccountWithoutSigning, .externalAccountPlaintextWithoutSigning:
                return .cleartextInline
            case .externalAccountWithPassword:
                return .encryptedToOutside
            case .errorIsThrown:
                return .proton
            }
        }

        var mimeType: SendMIMEType {
            switch self {
            case .protonAccount, .externalAccountWithoutSigning, .externalAccountWithPassword:
                return .mime
            case .externalAccountSigning:
                return .html
            case .externalAccountPlaintextWithoutSigning, .errorIsThrown:
                return .plainText
            }
        }

        var sign: Bool {
            switch self {
            case .protonAccount, .externalAccountSigning, .errorIsThrown:
                return true
            case .externalAccountWithoutSigning, .externalAccountPlaintextWithoutSigning, .externalAccountWithPassword:
                return false
            }
        }

        var encrypt: Bool {
            switch self {
            case .protonAccount, .externalAccountSigning, .externalAccountWithPassword, .errorIsThrown:
                return true
            case .externalAccountWithoutSigning, .externalAccountPlaintextWithoutSigning:
                return false
            }
        }

        var useRecipientPublicKey: Bool {
            switch self {
            case .protonAccount:
                return true
            case .externalAccountSigning, .externalAccountWithoutSigning, .externalAccountPlaintextWithoutSigning,
                    .externalAccountWithPassword, .errorIsThrown:
                return false
            }
        }

        var messagePassword: String? {
            switch self {
            case .externalAccountSigning, .externalAccountWithoutSigning, .externalAccountPlaintextWithoutSigning,
                    .protonAccount, .errorIsThrown:
                return nil
            case .externalAccountWithPassword:
                return "dummy_password"
            }
        }
    }

    private func makeParams(for config: TestCaseConfiguration) -> PrepareSendRequest.Params {
        return PrepareSendRequest.Params(
            authCredential: makeAuthCredential(),
            sendMetadata: makeSendMessageMetadata(config: config),
            scheduleSendDeliveryTime: dummyDeliveryTime,
            undoSendDelay: dummySendDelay
        )
    }

    private func makeAuthCredential() -> AuthCredential {
        return AuthCredential(
            sessionID: "",
            accessToken: "",
            refreshToken: "",
            expiration: Date(),
            userName: "",
            userID: "",
            privateKey: nil,
            passwordKeySalt: nil
        )
    }

    private func makeSendMessageMetadata(config: TestCaseConfiguration) -> SendMessageMetadata {
        let dummyBodyDecrypted = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut
        labore et dolore magna aliqua.
        """
        let dummyBodyEncrypted = try! Encryptor.encrypt(
            publicKey: ArmoredKey(value: dummySenderKey.privateKey.publicKey),
            cleartext: dummyBodyDecrypted
        )

        let recipientSendPreferences = RecipientSendPreferences(
            emailAddress: dummyRecipientEmailAddress,
            sendPreferences: makeSendPreferences(config: config)
        )

        let senderKey: Key
        if config == .errorIsThrown {
            senderKey = dummyWrongSenderKey
        } else {
            senderKey = dummySenderKey
        }

        return SendMessageMetadata(
            keys: SendMessageKeys(
                senderAddressKey: senderKey,
                userKeys: UserKeys(
                    privateKeys: [ArmoredKey(value: dummyUserKey.privateKey)],
                    addressesPrivateKeys: [dummySenderKey],
                    mailboxPassphrase: Passphrase(value: dummyUserKey.passphrase)
                )
            ),
            messageID: MessageID(rawValue: dummyMessageId),
            timeToExpire: dummyTimeToExpire,
            recipientSendPreferences: [recipientSendPreferences],
            bodySessionKey: try! dummyBodyEncrypted.split().keyPacket,
            bodySessionAlgorithm: .AES256,
            encryptedBody: dummyBodyEncrypted.value.data(using: .utf8)!,
            decryptedBody: dummyBodyDecrypted,
            attachments: [],
            encodedAttachments: [:],
            password: config.messagePassword,
            passwordHint: nil
        )
    }

    private func makeSendPreferences(config: TestCaseConfiguration) -> SendPreferences {
        return SendPreferences(
            encrypt: config.encrypt,
            sign: config.sign,
            pgpScheme: config.pgpScheme,
            mimeType: config.mimeType,
            publicKeys: config.useRecipientPublicKey ? dummyRecipientPublicKey : nil,
            isPublicKeyPinned: false,
            hasApiKeys: false,
            hasPinnedKeys: false,
            error: nil
        )
    }
}
