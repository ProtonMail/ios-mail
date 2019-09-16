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

@testable import ProtonMail

class GoOpenPGPTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEccDecrypt() {
        
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
        
        let pgp = Crypto()
        do {
            let clear = try pgp.decrypt(encrytped: ecdh_msg_bad_2, privateKey: ecdh_dec_key_2, passphrase: "12345")
            XCTAssertEqual(clear, "Tesssst<br><br><br>Sent from ProtonMail mobile<br><br><br>", "ecdh pgp message decrypt failed")
        } catch let error {
            XCTAssertNil(error)
            XCTFail("should not have exception")
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            for _ in 0 ... 100 {
                let result = OpenPGPDefines.privateKey.check(passphrase: OpenPGPDefines.passphrase)
                XCTAssertTrue(result, "checkPassphrase failed")
            }
        }
    }
    
    //MARK: - Test methods
    func testCheckPassphrase() {
        let result = OpenPGPDefines.privateKey.check(passphrase: OpenPGPDefines.passphrase)
        XCTAssertTrue(result, "checkPassphrase failed")
    }
    
    func testEncryption() {
        self.measure {
            for _ in 0 ... 100 {
                do {
                    let pgp = Crypto()
                    let out = try pgp.encrypt(plainText: "test", publicKey: OpenPGPDefines.publicKey)
                    XCTAssertNotEqual(out, "")
                } catch let error {
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }
    
    func testUnarmed() {
        var error : NSError?
        let unArmorKey = ArmorUnarmor(OpenPGPDefines.publicKey, &error)
        XCTAssertNil(error)
        
        do {
            let pgp = Crypto()
            let encrypted = try pgp.encrypt(plainText: "test", publicKey: unArmorKey!)
            XCTAssertNotEqual(encrypted, "")
        } catch _ {
            XCTFail("should not have exception")
        }
        
    }
    
    
    func testCryptoAttachmentProcessor() {
        let testData = """
        This file, its contents, concepts, methods, behavior, and operation
        (collectively the "Software") are protected by trade secret, patent,
        and copyright laws. The use of the Software is governed by a license
        agreement. Disclosure of the Software to third parties, in any form,
        in whole or in part, is expressly prohibited except as authorized by
        the license agreement.
        """
            
        let data = testData.data(using: .utf8)!
        let totalSize : Int = data.count
        do {
            let pgp = Crypto()
            // encrypt
            let processor = try pgp.encryptAttachmentLowMemory(fileName: "testData",
                                                               totalSize: totalSize,
                                                               publicKey: OpenPGPDefines.publicKey)
            let chunkSize : Int = 10
            var offset : Int = 0
            while offset < totalSize {
                let currentChunkSize = offset + chunkSize > totalSize ? totalSize - offset : chunkSize
                let currentChunk = data.subdata(in: Range(uncheckedBounds: (lower: offset, upper: offset + currentChunkSize)))
                offset += currentChunkSize
                processor.process(currentChunk)
            }
            
            let result = try processor.finish()
            guard let keyPacket = result.keyPacket,
                let dataPacket = result.dataPacket else {
                    XCTFail("can't be null")
                    return
            }
    
            // decrypt
            let decrypted = try pgp.decryptAttachment(keyPacket: keyPacket,
                                                      dataPacket: dataPacket,
                                                      privateKey: OpenPGPDefines.privateKey,
                                                      passphrase: OpenPGPDefines.passphrase)
            guard let clearData = decrypted else {
                 XCTFail("can't be null")
                 return
             }
            //match
            XCTAssertEqual(data, clearData)
        } catch let error {
            XCTFail("thrown" + "\(error.localizedDescription)")
        }
    }
    
    
    func testNewLib() {
//        let data = Data(repeating: 0, count: 8)
//        print("Data: \([UInt8](data))")
//        let bytes = MobileNewBytes(data)!
//        print("Elements: \([UInt8](bytes.getElements()!))")
//        print("Data: \([UInt8](data))")
//
        
        var data = Data(repeating: 0, count: 8)
        let mutableData = NSMutableData(bytes: &data, length: 8)
        print("Data: \(Array(UnsafeBufferPointer(start: mutableData.bytes.assumingMemoryBound(to: UInt8.self), count: 8)))")
        let bytes = MobileNewBytes(mutableData as Data)!
        print("Elements: \([UInt8](bytes.getElements()!))")
        print("Data: \([UInt8](data))")
    }
    
    
    func testAttachnentEncryptDecrypt() {
        let testAttachmentCleartext = "cc,\ndille."
        let privateKey =
"""
-----BEGIN PGP PRIVATE KEY BLOCK-----
Version: OpenPGP.js v0.7.1
Comment: http://openpgpjs.org

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
qqGRQm3MxoTdgQUShAwbNwNNQR9cInfMnA==
=2wIY
-----END PGP PRIVATE KEY BLOCK-----

"""
        let testMailboxPassword = "apple"
        do {
            let pgp = Crypto()
            let plainData = testAttachmentCleartext.data(using: String.Encoding.utf8)!
            // encrypt
            let encrypted = try pgp.encryptAttachment(plainData: plainData, fileName: "s.txt", publicKey: privateKey)
            XCTAssertNotNil(encrypted)
            guard let key = encrypted?.keyPacket,
                let data = encrypted?.dataPacket else {
                    XCTFail("can't be null")
                    return
            }
            // decrypt
            let decrypted = try pgp.decryptAttachment(keyPacket: key,
                                                      dataPacket: data,
                                                      privateKey: privateKey,
                                                      passphrase: testMailboxPassword)
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

    
    
    func testInGeneral() {
        let feng100_fingerprint = "F62F2E37580F4DFAD46200936DC999B146234F40".lowercased()

        // test feng 100 pub key fingerprint
        let out1 = OpenPGPDefines.public_key_feng100.fingerprint
        XCTAssertNotNil(out1)
        XCTAssert(out1 == feng100_fingerprint)
        
        // test unarmor key
        let unArmorKey = OpenPGPDefines.public_key_feng100.unArmor
        XCTAssertNotNil(unArmorKey)
        do {
            let encrypted = try Crypto().encrypt(plainText: "test", publicKey: unArmorKey!)
            XCTAssertNotNil(encrypted)
            // test decrypt
            let encrypted1 = try Crypto().encrypt(plainText: "test", publicKey: OpenPGPDefines.publicKey)
            XCTAssertNotNil(encrypted1)
            
            // decrypt encrypted message
            let clearText = try Crypto().decrypt(encrytped: encrypted1!, privateKey: OpenPGPDefines.privateKey, passphrase: OpenPGPDefines.passphrase)
            XCTAssertNotNil(clearText)
            XCTAssertEqual(clearText, "test")
            
            // test bad key
            do {
                let _ = try Crypto().encrypt(plainText: "test",
                                                      publicKey: OpenPGPDefines.publicKey,
                                                      privateKey: OpenPGPDefines.privateKey, passphrase: "222")
                XCTFail("should have exception")
            } catch {
                
            }
            
            // test signe
            let encrypted3 = try Crypto().encrypt(plainText: "test",
                                                  publicKey: OpenPGPDefines.publicKey,
                                                  privateKey: OpenPGPDefines.privateKey, passphrase: OpenPGPDefines.passphrase)
            XCTAssertNotNil(encrypted3)

            
            let verifyOut = try Crypto().decryptVerify(encrytped: encrypted3!,
                                                       publicKey: OpenPGPDefines.privateKey.unArmor!,
                                                       privateKey: OpenPGPDefines.privateKey,
                                                       passphrase: OpenPGPDefines.passphrase, verifyTime: 0)
            XCTAssertNotNil(verifyOut)
            XCTAssertEqual("test", verifyOut!.message?.getString())
            //            print(verifyOut!.signatureVerificationError)
            //            XCTAssertEqual(0, verifyOut!.signatureVerificationError?.status)
            
            var error : NSError? = nil
            let modulus = PMNOpenPgp.createInstance()?.readClearsignedMessage(OpenPGPDefines.modulus)
            let modulus1 = CryptoNewClearTextMessageFromArmored(OpenPGPDefines.modulus, &error)
            XCTAssertNil(error)
            XCTAssertNotNil(modulus)
            XCTAssertNotNil(modulus1)
            error = nil
            XCTAssertEqual(modulus!, modulus1!.getString())
            
        } catch let error {
            XCTFail("thrown" + "\(error.localizedDescription)")
        }
        
    }
//    
//    func testSign() {
//        do {
//            let pgp = CryptoGetGopenPGP()!
//            let encrypted = try Crypto().encrypt(plainText: "test", publicKey: OpenPGPDefines.publicKey,
//                                                 privateKey: OpenPGPDefines.feng100_private_key_1,
//                                                 passphrase: OpenPGPDefines.feng100_passphrase_1)
//            XCTAssertNotNil(encrypted)
//            let tempPubKey = OpenPGPDefines.feng100_private_key_1.publicKey
//            XCTAssertNotNil(tempPubKey)
//            
//            let verifyOut = try Crypto().decryptVerify(encrytped: encrypted!,
//                                                   publicKey: tempPubKey,
//                                                   privateKey: OpenPGPDefines.privateKey,
//                                                   passphrase: "123", verifyTime: pgp.getUnixTime())
////            let verifyOut = PmDecryptMessageVerify(encrypted!, tempPubKey!, OpenPGPDefines.privateKey, "123", &error)
//            XCTAssertNotNil(verifyOut)
//            XCTAssertNotNil(verifyOut!.message)
//            XCTAssertNotNil(verifyOut!.signatureVerificationError)
//            XCTAssertEqual("test", verifyOut!.message!.getString())
//            XCTAssertEqual(0, verifyOut!.signatureVerificationError!.status)
//            
//            
////            let verifyOut1 = PmDecryptMessageVerify(encrypted!, "", OpenPGPDefines.privateKey, "123", &error)
////            XCTAssertNil(error)
////            XCTAssertNotNil(verifyOut1)
////            XCTAssertEqual("test", verifyOut1?.plaintext()!)
////            XCTAssertEqual(false, verifyOut1?.verify())
////            error = nil
////
////            let verifyOut2 = PmDecryptMessageVerify(encrypted!, OpenPGPDefines.publicKey, OpenPGPDefines.privateKey, "123", &error)
////            XCTAssertNil(error)
////            XCTAssertNotNil(verifyOut2)
////            XCTAssertEqual("test", verifyOut1?.plaintext()!)
////            XCTAssertEqual(false, verifyOut1?.verify())
////            error = nil
//        } catch let error {
//            XCTFail("thrown" + "\(error.localizedDescription)")
//        }
//        
//        
//    }
//    
    func testPrivatekey2Publickey () {
        do {
            let pubkey = OpenPGPDefines.feng100_private_key_1.publicKey
            XCTAssertNotNil(pubkey)
            
            let encrypted = try Crypto().encrypt(plainText: "test", publicKey: pubkey)
            XCTAssertNotNil(encrypted)

            let clear = try Crypto().decrypt(encrytped: encrypted!,
                                         privateKey: OpenPGPDefines.feng100_private_key_1,
                                         passphrase: OpenPGPDefines.feng100_passphrase_1)
            XCTAssertNotNil(clear)
            
            XCTAssertEqual(clear, "test")
        } catch let error {
            XCTFail("thrown" + "\(error.localizedDescription)")
        }
    }

    func testTimeCache () {
        let openPgp = CryptoGetGopenPGP()!
        let time = Date().timeIntervalSince1970
        let time1 = openPgp.getUnixTime()
        XCTAssertEqual(time1 , Int64(time))
        let openPgp1 = CryptoGetGopenPGP()!
        openPgp1.updateTime(100)
        let openPgp2 = CryptoGetGopenPGP()!
        let time2 = openPgp2.getUnixTime()
        XCTAssertEqual(100 , time2)
    }
    
}
