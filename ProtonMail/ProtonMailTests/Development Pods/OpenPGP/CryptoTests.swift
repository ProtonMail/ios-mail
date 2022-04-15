//
//  CryptoTests.swift
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
import ProtonCore_Crypto
@testable import ProtonMail

class CryptoTests: XCTestCase {

    func testGenerateRandomKeyPair() throws {
        let keyPair = try MailCrypto.generateRandomKeyPair()
        let message = "Hello my friend!"

        let encrypted = try Crypto().encryptNonOptional(plainText: message, publicKey: keyPair.publicKey)
        let unwrappedEncrypted = try XCTUnwrap(encrypted)
        XCTAssertNotEqual(message, unwrappedEncrypted)

        let decrypted = try Crypto().decrypt(encrypted: unwrappedEncrypted, privateKey: keyPair.privateKey, passphrase: keyPair.passphrase)
        XCTAssertEqual(message, decrypted)
    }
}
