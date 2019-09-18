//
//  CryptoTests+Signature.swift
//  ProtonMail - Created on 09/12/19.
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
        let pgp = Crypto()
        do {
            
            let armoredSignature = try pgp.signDetached(plainData: signedPlainText,
                                                        privateKey: keyringPrivateKey,
                                                        passphrase: self.testMailboxPassword)
            XCTAssertTrue(!armoredSignature.isEmpty)
            XCTAssertTrue( armoredSignature.isMatch(signatureRegexMatch, options: []))
            
            
            
            let isOk = try pgp.verifyDetached(signature: armoredSignature,
                                              plainText: signedPlainText,
                                              publicKey: keyringPublicKey,
                                              verifyTime: testTime)
            XCTAssertTrue(isOk)
            
        } catch let error {
            XCTFail("thrown" + "\(error.localizedDescription)")
        }
        
   
//        message = NewPlainMessageFromString(signedPlainText)
//        textSignature, err = signingKeyRing.SignDetached(message)
//        if err != nil {
//            t.Fatal("Cannot generate signature:", err)
//        }
//
//        armoredSignature, err := textSignature.GetArmored()
//        if err != nil {
//            t.Fatal("Cannot armor signature:", err)
//        }
//
//        assert.Regexp(t, signatureTest, armoredSignature)
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
