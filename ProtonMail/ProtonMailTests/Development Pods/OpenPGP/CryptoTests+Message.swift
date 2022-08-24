//
//  CryptoTests+Message.swift
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

import Crypto
import ProtonCore_Crypto
@testable import ProtonMail
import UIKit
import XCTest

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
