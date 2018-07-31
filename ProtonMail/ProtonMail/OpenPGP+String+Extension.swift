
//
//  OpenPGPExtension.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation
import Pm

let sharedOpenPGP = PmOpenPGP()!


// MARK: - OpenPGP String extension

extension String {
    
    func getSignature() throws -> String? {
        var error : NSError?
        let dec_out_att : String = PmReadClearSignedMessage(self, &error)
        if let err = error {
            throw err
        }
        return dec_out_att
    }
    
    func decryptMessage(binKeys: Data, passphrase: String) throws -> String? {
        return try sharedOpenPGP.decryptMessageBinKey(self, privateKey: binKeys, passphrase: passphrase)
    }
    
    func verifyMessage(verifier: Data, binKeys: Data, passphrase: String, time : Int64) throws -> PmDecryptSignedVerify? {
        return try sharedOpenPGP.decryptMessageVerifyBinKeyPrivbinkeys(self, veriferKey: verifier, privateKeys: binKeys, passphrase: passphrase, verifyTime: time)
    }
    
    func decryptMessageWithSinglKey(_ privateKey: String, passphrase: String) throws -> String? {
        return try sharedOpenPGP.decryptMessage(self, privateKey: privateKey, passphrase: passphrase)
    }
    
    func split() throws -> PmEncryptedSplit? {
        var error : NSError?
        let out = PmSeparateKeyAndData(self, &error)
        if let err = error {
            throw err
        }
        return out
    }
    
    func encrypt(withAddr address_id: String, mailbox_pwd: String) throws -> String? {
        let privateKey = sharedUserDataService.getAddressPrivKey(address_id: address_id)
        return try sharedOpenPGP.encryptMessage(self, publicKey: privateKey, privateKey: privateKey, passphrase: mailbox_pwd, trim: true)
    }
    
    func encrypt(withPubKey publicKey: String, privateKey: String, mailbox_pwd: String) throws -> String? {
        return try sharedOpenPGP.encryptMessage(self, publicKey: publicKey, privateKey: privateKey, passphrase: mailbox_pwd, trim: true)
    }
    
    func encrypt(withPwd passphrase: String) throws -> String? {
        return try sharedOpenPGP.encryptMessage(withPassword: self, password: passphrase)
    }
    
    func decrypt(withPwd passphrase: String) throws -> String? {
        return try sharedOpenPGP.decryptMessage(withPassword: self, password: passphrase)
    }
    
    //self is private key
    func check(passphrase: String) -> Bool {
        return PmCheckPassphrase(self, passphrase)
    }
}


