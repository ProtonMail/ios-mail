//
//  OpenPGPExtension.swift
//  ProtonMail
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


import Foundation
import Crypto

// MARK: - OpenPGP String extension

extension String {

    func decryptMessage(binKeys: Data, passphrase: String) throws -> String? {
        return try Crypto().decrypt(encrytped: self, privateKey: binKeys, passphrase: passphrase)
    }
    
    func verifyMessage(verifier: Data, binKeys: Data, passphrase: String, time : Int64) throws -> ExplicitVerifyMessage? {
        return try Crypto().decryptVerify(encrytped: self, publicKey: verifier, privateKey: binKeys, passphrase: passphrase, verifyTime: time)
    }
    
    func verifyMessage(verifier: Data, userKeys: Data, keys: [Key], passphrase: String, time : Int64) throws -> ExplicitVerifyMessage? {
        var firstError : Error?
        for key in keys {
            do {
                if let token = key.token, let signature = key.signature { //have both means new schema. key is
                    if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        PMLog.D(signature)
                        return try Crypto().decryptVerify(encrytped: self,
                                                          publicKey: verifier,
                                                          privateKey: key.private_key,
                                                          passphrase: plaitToken, verifyTime: time)
                    }
                } else if let token = key.token { //old schema with token - subuser. key is embed singed
                    if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        //TODO:: try to verify signature here embeded signature
                        return try Crypto().decryptVerify(encrytped: self,
                                                          publicKey: verifier,
                                                          privateKey: key.private_key,
                                                          passphrase: plaitToken, verifyTime: time)
                    }
                } else {//normal key old schema
                    return try Crypto().decryptVerify(encrytped: self,
                                                      publicKey: verifier,
                                                      privateKey: userKeys,
                                                      passphrase: passphrase, verifyTime: time)
                }
            } catch let error {
                if firstError == nil {
                    firstError = error
                }
                PMLog.D(error.localizedDescription)
            }
        }
        if let error = firstError {
            throw error
        }
        return nil
    }
    
    func decryptMessageWithSinglKey(_ privateKey: String, passphrase: String) throws -> String? {
        return try Crypto().decrypt(encrytped: self, privateKey: privateKey, passphrase: passphrase)
    }
    
    func encrypt(withPrivKey key: String, mailbox_pwd: String) throws -> String? {
        return try Crypto().encrypt(plainText: self, publicKey: key, privateKey: key, passphrase: mailbox_pwd)
    }
    
    func encrypt(withKey key: Key, userKeys: Data, mailbox_pwd: String) throws -> String? {
        if let token = key.token, let signature = key.signature { //have both means new schema. key is
            if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: mailbox_pwd) {
                PMLog.D(signature)
                return try Crypto().encrypt(plainText: self,
                                            publicKey: key.private_key,
                                            privateKey: key.private_key,
                                            passphrase: plaitToken)
            }
        } else if let token = key.token { //old schema with token - subuser. key is embed singed
            if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: mailbox_pwd) {
                //TODO:: try to verify signature here embeded signature
                return try Crypto().encrypt(plainText: self,
                                            publicKey: key.private_key,
                                            privateKey: key.private_key,
                                            passphrase: plaitToken)
            }
        }
        return try Crypto().encrypt(plainText: self,
                                    publicKey:  key.private_key,
                                    privateKey: key.private_key,
                                    passphrase: mailbox_pwd)
    }

    func encrypt(withPubKey publicKey: String, privateKey: String, passphrase: String) throws -> String? {
        return try Crypto().encrypt(plainText: self, publicKey: publicKey, privateKey: privateKey, passphrase: passphrase)
    }
    
    func encrypt(withPwd passphrase: String) throws -> String? {
        return try Crypto().encrypt(plainText: self, token: passphrase)
    }
    
    func decrypt(withPwd passphrase: String) throws -> String? {
        return try Crypto().decrypt(encrypted: self, token: passphrase)
    }
}


