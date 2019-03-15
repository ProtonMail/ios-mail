//
//  GoOpenPGPTests.swift
//  ProtonMailTests - Created on 5/7/18.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import XCTest
import Crypto

class GoOpenPGPTests: XCTestCase {
    let openpgp = CryptoPmCrypto()!
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test() {
        
        let ecdh_msg_bad_2 = """
-----BEGIN PGP MESSAGE-----
Version: ProtonMail
Comment: https://protonmail.com

wV4DtM+8giJEGNISAQhA2rYu8+B41rJi6Gsr4TVeKyDtI0KjhhlLZs891rCG
6X4wxNkxCuTJZax7gQZbDKh2kETK/RH75s9g7H/WV9kZ192NTGmMFiKiautH
c5BGRGxM0sDfAQZb3ZsAUORHKPP7FczMv5aMU2Ko7O2FHc06bMdnZ/ag7GMF
Bdl4EizttNTQ5sNCAdIXUoA8BJLHPgPiglnfTqqx3ynkBNMzfH46oKf08oJ+
6CAQhJdif67/iDX8BRtaKDICBpv3b5anJht7irOBqf9XX13SGkmqKYF3T8eB
W7ZV5EdCTC9KU+1BBPfPEi93F4OHsG/Jo80e5MDN24/wNxC67h7kUQiy3H4s
al+5mSAKcIfZJA4NfPJg9zSoHgfRNGI8Q7ao+c8CLPiefGcMsakNsWUdRyBT
SSLH3z/7AH4GxBvhDEEG3cZwmXzZAJMZmzTa+SrsxZzRpGB/aawyRntOWm8w
6Lq9ntq4S8suj/YK62dJpJxFl8xs+COngpMDvCexX9lYlh/r/y4JRQl06oUK
wv7trvi89TkK3821qHxr7XwI1Ncr2qDJVNlN4W+b6WFyLXnXaJAUMyZ/6inm
RR8BoR2KkEAku3Ne/G5QI51ktNJ7cCodeVOkZj8+iip1/AGyjxZCybq/N8rc
bpOWdMhJ6Hy+JzGNY1qNXcHJPw==
=99Fs
-----END PGP MESSAGE-----
"""
        
        let ecdh_dec_key_2 = """
-----BEGIN PGP PRIVATE KEY BLOCK-----
Version: OpenPGP.js v4.4.9
Comment: https://openpgpjs.org

xYYEXEg93hYJKwYBBAHaRw8BAQdAeoA+T4vr3P0hFFsbzJpgy7/ZnKCrlehr
Myk5QAsBYgf+CQMIQ76YL5sEx+Zgr7DLZ5fhQn1U9+8aLIQaIbaT51nEjEMD
7h6mrJmp7oIr4PyijsIU+0LasXh/qlNeVQVWSygDq9L4nXDEGQhlMq3oH1FN
NM07InBha292c2thdGVzdEBwcm90b25tYWlsLmNvbSIgPHBha292c2thdGVz
dEBwcm90b25tYWlsLmNvbT7CdwQQFgoAHwUCXEg93gYLCQcIAwIEFQgKAgMW
AgECGQECGwMCHgEACgkQp7+eOYEhwd6x5AD9E0LA62odFFDH76wjEYrPCvOH
cYM56/5ZqZoGPPmbE98BAKCz/SQ90tiCMmlLEDXGX+a1bi6ttozqrnSQigic
DI4Ix4sEXEg93hIKKwYBBAGXVQEFAQEHQPDXy2mDfbMKOpCBZB2Ic5bfoWGV
iXvCFMnTLRWfGHUkAwEIB/4JAwhxMnjHjyALomBWSsoYxxB6rj6JKnWeikyj
yjXZdZqdK5F+0rk4M0l7lF0wt5PhT2uMCLB7aH/mSFN1cz7sBeJl3w2soJsT
ve/fP/8NfzP0wmEEGBYIAAkFAlxIPd4CGwwACgkQp7+eOYEhwd5MWQEAp0E4
QTnEnG8lYXhOqnOw676oV2kEU6tcTj3DdM+cW/sA/jH3FQQjPf+mA/7xqKIv
EQr2Mx42THr260IFYp5E/rIA
=oA0b
-----END PGP PRIVATE KEY BLOCK-----
"""
        
        
        let openpgp = CryptoPmCrypto()!
        do {
            let clear = try openpgp.decryptMessage(ecdh_msg_bad_2, privateKey: ecdh_dec_key_2, passphrase: "12345")
            XCTAssertEqual(clear, "Tesssst<br><br><br>Sent from ProtonMail mobile<br><br><br>", "ecdh pgp message decrypt failed")
        } catch let error {
            XCTAssertNil(error)
            print(error.localizedDescription)
            XCTFail("should not have exception")
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            for _ in 0 ... 100 {
                let result = KeyCheckPassphrase(OpenPGPDefines.privateKey, OpenPGPDefines.passphrase)
                XCTAssertTrue(result, "checkPassphrase failed")
            }
        }
    }
    
    //MARK: - Test methods
    func testCheckPassphrase() {
        let result = KeyCheckPassphrase(OpenPGPDefines.privateKey, OpenPGPDefines.passphrase)
        XCTAssertTrue(result, "checkPassphrase failed")
    }
    
    func testEncryption() {
        self.measure {
            for _ in 0 ... 100 {
                do {
                    let out = try openpgp.encryptMessage("test", publicKey: OpenPGPDefines.publicKey, privateKey: "", passphrase: "", trim: true)
                    XCTAssertNotEqual(out, "")
                } catch _ {
                    XCTFail("should not have exception")
                }
            }
        }
    }
    
    func testUnarmed() {
        var error : NSError?
        let unArmorKey = ArmorUnarmor(OpenPGPDefines.publicKey, &error)
        XCTAssertNil(error)
        
        do {
            let encrypted = try openpgp.encryptMessageBinKey("test", publicKey: unArmorKey!, privateKey: "", passphrase: "", trim: true)
            XCTAssertNotEqual(encrypted, "")
        } catch _ {
            XCTFail("should not have exception")
        }
        
    }
    
    
    func testCryptoAttachmentProcessor() {
        let data = """
        This file, its contents, concepts, methods, behavior, and operation
        (collectively the "Software") are protected by trade secret, patent,
        and copyright laws. The use of the Software is governed by a license
        agreement. Disclosure of the Software to third parties, in any form,
        in whole or in part, is expressly prohibited except as authorized by
        the license agreement.
        """.data(using: .utf8)!
        let totalSize = data.count
        
        do {
            // encrypt
            let processor = try openpgp.encryptAttachmentLowMemory(totalSize, fileName: "testData", publicKey: OpenPGPDefines.publicKey)
            
            let chunkSize = 10
            var offset = 0
            while offset < totalSize {
                let currentChunkSize = offset + chunkSize > totalSize ? totalSize - offset : chunkSize
                let currentChunk = data.subdata(in: Range(uncheckedBounds: (lower: offset, upper: offset + currentChunkSize)))
                offset += currentChunkSize
                processor.process(currentChunk)
            }
            
            let result = try processor.finish()
            
            // decrypt
            let decrypted = try openpgp.decryptAttachment(result.keyPacket(), dataPacket: result.dataPacket(), privateKey: OpenPGPDefines.privateKey, passphrase: OpenPGPDefines.passphrase)
            
            // match
            XCTAssertEqual(data, decrypted)
        } catch {
            XCTFail("thrown")
        }
    }
    
//
//    func testInGeneral() {
//        let feng100_fingerprint = "F62F2E37580F4DFAD46200936DC999B146234F40".lowercased()
//        
//        // test feng 100 pub key fingerprint
//        var error : NSError? = nil
//        let out1 = PmGetFingerprint(OpenPGPDefines.public_key_feng100, &error)
//    
//        XCTAssertNil(error)
//        XCTAssertNotNil(out1)
//        XCTAssert(out1! == feng100_fingerprint)
//        error = nil
//        
//        // test unarmor key
//        let unArmorKey = PmUnArmor(OpenPGPDefines.public_key_feng100, &error)
//        XCTAssertNil(error)
//        XCTAssertNotNil(unArmorKey)
//        error = nil
//        
//        // test get fingerprint use unarmored key
//        let out2 = PmGetFingerprintBinKey(unArmorKey!, &error)
//        XCTAssertNil(error)
//        XCTAssertNotNil(out2)
//        XCTAssert(out2! == feng100_fingerprint)
//        error = nil
//        
//        // test encrypt use unarmored key
//        let encrypted = PmEncryptMessageBinKey("test", unArmorKey!,  "", "", true, &error)
//        XCTAssertNil(error)
//        XCTAssertNotNil(encrypted)
//        error = nil
//        
//        // test decrypt
//        let encrypted1 = PmEncryptMessage( "test", OpenPGPDefines.publicKey, "", "", true, &error)
//        XCTAssertNil(error)
//        XCTAssertNotNil(encrypted1)
//        error = nil
//        
//        // decrypt encrypted message
//        let clearText = PmDecryptMessage(encrypted1!, OpenPGPDefines.privateKey, OpenPGPDefines.passphrase, &error)
//        XCTAssertNil(error)
//        XCTAssertNotNil(clearText)
//        XCTAssertEqual(clearText!, "test")
//        error = nil
//        
//        // test bad key
//        let encrypted2 = PmEncryptMessage("test", OpenPGPDefines.publicKey, OpenPGPDefines.privateKey, "222", true, &error)
//        XCTAssertNotNil(error)
//        XCTAssertNil(encrypted2)
//        error = nil
//        
//        // test signe
//        let encrypted3 = PmEncryptMessage("test", OpenPGPDefines.publicKey,  OpenPGPDefines.privateKey, OpenPGPDefines.passphrase, true, &error)
//        XCTAssertNil(error)
//        XCTAssertNotNil(encrypted3)
//        error = nil
//        
//        let verifyOut = PmDecryptMessageVerify(encrypted3!, "", OpenPGPDefines.privateKey, OpenPGPDefines.passphrase, &error)
//        XCTAssertNil(error)
//        XCTAssertNotNil(verifyOut)
//        XCTAssertEqual("test", verifyOut?.plaintext()!)
//        XCTAssertEqual(true, verifyOut?.verify())
//        
//        // test armor fucntion
//        let outArmored = PmArmorKey(unArmorKey!, &error)
//        XCTAssertNil(error)
//        XCTAssertNotNil(outArmored)
//        XCTAssertEqual(outArmored!, OpenPGPDefines.public_key_feng100)
//        error = nil
//
//        
//        let modulus = PMNOpenPgp.createInstance()?.readClearsignedMessage(OpenPGPDefines.modulus)
//        let modulus1 = PmReadClearSignedMessage(OpenPGPDefines.modulus, &error)
//        
//        XCTAssertNil(error)
//        XCTAssertNotNil(modulus)
//        XCTAssertNotNil(modulus1)
//        error = nil
//       
//        XCTAssertEqual(modulus!, modulus1!)
//        
//    }
//    
//    func testPrintoutKey() {
//        var error : NSError? = nil
//        PmCheckKey(OpenPGPDefines.public_key_feng100, &error)
//    }
//    
//    
//    func testSign() {
//        var error : NSError? = nil
//        let encrypted = PmEncryptMessage( "test",
//                                          OpenPGPDefines.publicKey,
//                                          OpenPGPDefines.feng100_private_key_1,
//                                          OpenPGPDefines.feng100_passphrase_1, true, &error)
//        XCTAssertNil(error)
//        XCTAssertNotNil(encrypted)
//        error = nil
//        
//        let tempPubKey = PmPublicKey(OpenPGPDefines.feng100_private_key_1, &error)
//        XCTAssertNil(error)
//        XCTAssertNotNil(tempPubKey)
//        
//        let verifyOut = PmDecryptMessageVerify(encrypted!, tempPubKey!, OpenPGPDefines.privateKey, "123", &error)
//        XCTAssertNil(error)
//        XCTAssertNotNil(verifyOut)
//        XCTAssertEqual("test", verifyOut?.plaintext()!)
//        XCTAssertEqual(true, verifyOut?.verify())
//        error = nil
//        
//        let verifyOut1 = PmDecryptMessageVerify(encrypted!, "", OpenPGPDefines.privateKey, "123", &error)
//        XCTAssertNil(error)
//        XCTAssertNotNil(verifyOut1)
//        XCTAssertEqual("test", verifyOut1?.plaintext()!)
//        XCTAssertEqual(false, verifyOut1?.verify())
//        error = nil
//        
//        let verifyOut2 = PmDecryptMessageVerify(encrypted!, OpenPGPDefines.publicKey, OpenPGPDefines.privateKey, "123", &error)
//        XCTAssertNil(error)
//        XCTAssertNotNil(verifyOut2)
//        XCTAssertEqual("test", verifyOut1?.plaintext()!)
//        XCTAssertEqual(false, verifyOut1?.verify())
//        error = nil
//    }
//    
//    func testPrivatekey2Publickey () {
//        var error : NSError? = nil
//        let pubkey = PmPublicKey(OpenPGPDefines.feng100_private_key_1, &error)
//        XCTAssertNil(error)
//        XCTAssertNotNil(pubkey)
//        
//        let encrypted = PmEncryptMessage("test", pubkey!, "", "", true, &error)
//        XCTAssertNil(error)
//        XCTAssertNotNil(encrypted)
//        
//        let clear = PmDecryptMessage(encrypted!, OpenPGPDefines.feng100_private_key_1, OpenPGPDefines.feng100_passphrase_1, &error)
//        XCTAssertNil(error)
//        XCTAssertNotNil(clear)
//        
//        XCTAssertEqual(clear!, "test")
//        
//    }
//    
//    
//    func testEncryptAttachment() {
//        var error : NSError? = nil
//        let indata = "Testlaksdjfklsadf".data(using: .ascii)
//        
//        let spiled = PmEncryptAttachment(indata, "",OpenPGPDefines.publicKey, &error)
//        XCTAssertNil(error)
//        XCTAssertNotNil(spiled)
//    }
//    
//    func testTimeCache () {
//
//        let openPgp = PmOpenPGP()
//
//        let time1 = openPgp?.getTime()
//        
//        XCTAssertEqual(time1, 0)
//        
//        openPgp?.updateTime(100)
//        
//        let time2 = openPgp?.getTime()
//        
//        openPgp.verifybin
//        
//        XCTAssertEqual(time2, 100)
//    }
//    
}
