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

import Foundation
@testable import ProtonMail
import XCTest
import ProtonCore_DataModel

final class DataAttachmentDecryptionTests: XCTestCase {
    private let encryptedData = try! Data(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "dataPacket", withExtension: nil)!)
    private let keyPacket = try! Data(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "keyPacket", withExtension: nil)!)
    private let passphrase = try! String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "passphrase", withExtension: "txt")!)
    private let plainData = try! String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "plainData", withExtension: "txt")!)
    private let userKey = try! Data(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "userKey", withExtension: nil)!)

    func testDecryptionWithTokenAndSignature() throws {
        let case1Token = try! String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_token", withExtension: "txt")!)
        let case1Signature = try! String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_signature", withExtension: "txt")!)
        let case1AddressKey = try! String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1_addressKey", withExtension: "txt")!)

        let outData = try encryptedData.decryptAttachment(keyPackage: keyPacket, userKeys: [userKey], passphrase: passphrase, keys: [Key(keyID: "foo", privateKey: case1AddressKey, token: case1Token, signature: case1Signature)])
        let decryptedData = plainData.data(using: .utf8)!
        XCTAssertEqual(outData, decryptedData)
    }

    func testDecryptionWithTokenAndSignatureForged() throws {
        let case1bisToken = try! String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1bis_token", withExtension: "txt")!)
        let case1bisSignature = try! String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1bis_signature", withExtension: "txt")!)
        let case1bisAddressKey = try! String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1bis_forgedAddressKey", withExtension: "txt")!)
        let keyPacket1bis = try! Data(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1bis_keyPacket", withExtension: nil)!)
        let encryptedData1bis = try! Data(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case1bis_dataPacket", withExtension: nil)!)

        XCTAssertThrowsError(try encryptedData1bis.decryptAttachment(keyPackage: keyPacket1bis, userKeys: [userKey], passphrase: passphrase, keys: [Key(keyID: "foo", privateKey: case1bisAddressKey, token: case1bisToken, signature: case1bisSignature)]), "Should throw Crypto.CryptoError.verificationFailed Error", { error in
            if let error = error as? Crypto.CryptoError, case .verificationFailed = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Should throw Crypto.CryptoError.verificationFailed Error")
            }
        })
    }

    func testDecryptionWithoutTokenNorSignature() throws {
        let case3AddressKey = try! String(contentsOf: Bundle(for: DataAttachmentDecryptionTests.self).url(forResource: "case3_addressKey", withExtension: "txt")!)

        let outData = try encryptedData.decryptAttachment(keyPackage: keyPacket, userKeys: [userKey], passphrase: passphrase, keys: [Key(keyID: "foo", privateKey: case3AddressKey, token: nil, signature: nil)])
        let decryptedData = plainData.data(using: .utf8)!
        XCTAssertEqual(outData, decryptedData)
    }
}
