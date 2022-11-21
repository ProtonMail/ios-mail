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

import GoLibs
import ProtonCore_Crypto
import XCTest

@testable import ProtonMail

class MailCryptoTests: XCTestCase {
    private var pgpPrivateKey: DecryptionKey!
    private var pgpPublicKey: ArmoredKey!
    private var expectedBody: String!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let pgpKeyPair = try MailCrypto.generateRandomKeyPair()
        pgpPrivateKey = DecryptionKey(
            privateKey: ArmoredKey(value: pgpKeyPair.privateKey),
            passphrase: Passphrase(value: pgpKeyPair.passphrase)
        )
        pgpPublicKey = ArmoredKey(value: pgpKeyPair.publicKey)
        expectedBody = OpenPGPTestsDefine.mime_decodedBody.rawValue!
    }

    override func tearDown() {
        pgpPrivateKey = nil
        pgpPublicKey = nil
        expectedBody = nil

        super.tearDown()
    }

    func testDecryptingSignedMessageWithoutVerifierKeysWorks() throws {
        let ciphertext = try prepareCiphertext(addPGPSignature: true, addEmbeddedMIMESignature: true)

        let decrypted = try MailCrypto().decryptMIME(
            encrypted: ciphertext,
            publicKeys: [],
            decryptionKeys: [pgpPrivateKey]
        )

        XCTAssertEqual(decrypted.body, expectedBody)
        XCTAssertEqual(decrypted.mimeType, "text/html")
        XCTAssertEqual(decrypted.attachments.count, 2)
        XCTAssertEqual(decrypted.signatureVerificationResult, .signatureVerificationSkipped)
    }

    func testSignatureVerificationSucceedsIfAtLeastOneSignatureChecksOut() throws {
        let ciphertext = try prepareCiphertext(addPGPSignature: true, addEmbeddedMIMESignature: true)

        let decrypted = try MailCrypto().decryptMIME(
            encrypted: ciphertext,
            publicKeys: [pgpPublicKey],
            decryptionKeys: [pgpPrivateKey]
        )

        XCTAssertEqual(decrypted.body, expectedBody)
        XCTAssertEqual(decrypted.mimeType, "text/html")
        XCTAssertEqual(decrypted.attachments.count, 2)
        XCTAssertEqual(decrypted.signatureVerificationResult, .success)
    }

    func testSignatureVerificationFailsIfProvidedKeysCannotVerifyNeitherOfThem() throws {
        let ciphertext = try prepareCiphertext(addPGPSignature: true, addEmbeddedMIMESignature: true)

        let differentPublicKey = try ArmoredKey(value: MailCrypto.generateRandomKeyPair().publicKey)

        let decrypted = try MailCrypto().decryptMIME(
            encrypted: ciphertext,
            publicKeys: [differentPublicKey],
            decryptionKeys: [pgpPrivateKey]
        )

        XCTAssertEqual(decrypted.body, expectedBody)
        XCTAssertEqual(decrypted.mimeType, "text/html")
        XCTAssertEqual(decrypted.attachments.count, 2)
        XCTAssertEqual(decrypted.signatureVerificationResult, .failure)
    }

    func testReturnsNotSignedIfThereIsNeitherPGPSignatureNorEmbeddedMIMESignature() throws {
        let ciphertext = try prepareCiphertext(addPGPSignature: false, addEmbeddedMIMESignature: false)

        let decrypted = try MailCrypto().decryptMIME(
            encrypted: ciphertext,
            publicKeys: [pgpPublicKey],
            decryptionKeys: [pgpPrivateKey]
        )

        XCTAssertEqual(decrypted.body, expectedBody)
        XCTAssertEqual(decrypted.mimeType, "text/html")
        XCTAssertEqual(decrypted.attachments.count, 2)
        XCTAssertEqual(decrypted.signatureVerificationResult, .messageNotSigned)
    }

    func testSignatureVerificationSkippedTrumpsMessageNotSignedIfThereAreNoSignaturesAndNoVerifierKeys() throws {
        let ciphertext = try prepareCiphertext(addPGPSignature: false, addEmbeddedMIMESignature: false)

        let decrypted = try MailCrypto().decryptMIME(
            encrypted: ciphertext,
            publicKeys: [],
            decryptionKeys: [pgpPrivateKey]
        )

        XCTAssertEqual(decrypted.body, expectedBody)
        XCTAssertEqual(decrypted.mimeType, "text/html")
        XCTAssertEqual(decrypted.attachments.count, 2)
        XCTAssertEqual(decrypted.signatureVerificationResult, .signatureVerificationSkipped)
    }

    func testDecryptionFailsIfNoPrivateKeysAreProvided() throws {
        let ciphertext = try prepareCiphertext(addPGPSignature: true, addEmbeddedMIMESignature: true)

        XCTAssertThrowsError(
            try MailCrypto().decryptMIME(
                encrypted: ciphertext,
                publicKeys: [],
                decryptionKeys: []
            )
        )
    }

    private func prepareCiphertext(addPGPSignature: Bool, addEmbeddedMIMESignature: Bool) throws -> String {
        let file: OpenPGPTestsDefine
        if addEmbeddedMIMESignature {
            file = .mime_testMessage_with_mime_sig
        } else {
            file = .mime_testMessage_without_mime_sig
        }

        let plaintext = try XCTUnwrap(file.rawValue)

        let armoredMessage: ArmoredMessage
        if addPGPSignature {
            armoredMessage = try Encryptor.encrypt(publicKey: pgpPublicKey, cleartext: plaintext, signerKey: pgpPrivateKey)
        } else {
            armoredMessage = try Encryptor.encrypt(publicKey: pgpPublicKey, cleartext: plaintext)
        }
        return armoredMessage.value
    }
}
