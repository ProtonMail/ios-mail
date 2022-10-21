//
//  CryptoTests.swift
//  Proton Mail - Created on 09/12/19.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_Crypto
@testable import ProtonMail
import UIKit
import XCTest

class CryptoTests: XCTestCase {
    func testGenerateRandomKeyPair() throws {
        let keyPair = try MailCrypto.generateRandomKeyPair()
        let privateKey = ArmoredKey(value: keyPair.privateKey)
        let publicKey = ArmoredKey(value: keyPair.publicKey)
        let passphrase = Passphrase(value: keyPair.passphrase)
        let message = "Hello my friend!"

        let encrypted = try Encryptor.encrypt(publicKey: publicKey, cleartext: message)
        let unwrappedEncrypted = try XCTUnwrap(encrypted)
        XCTAssertNotEqual(message, unwrappedEncrypted.value)

        let decrypted: String = try Decryptor.decrypt(
            decryptionKeys: [DecryptionKey(privateKey: privateKey, passphrase: passphrase)],
            encrypted: encrypted
        )
        XCTAssertEqual(message, decrypted)
    }
}
