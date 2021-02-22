//
//  CryptoTests+Signature.swift
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


extension CryptoTests {
    //const signedPlainText = "Signed message\n"
    //const testTime = 1557754627 // 2019-05-13T13:37:07+00:00
    //
    //var signingKeyRing *KeyRing
    //var textSignature, binSignature *PGPSignature
    //var message *PlainMessage
    //var signatureTest = regexp.MustCompile("(?s)^-----BEGIN PGP SIGNATURE-----.*-----END PGP SIGNATURE-----$")
    //var signedMessageTest = regexp.MustCompile(
    //    "(?s)^-----BEGIN PGP SIGNED MESSAGE-----.*-----BEGIN PGP SIGNATURE-----.*-----END PGP SIGNATURE-----$")
    
    func testSignTextDetached() {
        let signedPlainText = "Signed message\n"
        let signatureRegexMatch = "(?s)^-----BEGIN PGP SIGNATURE-----.*-----END PGP SIGNATURE-----$"
        let testTime : Int64 = 0
        guard let keyringPrivateKey = OpenPGPTestsDefine.keyring_privateKey.rawValue,
        let keyringPublicKey =  OpenPGPTestsDefine.keyring_publicKey.rawValue else {
            XCTFail("can't be nil")
            return
        }
        let crypto = Crypto()
        do {
            
            let armoredSignature = try crypto.signDetached(plainData: signedPlainText,
                                                        privateKey: keyringPrivateKey,
                                                        passphrase: self.testMailboxPassword)
            XCTAssertTrue(!armoredSignature.isEmpty)
            XCTAssertTrue( armoredSignature.isMatch(signatureRegexMatch, options: []))
            
            
            
            let isOk = try crypto.verifyDetached(signature: armoredSignature,
                                              plainText: signedPlainText,
                                              publicKey: keyringPublicKey,
                                              verifyTime: testTime)
            XCTAssertTrue(isOk)
            
        } catch let error {
            XCTFail("thrown" + "\(error.localizedDescription)")
        }
    }
    
    func testSignDataDetached() {
        let signedPlainText = "Signed message\n"
        let signedData = signedPlainText.data(using: .utf8)!
        let signatureRegexMatch = "(?s)^-----BEGIN PGP SIGNATURE-----.*-----END PGP SIGNATURE-----$"
        let testTime : Int64 = 0
        guard let keyringPrivateKey = OpenPGPTestsDefine.keyring_privateKey.rawValue,
        let keyringPublicKey =  OpenPGPTestsDefine.keyring_publicKey.rawValue else {
            XCTFail("can't be nil")
            return
        }
        let crypto = Crypto()
        do {
            
            guard let armoredSignature = try crypto.signDetached(plainData: signedData,
                                                        privateKey: keyringPrivateKey,
                                                        passphrase: self.testMailboxPassword) else {
                                                            XCTFail("Nil signature")
                                                            return
            }
            XCTAssertTrue(!armoredSignature.isEmpty)
            XCTAssertTrue( armoredSignature.isMatch(signatureRegexMatch, options: []))
            
            
            
            let isOk = try crypto.verifyDetached(signature: armoredSignature,
                                              plainData: signedData,
                                              publicKey: keyringPublicKey,
                                              verifyTime: testTime)
            XCTAssertTrue(isOk)
            
        } catch let error {
            XCTFail("thrown" + "\(error.localizedDescription)")
        }
    }
    
//    func testVerifyTextDetachedSig() {
//        verificationError := signingKeyRing.VerifyDetached(message, textSignature, testTime)
//        if verificationError != nil {
//            t.Fatal("Cannot verify plaintext signature:", err)
//        }
//    }
//
//    func testVerifyTextDetachedSigWrong() {
//        fakeMessage := NewPlainMessageFromString("wrong text")
//        verificationError := signingKeyRing.VerifyDetached(fakeMessage, textSignature, testTime)
//
//        assert.EqualError(t, verificationError, "Signature Verification Error: Invalid signature")
//
//        err, _ := verificationError.(SignatureVerificationError)
//        assert.Exactly(t, constants.SIGNATURE_FAILED, err.Status)
//    }
//
//    func testSignBinDetached() {
//        var err error
//
//        binSignature, err = signingKeyRing.SignDetached(NewPlainMessage([]byte(signedPlainText)))
//        if err != nil {
//            t.Fatal("Cannot generate signature:", err)
//        }
//
//        armoredSignature, err := binSignature.GetArmored()
//        if err != nil {
//            t.Fatal("Cannot armor signature:", err)
//        }
//
//        assert.Regexp(t, signatureTest, armoredSignature)
//    }
//
//    func testVerifyBinDetachedSig() {
//        verificationError := signingKeyRing.VerifyDetached(message, binSignature, testTime)
//        if verificationError != nil {
//            t.Fatal("Cannot verify binary signature:", err)
//        }
//    }
    
}
