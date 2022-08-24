// Copyright (c) 2021 Proton AG
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
@testable import ProtonMail
import XCTest
import ProtonCore_Crypto
import ProtonCore_DataModel
import Crypto

final class DataAttachmentDecryptionTests: XCTestCase {
    private let encryptedData = try! Data(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "dataPacket", withExtension: nil)!)
    private let keyPacket = try! Data(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "keyPacket", withExtension: nil)!)
    private let passphrase = try! String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "passphrase", withExtension: "txt")!)
    private let plainData = try! String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "plainData", withExtension: "txt")!)
    private let userKey = try! Data(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "userKey", withExtension: nil)!)

    func testDecryptionWithTokenAndSignature() throws {
        let case1Token = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_token", withExtension: "txt")!)
        let case1Signature = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_signature", withExtension: "txt")!)
        let case1AddressKey = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_addressKey", withExtension: "txt")!)

        let outData = try encryptedData.decryptAttachment(keyPackage: keyPacket, userKeys: [userKey], passphrase: passphrase, keys: [Key(keyID: "foo", privateKey: case1AddressKey, token: case1Token, signature: case1Signature)])
        let decryptedData = plainData.data(using: .utf8)!
        XCTAssertEqual(outData, decryptedData)
    }

    func testFailedDecryptionShouldRethrowTheError() throws {
        let case1Token = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_token", withExtension: "txt")!)
        let case1Signature = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_signature", withExtension: "txt")!)
        let case1AddressKey = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_addressKey", withExtension: "txt")!)
        let attachmentDecryptor = AttachmentDecryptorMock(stubbedResult: .failure(CryptoError.attachmentCouldNotBeDecrypted))

        XCTAssertThrowsError(try encryptedData.decryptAttachment(keyPackage: keyPacket, userKeys: [userKey], passphrase: passphrase, keys: [Key(keyID: "foo", privateKey: case1AddressKey, token: case1Token, signature: case1Signature)], attachmentDecryptor: attachmentDecryptor), "Should throw CryptoError.attachmentCouldNotBeDecrypted Error", { error in
            if let error = error as? CryptoError, case .attachmentCouldNotBeDecrypted = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Should throw CryptoError.attachmentCouldNotBeDecrypted Error")
            }
        })
    }

    func testDecryptionWithTokenAndSignatureForgedThrowsVerificationFailedError() throws {
        let case1bisToken = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1bis_token", withExtension: "txt")!)
        let case1bisSignature = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1bis_signature", withExtension: "txt")!)
        let case1bisAddressKey = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1bis_forgedAddressKey", withExtension: "txt")!)
        let keyPacket1bis = try Data(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1bis_keyPacket", withExtension: nil)!)
        let encryptedData1bis = try Data(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1bis_dataPacket", withExtension: nil)!)

        XCTAssertThrowsError(try encryptedData1bis.decryptAttachment(keyPackage: keyPacket1bis, userKeys: [userKey], passphrase: passphrase, keys: [Key(keyID: "foo", privateKey: case1bisAddressKey, token: case1bisToken, signature: case1bisSignature)]), "Should throw Crypto.CryptoError.verificationFailed Error", { error in
            if let error = error as? MailCrypto.CryptoError, case .verificationFailed = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Should throw Crypto.CryptoError.verificationFailed Error")
            }
        })
    }

    func testDecryptionWithoutTokenNorSignature() throws {
        let case3AddressKey = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case3_addressKey", withExtension: "txt")!)

        let outData = try encryptedData.decryptAttachment(keyPackage: keyPacket, userKeys: [userKey], passphrase: passphrase, keys: [Key(keyID: "foo", privateKey: case3AddressKey, token: nil, signature: nil)])
        let decryptedData = plainData.data(using: .utf8)!
        XCTAssertEqual(outData, decryptedData)
    }

    func testVerifyDetachedSucceedsWithValidSignature() throws {
        let case1Token = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_token", withExtension: "txt")!)
        let case1Signature = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_signature", withExtension: "txt")!)
        let plainToken = try case1Token.decryptMessageNonOptional(binKeys: [userKey], passphrase: passphrase)
        let verification = try MailCrypto().verifyDetached(signature: case1Signature, plainText: plainToken, binKeys: [userKey], verifyTime: CryptoGetUnixTime())
        XCTAssertTrue(verification)
    }

    func testVerifyDetachedFailsWithInvalidSignature() throws {
        let case1bisToken = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1bis_token", withExtension: "txt")!)
        let case1bisSignature = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1bis_signature", withExtension: "txt")!)
        let plainToken = try case1bisToken.decryptMessageNonOptional(binKeys: [userKey], passphrase: passphrase)
        let verification = try MailCrypto().verifyDetached(signature: case1bisSignature, plainText: plainToken, binKeys: [userKey], verifyTime: CryptoGetUnixTime())
        XCTAssertFalse(verification)
    }

    func testBuildPublicKeyRing() throws {
        var error: NSError?
        guard let expectedKeyRing = CryptoNewKeyRing(nil, &error) else {
            XCTFail("Failed to build key ring")
            return
        }
        do {
            let keyToAdd = CryptoNewKey(userKey, &error)!
            if let error = error {
                throw error
            }
            let publicKeyData = try? keyToAdd.getPublicKey()
            var error: NSError?
            let publicKey = CryptoNewKey(publicKeyData, &error)
            if let error = error {
                throw error
            } else {
                try expectedKeyRing.add(publicKey)
            }
        } catch let error {
            throw error
        }
        let testedKeyRing = MailCrypto().buildPublicKeyRing(keys: [userKey])!
        XCTAssertEqual(expectedKeyRing.countEntities(), testedKeyRing.countEntities())
        for i in 0..<expectedKeyRing.countEntities() {
            XCTAssertEqual(try expectedKeyRing.getKey(i).getFingerprint(), try testedKeyRing.getKey(i).getFingerprint())
            XCTAssertFalse(try expectedKeyRing.getKey(i).isPrivate())
        }
    }

    func testGetAddressKeyPassphraseShouldReturnDefaultPassphraseWhenTokenIsNil() throws {
        let case1Signature = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_signature", withExtension: "txt")!)
        let case1AddressKey = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_addressKey", withExtension: "txt")!)
        let keyWithoutToken = Key(keyID: "foo", privateKey: case1AddressKey, token: nil, signature: case1Signature)
        let expectedPassphrase = passphrase
        let returnedPassphrase = try MailCrypto.getAddressKeyPassphrase(userKeys: [userKey], passphrase: expectedPassphrase, key: keyWithoutToken)
        XCTAssertEqual(expectedPassphrase, returnedPassphrase)
    }

    func testGetAddressKeyPassphraseShouldReturnDefaultPassphraseWhenSignatureIsNil() throws {
        let case1Token = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_token", withExtension: "txt")!)
        let case1AddressKey = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_addressKey", withExtension: "txt")!)
        let keyWithoutSignature = Key(keyID: "foo", privateKey: case1AddressKey, token: case1Token, signature: nil)
        let expectedPassphrase = passphrase
        let returnedPassphrase = try MailCrypto.getAddressKeyPassphrase(userKeys: [userKey], passphrase: expectedPassphrase, key: keyWithoutSignature)
        XCTAssertEqual(expectedPassphrase, returnedPassphrase)
    }

    func testGetAddressKeyPassphraseShouldReturnPlainTokenPassphraseWhenTokenAndSignatureAreRight() throws {
        let case1Token = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_token", withExtension: "txt")!)
        let case1Signature = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_signature", withExtension: "txt")!)
        let case1AddressKey = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_addressKey", withExtension: "txt")!)
        let fullkey = Key(keyID: "foo", privateKey: case1AddressKey, token: case1Token, signature: case1Signature)
        let expectedPassphrase = try case1Token.decryptMessageNonOptional(binKeys: [userKey], passphrase: passphrase)
        let returnedPassphrase = try MailCrypto.getAddressKeyPassphrase(userKeys: [userKey], passphrase: passphrase, key: fullkey)
        XCTAssertEqual(expectedPassphrase, returnedPassphrase)
    }

    func testGetAddressKeyPassphraseShouldThrowErrorIfWrongPassphraseIsSupplied() throws {
        let case1Token = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_token", withExtension: "txt")!)
        let case1Signature = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_signature", withExtension: "txt")!)
        let case1AddressKey = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_addressKey", withExtension: "txt")!)
        let key = Key(keyID: "foo", privateKey: case1AddressKey, token: case1Token, signature: case1Signature)

        XCTAssertThrowsError(
            try MailCrypto.getAddressKeyPassphrase(userKeys: [userKey], passphrase: "wrong passphrase", key: key),
            "Should throw Crypto.CryptoError.messageCouldNotBeDecrypted Error",
            { error in
                if let error = error as? CryptoError, case .messageCouldNotBeDecrypted = error {
                    XCTAssertTrue(true)
                } else {
                    XCTFail("Should throw Crypto.CryptoError.messageCouldNotBeDecrypted Error")
                }
            }
        )
    }

    func testGetAddressKeyPassphraseShouldThrowErrorWhenTokenHasWrongFormat() throws {
        let malformedToken = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "malformed_token", withExtension: "txt")!)
        let malformedSignature = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "malformed_signature", withExtension: "txt")!)
        let malformedAddressKey = try String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "malformed_addressKey", withExtension: "txt")!)
        let key = Key(keyID: "foo", privateKey: malformedAddressKey, token: malformedToken, signature: malformedSignature)

        XCTAssertThrowsError(
            try MailCrypto.getAddressKeyPassphrase(userKeys: [userKey], passphrase: passphrase, key: key),
            "Should throw Crypto.CryptoError.messageCouldNotBeDecrypted Error",
            { error in
                if let error = error as? CryptoError, case .messageCouldNotBeDecrypted = error {
                    XCTAssertTrue(true)
                } else {
                    XCTFail("Should throw Crypto.CryptoError.messageCouldNotBeDecrypted Error")
                }
            }
        )
    }

}

final class AttachmentDecryptorMock: AttachmentDecryptor {
    var stubbedResult: Result<Data, Error>

    init(stubbedResult: Result<Data, Error>) {
        self.stubbedResult = stubbedResult
    }

    func decryptAttachmentNonOptional(keyPacket: Data,
                                      dataPacket: Data,
                                      privateKey: String,
                                      passphrase: String) throws -> Data {
        try stubbedResult.get()
    }
}
