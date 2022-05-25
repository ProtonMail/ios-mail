//
//  CryptoTests+Message.swift
//  ProtonMail - Created on 09/12/19.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import UIKit
import XCTest
import Crypto
import ProtonCore_Crypto
@testable import ProtonMail

extension CryptoTests {
    func testMIMEDecryption() throws {
        let testMessage = OpenPGPTestsDefine.mime_testMessage.rawValue!
        let decodedBody = OpenPGPTestsDefine.mime_decodedBody.rawValue!

        let keyPair = try MailCrypto.generateRandomKeyPair()

        let ciphertext = try Crypto().encryptNonOptional(
            plainText: testMessage,
            publicKey: keyPair.publicKey
        )

        let crypto = MailCrypto()
        let decrypted = try crypto.decryptMIME(
            encrypted: ciphertext,
            keys: [(keyPair.privateKey, keyPair.passphrase)]
        )

        XCTAssertEqual(decrypted.body, decodedBody)
        XCTAssertEqual(decrypted.mimeType, "text/html")
        XCTAssertEqual(decrypted.attachments.count, 2)
    }
}
