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
import Crypto
@testable import ProtonMail

class CryptoTests: XCTestCase {
    
    let testMailboxPassword = "apple"
    let testPublicKey =
"""
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: OpenPGP.js v0.7.1
Comment: http://openpgpjs.org

xsBNBFRJbc0BCAC0mMLZPDBbtSCWvxwmOfXfJkE2+ssM3ux21LhD/bPiWefE
WSHlCjJ8PqPHy7snSiUuxuj3f9AvXPvg+mjGLBwu1/QsnSP24sl3qD2onl39
vPiLJXUqZs20ZRgnvX70gjkgEzMFBxINiy2MTIG+4RU8QA7y8KzWev0btqKi
MeVa+GLEHhgZ2KPOn4Jv1q4bI9hV0C9NUe2tTXS6/Vv3vbCY7lRR0kbJ65T5
c8CmpqJuASIJNrSXM/Q3NnnsY4kBYH0s5d2FgbASQvzrjuC2rngUg0EoPsrb
DEVRA2/BCJonw7aASiNCrSP92lkZdtYlax/pcoE/mQ4WSwySFmcFT7yFABEB
AAHNBlVzZXJJRMLAcgQQAQgAJgUCVEltzwYLCQgHAwIJED62JZ7fId8kBBUI
AgoDFgIBAhsDAh4BAAD0nQf9EtH9TC0JqSs8q194Zo244jjlJFM3EzxOSULq
0zbywlLORfyoo/O8jU/HIuGz+LT98JDtnltTqfjWgu6pS3ZL2/L4AGUKEoB7
OI6oIdRwzMc61sqI+Qpbzxo7rzufH4CiXZc6cxORUgL550xSCcqnq0q1mds7
h5roKDzxMW6WLiEsc1dN8IQKzC7Ec5wA7U4oNGsJ3TyI8jkIs0IhXrRCd26K
0TW8Xp6GCsfblWXosR13y89WVNgC+xrrJKTZEisc0tRlneIgjcwEUvwfIg2n
9cDUFA/5BsfzTW5IurxqDEziIVP0L44PXjtJrBQaGMPlEbtP5i2oi3OADVX2
XbvsRc7ATQRUSW3PAQgAkPnu5fps5zhOB/e618v/iF3KiogxUeRhA68TbvA+
xnFfTxCx2Vo14aOL0CnaJ8gO5yRSqfomL2O1kMq07N1MGbqucbmc+aSfoElc
+Gd5xBE/w3RcEhKcAaYTi35vG22zlZup4x3ElioyIarOssFEkQgNNyDf5AXZ
jdHLA6qVxeqAb/Ff74+y9HUmLPSsRU9NwFzvK3Jv8C/ubHVLzTYdFgYkc4W1
Uug9Ou08K+/4NEMrwnPFBbZdJAuUjQz2zW2ZiEKiBggiorH2o5N3mYUnWEmU
vqL3EOS8TbWo8UBIW3DDm2JiZR8VrEgvBtc9mVDUj/x+5pR07Fy1D6DjRmAc
9wARAQABwsBfBBgBCAATBQJUSW3SCRA+tiWe3yHfJAIbDAAA/iwH/ik9RKZM
B9Ir0x5mGpKPuqhugwrc3d04m1sOdXJm2NtD4ddzSEvzHwaPNvEvUl5v7FVM
zf6+6mYGWHyNP4+e7RtwYLlRpud6smuGyDSsotUYyumiqP6680ZIeWVQ+a1T
ThNs878mAJy1FhvQFdTmA8XIC616hDFpamQKPlpoO1a0wZnQhrPwT77HDYEE
a+hqY4Jr/a7ui40S+7xYRHKL/7ZAS4/grWllhU3dbNrwSzrOKwrA/U0/9t73
8Ap6JL71YymDeaL4sutcoaahda1pTrMWePtrCltz6uySwbZs7GXoEzjX3EAH
+6qhkUJtzMaE3YEFEoQMGzcDTUEfXCJ3zJw=
=yT9U
-----END PGP PUBLIC KEY BLOCK-----
"""
    let testPrivateKey =
"""
-----BEGIN PGP PRIVATE KEY BLOCK-----
Version: OpenPGP.js v0.7.1
Comment: http://openpgpjs.org

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
qqGRQm3MxoTdgQUShAwbNwNNQR9cInfMnA==
=2wIY
-----END PGP PRIVATE KEY BLOCK-----

"""
    let testEncodedSessionKey = "ExXmnSiQ2QCey20YLH6qlLhkY3xnIBC1AwlIXwK/HvY="
    
    func testAttachmentGetKey() {
        let keyPacket = "wcBMA0fcZ7XLgmf2AQgAiRsOlnm1kSB4/lr7tYe6pBsRGn10GqwUhrwU5PMKOHdCgnO12jO3y3CzP0Yl/jGhAYja9wLDqH8X0sk3tY32u4Sb1Qe5IuzggAiCa4dwOJj5gEFMTHMzjIMPHR7A70XqUxMhmILye8V4KRm/j4c1sxbzA1rM3lYBumQuB5l/ck0Kgt4ZqxHVXHK5Q1l65FHhSXRj8qnunasHa30TYNzP8nmBA8BinnJxpiQ7FGc2umnUhgkFtjm5ixu9vyjr9ukwDTbwAXXfmY+o7tK7kqIXJcmTL6k2UeC6Mz1AagQtRCRtU+bv/3zGojq/trZo9lom3naIeQYa36Ketmcpj2Qwjg=="
        do {
            let crypto = Crypto()
            let keyPacketData: Data = keyPacket.decodeBase64()
            
            guard let symetricKey = try crypto.getSession(keyPacket: keyPacketData, privateKey: self.testPrivateKey, passphrase: testMailboxPassword) else {
                XCTFail("symetricKey can't be nil")
                return
            }
            XCTAssertEqual(symetricKey.algo, "aes256")
            XCTAssertEqual(symetricKey.key?.base64EncodedString(), self.testEncodedSessionKey)
        } catch let error {
            XCTFail("thrown" + "\(error.localizedDescription)")
        }
    }
    
    func testAttachmentGetKeyWithBinaryPrivateKey() {
        let keyPacket = "wcBMA0fcZ7XLgmf2AQgAiRsOlnm1kSB4/lr7tYe6pBsRGn10GqwUhrwU5PMKOHdCgnO12jO3y3CzP0Yl/jGhAYja9wLDqH8X0sk3tY32u4Sb1Qe5IuzggAiCa4dwOJj5gEFMTHMzjIMPHR7A70XqUxMhmILye8V4KRm/j4c1sxbzA1rM3lYBumQuB5l/ck0Kgt4ZqxHVXHK5Q1l65FHhSXRj8qnunasHa30TYNzP8nmBA8BinnJxpiQ7FGc2umnUhgkFtjm5ixu9vyjr9ukwDTbwAXXfmY+o7tK7kqIXJcmTL6k2UeC6Mz1AagQtRCRtU+bv/3zGojq/trZo9lom3naIeQYa36Ketmcpj2Qwjg=="
        do {
            var error: NSError?
            let crypto = Crypto()
            let keyPacketData: Data = keyPacket.decodeBase64()
            
            let binaryPrivateKey = ArmorUnarmor(self.testPrivateKey, &error)
            XCTAssertNil(error)
            
            let privateKeys: [Data] = ["WrongKey".data(using: .utf8)!, binaryPrivateKey!]
            
            guard let symetricKey = try crypto.getSession(keyPacket: keyPacketData, privateKeys: privateKeys, passphrase: testMailboxPassword) else {
                XCTFail("symetricKey can't be nil")
                return
            }
            XCTAssertEqual(symetricKey.algo, "aes256")
            XCTAssertEqual(symetricKey.key?.base64EncodedString(), self.testEncodedSessionKey)
        } catch let error {
            XCTFail("thrown" + "\(error.localizedDescription)")
        }
    }

    func testAttachmentSetKey() {
        do {
            let key: Data = self.testEncodedSessionKey.decodeBase64()
            guard let keyPacket = try key.getKeyPackage(publicKey: self.testPublicKey, algo: "aes256") else {
                XCTFail("keyPacket can't be nil")
                return
            }
            
            guard let symetricKey = try Crypto().getSession(keyPacket: keyPacket,
                                                            privateKey: self.testPrivateKey,
                                                            passphrase: self.testMailboxPassword) else {
                XCTFail("symetricKey can't be nil")
                return
            }
            
            XCTAssertEqual(symetricKey.algo, "aes256")
            XCTAssertEqual(symetricKey.key?.base64EncodedString(), self.testEncodedSessionKey)
        } catch let error {
            XCTFail("thrown" + "\(error.localizedDescription)")
        }
    }
    
    func testAttachmentEncryptDecrypt() {
        let testAttachmentCleartext = "cc,\ndille."
        do {
            let crypto = Crypto()
            let plainData = testAttachmentCleartext.data(using: String.Encoding.utf8)!
            // encrypt
            let encrypted = try crypto.encryptAttachment(plainData: plainData, fileName: "s.txt", publicKey: self.testPublicKey)
            XCTAssertNotNil(encrypted)
            guard let key = encrypted?.keyPacket,
                let data = encrypted?.dataPacket else {
                    XCTFail("can't be null")
                    return
            }
            // decrypt
            let decrypted = try crypto.decryptAttachment(keyPacket: key,
                                                      dataPacket: data,
                                                      privateKey: self.testPrivateKey,
                                                      passphrase: self.testMailboxPassword)
            guard let clearData = decrypted else {
                XCTFail("can't be null")
                return
            }
            let clearText = NSString(data: clearData, encoding: String.Encoding.utf8.rawValue)! as String
            //match
            XCTAssertEqual(testAttachmentCleartext, clearText)
        } catch let error {
            XCTFail("thrown" + "\(error.localizedDescription)")
        }
    }
    
    func testAttachmentEncrypt() {
        let testAttachmentCleartext = "cc,\ndille."
        do {
            let crypto = Crypto()
            let plainData = testAttachmentCleartext.data(using: String.Encoding.utf8)!
            // encrypt
            guard let encrypted = try crypto.encryptAttachment(plainData: plainData, fileName: "s.txt", publicKey: self.testPublicKey) else {
                return XCTFail("can't be null")
            }
            guard let _ = encrypted.keyPacket, let _ = encrypted.dataPacket else {
                return XCTFail("can't be null")
            }
            guard let encryptedData = encrypted.getBinary() else {
                return XCTFail("can't be null")
            }
            // decrypt
            let decrypted = try crypto.decrypt(encrytped: encryptedData, privateKey: self.testPrivateKey, passphrase: self.testMailboxPassword)
            //match
            XCTAssertEqual(testAttachmentCleartext, decrypted)
        } catch let error {
            XCTFail("thrown" + "\(error.localizedDescription)")
        }
    }

    func testAttachmentDecrypt() {
        let testAttachmentCleartext = "cc,\ndille."
        
        //The function CryptoNewPlainMessageFromString will normalize the text input of "\n" into "\r\n".
        let textAttachmentClearTestAfterNormalization = "cc,\r\ndille."
        do {
            let crypto = Crypto()
            // encrypt
            guard let encrypted = try crypto.encrypt(plainText: testAttachmentCleartext, publicKey: self.testPublicKey) else {
                return XCTFail("can't be null")
            }

            // decrypt
            let decrypted = try crypto.decryptAttachment(encrypted: encrypted, privateKey:  self.testPrivateKey, passphrase: self.testMailboxPassword)
            guard let clearData = decrypted else {
                XCTFail("can't be null")
                return
            }
            let clearText = NSString(data: clearData, encoding: String.Encoding.utf8.rawValue)! as String
            //match
            XCTAssertEqual(textAttachmentClearTestAfterNormalization, clearText)
        } catch let error {
            XCTFail("thrown" + "\(error.localizedDescription)")
        }
    }
    
    func testAttachmentDecryptionWithBinaryKey() {
        let testAttachmentCleartext = "cc,\ndille."
        do {
            var error: NSError?
            let crypto = Crypto()
            // encrypt
            let plainData = testAttachmentCleartext.data(using: String.Encoding.utf8)!
            guard let encrypted = try crypto.encryptAttachment(plainData: plainData, fileName: "s.txt", publicKey: self.testPublicKey) else {
                return XCTFail("can't be null")
            }
            
            XCTAssertNotNil(encrypted.keyPacket)
            XCTAssertNotNil(encrypted.dataPacket)
            
            let binaryPrivateKey = ArmorUnarmor(self.testPrivateKey, &error)
            XCTAssertNil(error)
            
            let wrongPrivateKey = ArmorUnarmor(OpenPGPDefines.feng100_private_key_1, &error)
            XCTAssertNil(error)
            let privateKeyArray: [Data] = ["WrongKey".data(using: .utf8)!, wrongPrivateKey!, binaryPrivateKey!]

            // decrypt
            let decrypted = try crypto.decryptAttachment(keyPacket: encrypted.keyPacket!, dataPacket: encrypted.dataPacket!, privateKey: privateKeyArray, passphrase: self.testMailboxPassword)
            guard let clearData = decrypted else {
                XCTFail("can't be null")
                return
            }
            let clearText = NSString(data: clearData, encoding: String.Encoding.utf8.rawValue)! as String
            //match
            XCTAssertEqual(testAttachmentCleartext, clearText)
        } catch let error {
            XCTFail("thrown" + "\(error.localizedDescription)")
        }
    }
    
    func testUpdatePassphrase() {
        let newPassphrase = "NewPassphrase"
        do {
            let keyWithNewPassphrase = try Crypto.updatePassphrase(privateKey: self.testPrivateKey, oldPassphrase: self.testMailboxPassword, newPassphrase: newPassphrase)
            XCTAssertNotNil(keyWithNewPassphrase)
            
            var error: NSError?
            let key = CryptoNewKeyFromArmored(keyWithNewPassphrase, &error)
            XCTAssertNil(error)
            XCTAssertNotNil(key)
            
            let passSlic = newPassphrase.data(using: .utf8)!
            let unlocked = try key?.unlock(passSlic)
            
            XCTAssertNotNil(unlocked)
            
            var result: ObjCBool = true
            try unlocked?.isLocked(&result)
            let isUnlock = !result.boolValue
            
            XCTAssertTrue(isUnlock)
            
        } catch {
            XCTFail("Should not throw error")
        }
    }

}
