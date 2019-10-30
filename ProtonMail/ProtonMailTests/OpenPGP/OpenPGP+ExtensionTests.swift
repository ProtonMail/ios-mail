//
//  OpenPGP+ExtensionTests.swift
//  ProtonMailTests - Created on 06/11/2018.
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


import XCTest
@testable import ProtonMail

class OpenPGP_ExtensionTests: XCTestCase {

    func testGenerateRandomKeyPair() {
        let openPGP = PMNOpenPgp.createInstance()!
        do {
            let keypair = try openPGP.generateRandomKeypair()
            let message = "Bird is a word"
            
            let encrypted = openPGP.encryptMessageSingleKey(keypair.publicKey, plainText: message, privateKey: keypair.privateKey, passphras: keypair.passphrase, trim: false)
            XCTAssertNotEqual(message, encrypted)
            
            let decrypted = openPGP.decryptMessageSingleKey(encrypted, privateKey: keypair.privateKey, passphras: keypair.passphrase)
            XCTAssertEqual(message, decrypted)
        } catch _ {
            XCTFail()
        }
    }

}
