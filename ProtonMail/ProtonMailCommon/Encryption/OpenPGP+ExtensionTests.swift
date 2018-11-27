//
//  OpenPGP+ExtensionTests.swift
//  ProtonMailTests
//
//  Created by Anatoly Rosencrantz on 06/11/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

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
