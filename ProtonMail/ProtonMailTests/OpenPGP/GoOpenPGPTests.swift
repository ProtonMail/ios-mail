//
//  GoOpenPGPTests.swift
//  ProtonMailTests
//
//  Created by Yanfeng Zhang on 5/7/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

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
