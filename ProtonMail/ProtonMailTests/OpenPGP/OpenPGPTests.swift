//
//  OpenPGPTests.swift
//  ProtonMailTests
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


import Foundation

import XCTest
import Crypto

class OpenPGPTests: XCTestCase {
    
    //MARK: - Test methods
    func testCheckPassphrase() {
        let result = PMNOpenPgp.checkPassphrase(OpenPGPDefines.privateKey,
                                   passphrase: OpenPGPDefines.passphrase)
        XCTAssertTrue(result, "checkPassphrase failed")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            for _ in 0 ... 100 {
                let result = PMNOpenPgp.checkPassphrase(OpenPGPDefines.privateKey,
                                                        passphrase: OpenPGPDefines.passphrase)
                XCTAssertTrue(result, "checkPassphrase failed")
            }
        }
    }
    
    let openPGP = PMNOpenPgp.createInstance()
    func testEncryption() {
        self.measure {
            for _ in 0 ... 10 {
                let out = openPGP?.encryptMessageSingleKey(OpenPGPDefines.publicKey,
                                                           plainText: "test",
                                                           privateKey: "",
                                                           passphras: "",
                                                           trim: false)
                
                
                XCTAssertNotNil(out)
            }
        }
    }
    
    func testCheckPassphraseBad() {
//        let badPassphrase = "badPassphrase"
//        var error: NSError?
//        let result = OpenPGP().checkPassphrase(badPassphrase, forPrivateKey: privateKey, publicKey: publicKey, error: &error)
//        
//        XCTAssertFalse(result, "badPassphrase should fail.")
//        XCTAssertEqual(error!.domain, OpenPGPErrorDomain, "bad error domain")
//        XCTAssertEqual(error!.code, OpenPGP.ErrorCode.badPassphrase.rawValue, "wrong error code")
    }
    
//    func testDecryptWithPrivateKey() {
//        let encryptedText = cleartext.encryptWithPublicKey(publicKey, error: nil)
//
//        var error: NSError?
//        let decryptedText = encryptedText!.decryptWithPrivateKey(privateKey, passphrase: passphrase, publicKey: publicKey, error: &error)
//        XCTAssertNotNil(decryptedText, "decryptWithPrivateKey failed with error: \(error)")
//
//        if let decryptedText = decryptedText {
//            XCTAssertEqual(decryptedText, cleartext, "decryptedText does not match cleartext")
//        }
//    }
//
//    func testEncryptWithPublicKey() {
//        var error: NSError?
//        let encryptedText = cleartext.encryptWithPublicKey(self.publicKey, error: &error)
//        XCTAssertNotNil(encryptedText, "encryptWithPublicKey failed with error: \(error)")
//    }
//
//    func testGenerateKeyPair()
//    {
//        var error: NSError?
//        let new_key_pairs = OpenPGP().generateKey("123", userName: "test_user_name", error: &error)
//        XCTAssertNotNil(new_key_pairs, "new key pair failed with error: \(error)")
//        let pub = new_key_pairs?.objectForKey("public") as? String;
//        XCTAssertNotNil(pub, "new key pair -- public key failed with error: \(error)")
//        let priv = new_key_pairs?.objectForKey("private") as? String;
//        XCTAssertNotNil(priv, "new key pair -- private key failed with error: \(error)")
//    }
//
//    func testUpdateKeyPassphrase()
//    {
//        var error: NSError?
//        let new_passphrase : String = "321";
//
//        let new_private_key = OpenPGP().updatePassphrase(privateKey, publicKey: publicKey, old_pass: passphrase, new_pass: new_passphrase, error: &error)
//        XCTAssertNotNil(new_private_key, "update key passphrase failed with error: \(error)")
//
//        let badPassphrase = "123"
//        var result = OpenPGP().checkPassphrase(badPassphrase, forPrivateKey: new_private_key!, publicKey: publicKey, error: &error)
//        XCTAssertFalse(result, "badPassphrase should fail.")
//        XCTAssertEqual(error!.domain, OpenPGPErrorDomain, "bad error domain")
//        XCTAssertEqual(error!.code, OpenPGP.ErrorCode.badPassphrase.rawValue, "wrong error code")
//
//        result = OpenPGP().checkPassphrase(new_passphrase, forPrivateKey: new_private_key!, publicKey: publicKey, error: &error)
//        XCTAssertTrue(result, "badPassphrase should fail.")
//    }
//
//    func testEncryptDecryptAES()
//    {
//        var error: NSError?
//        let test_password : String = "123";
//        let original_text :String = "<div>lajflkjasklfjlksdfkl</div><div><br></div><div>Sent from iPhone <a href=\"https://protonmail.ch\">ProtonMail</a>, encrypted email based in Switzerland.<br></div>"
//        let test_aes_str : String = "-----BEGIN PGP MESSAGE-----\nVersion: OpenPGP.js v0.10.1-IE\nComment: http://openpgpjs.org\n\nww0ECQMIina34sp8Nlpg0sAbAc/x6pR8h57OJv9pklLuEc/aH5lFT9OpWS+N\n7oPaJCGK1f3aQV7g5V5INlUvwICeDiSkDMo+hHGtFgDFEwgNiMDc7wAtod1U\nZ5PTHegr8KWWmBiDIYuPVFJH8mALVcQen9MI1xFSYO8RvSxM/P6dJPzrVZQK\noIRW98dxMjJqMWW9HgqWCej6TRDua65r/X7Ucco9tWpwzmQCnvJLqpcYYrEk\ngcGyXsp3RvISG6pWh8ZFemeO6yoqnphYmcAa/i4h4CiMqKDDJuOg4UdpW46U\nGoNSV+C4hz5ymRDj\n=hUe3\n-----END PGP MESSAGE-----"
//        let plain_text = test_aes_str.decryptWithPassphrase(test_password, error: &error)
//        XCTAssertNotNil(plain_text, "decryptWithPassphrase failed with error: \(error)")
//        XCTAssertEqual(plain_text!, original_text, "decryptedText does not match cleartext")
//
//
//        let new_enc_msg = original_text.encryptWithPassphrase(test_password, error: &error)
//        XCTAssertNotNil(new_enc_msg, "encryptWithPassphrase failed with error: \(error)")
//
//        let new_dec_msg = new_enc_msg?.decryptWithPassphrase(test_password, error: &error)
//        XCTAssertNotNil(new_dec_msg, "decryptWithPassphrase failed with error: \(error)")
//
//        XCTAssertEqual(new_dec_msg!, original_text, "decryptedText does not match cleartext")
//
//
//        let bad_msg = new_enc_msg?.decryptWithPassphrase("bad_pwd", error: &error)
//        XCTAssertTrue(bad_msg == nil, "decryptWithPassphrase badPassphrase should fail.")
//        XCTAssertEqual(error!.domain, OpenPGPErrorDomain, "bad error domain")
//        XCTAssertEqual(error!.code, OpenPGP.ErrorCode.badPassphrase.rawValue, "wrong error code")
//
//    }
    
    
//
//
//    // MARK: - Performance tests
//
//    func testPerformanceEncryptMessage() {
//        self.measureBlock() {
//            var error: NSError?
//
//            let encryptedMessage = self.cleartext.encryptWithPublicKey(self.publicKey, error: &error)
//            XCTAssertNotNil(encryptedMessage, "encryptedMessage is nil")
//        }
//    }
//
//    func testPerformanceDecryptMessage() {
//        var error: NSError?
//        let encryptedMessage = self.cleartext.encryptWithPublicKey(self.publicKey, error: &error)
//        XCTAssertNotNil(encryptedMessage, "encryptedMessage is nil")
//
//        self.measureBlock() {
//            let decryptedText = encryptedMessage?.decryptWithPrivateKey(self.privateKey, passphrase: self.passphrase, publicKey: self.publicKey, error: &error)
//            XCTAssertNotNil(decryptedText, "decryptWithPrivateKey failed with error: \(error)")
//        }
//    }
}
