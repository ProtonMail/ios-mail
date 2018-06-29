
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


extension PmOpenPGP {
    func random(byte: Int) -> Data? {
        var error : NSError?
        let out = PmRandomTokenWith(byte, &error)
        if nil != error {
            return nil
        }
        return out
    }
    
    class func updateKeysPassword(_ old_keys : [Key], old_pass: String, new_pass: String ) throws -> [Key] {
        var outKeys : [Key] = [Key]()
        for okey in old_keys {
            do {
                let new_private_key = try sharedOpenPGP.updatePrivateKeyPassphrase(okey.private_key,
                                                                                   oldPassphrase: old_pass,
                                                                                   newPassphrase: new_pass)
                let newK = Key(key_id: okey.key_id,
                               private_key: new_private_key,
                               fingerprint: okey.fingerprint,
                               isupdated: true)
                outKeys.append(newK)
            } catch {
                let newK = Key(key_id: okey.key_id,
                               private_key: okey.private_key,
                               fingerprint: okey.fingerprint,
                               isupdated: false)
                outKeys.append(newK)
            }
        }
        
        guard outKeys.count == old_keys.count else {
            throw UpdatePasswordError.keyUpdateFailed.error
        }
        
        guard outKeys.count > 0 && outKeys[0].is_updated == true else {
            throw UpdatePasswordError.keyUpdateFailed.error
        }
        
        for u_k in outKeys {
            if u_k.is_updated == false {
                continue
            }
            let result = PmCheckPassphrase(u_k.private_key, new_pass)
            guard result == true else {
                throw UpdatePasswordError.keyUpdateFailed.error
            }
        }
        return outKeys
    }
    
    
    class func updateAddrKeysPassword(_ old_addresses : [Address], old_pass: String, new_pass: String ) throws -> [Address] {
        var out_addresses = [Address]()
        for addr in old_addresses {
            var outKeys : [Key] = [Key]()
            for okey in addr.keys {
                do {
                    let new_private_key = try sharedOpenPGP.updatePrivateKeyPassphrase(okey.private_key,
                                                                                       oldPassphrase: old_pass,
                                                                                       newPassphrase: new_pass)
                    let newK = Key(key_id: okey.key_id,
                                   private_key: new_private_key,
                                   fingerprint: okey.fingerprint,
                                   isupdated: true)
                    outKeys.append(newK)
                } catch {
                    let newK = Key(key_id: okey.key_id,
                                   private_key: okey.private_key,
                                   fingerprint: okey.fingerprint,
                                   isupdated: false)
                    outKeys.append(newK)
                }
            }
            
            guard outKeys.count == addr.keys.count else {
                throw UpdatePasswordError.keyUpdateFailed.error
            }
            
            guard outKeys.count > 0 && outKeys[0].is_updated == true else {
                throw UpdatePasswordError.keyUpdateFailed.error
            }
            
            for u_k in outKeys {
                if u_k.is_updated == false {
                    continue
                }
                let result = PmCheckPassphrase(u_k.private_key, new_pass)
                guard result == true else {
                    throw UpdatePasswordError.keyUpdateFailed.error
                }
            }
            
            let new_addr = Address(addressid: addr.address_id,
                                   email: addr.email,
                                   order: addr.order,
                                   receive: addr.receive,
                                   mailbox: addr.mailbox,
                                   display_name: addr.display_name,
                                   signature: addr.signature,
                                   keys: outKeys,
                                   status: addr.status,
                                   type: addr.type,
                                   send: addr.send)
            out_addresses.append(new_addr)
        }
        
        guard out_addresses.count == old_addresses.count else {
            throw UpdatePasswordError.keyUpdateFailed.error
        }
        
        return out_addresses
    }
}


//
extension PMNOpenPgp {
//    enum ErrorCode: Int {
//        case badPassphrase = 10001
//        case noPrivateKey = 10004
//        case badProtonMailPGPMessage = 10006
//    }
//
//    static func checkPassphrase(_ passphrase: String, forPrivateKey privateKey: String) -> Bool {
//        if !checkPassphrase(privateKey, passphrase: passphrase) {
//            return false
//        }
//        return true
//    }
//
    func generateKey(_ passphrase: String, userName: String, domain:String, bits: Int32) throws -> PMNOpenPgpKey? {
        var out_new_key : PMNOpenPgpKey?
        try ObjC.catchException {
            out_new_key = self.generateKey(userName, domain: domain, passphrase: passphrase, bits: bits, time: 0)
           
            if out_new_key!.privateKey.isEmpty || out_new_key!.publicKey.isEmpty {
                out_new_key = nil
            }
        }
        return out_new_key
    }
}
//

//
//    class func updateKeyPassword(_ private_key: String, old_pass: String, new_pass: String ) throws -> String {
//        var out_key : String?
//        try ObjC.catchException {
//            out_key = PMNOpenPgp.updateSinglePassphrase(private_key, oldPassphrase: old_pass, newPassphrase: new_pass)
//            if out_key == nil || out_key!.isEmpty {
//                out_key = nil
//            }
//        }
//
//        guard let outKey = out_key else {
//            throw UpdatePasswordError.keyUpdateFailed.error
//        }
//
//        guard PMNOpenPgp.checkPassphrase(outKey, passphrase: new_pass) else {
//            throw UpdatePasswordError.keyUpdateFailed.error
//        }
//
//        return outKey
//    }
//
//
//    func signVerify(detached signature: String, publicKey: String, plainText: String ) -> Bool {
//        var check = false
//        do {
//            try ObjC.catchException {
//                check = self.signDetachedVerifySinglePubKey(publicKey, signature: signature, plainText: plainText)
//            }
//        } catch {
//
//        }
//        return check
//    }
//}

extension Data {
    func decryptAttachment(_ keyPackage:Data!, passphrase: String) throws -> Data? {
        let privKeys = sharedUserDataService.addressPrivKeys
        return try sharedOpenPGP.decryptAttachmentBinKey(keyPackage, dataPacket: self, privateKeys: privKeys, passphrase: passphrase)
    }

    func decryptAttachmentWithSingleKey(_ keyPackage:Data!, passphrase: String, publicKey: String, privateKey: String) throws -> Data? {
        return try sharedOpenPGP.decryptAttachment(keyPackage, dataPacket: self, privateKey: privateKey, passphrase: passphrase)
    }
    
    func encryptAttachment(_ address_id: String, fileName:String, mailbox_pwd: String) throws -> PmEncryptedSplit? {
        let pubkey = sharedUserDataService.getAddressPrivKey(address_id: address_id)
        return try sharedOpenPGP.encryptAttachment(self, fileName: fileName, publicKey: pubkey)
    }
    //
//    func encryptAttachmentWithSingleKey(_ publicKey: String, fileName:String, privateKey: String, mailbox_pwd: String) throws -> PMNEncryptPackage? {
//        var out_enc_data : PMNEncryptPackage?
//        try ObjC.catchException {
//            out_enc_data = sharedOpenPGP.encryptAttachmentSingleKey(publicKey, unencryptData: self, fileName: fileName, privateKey: privateKey, passphras: mailbox_pwd)
//        }
//        
//        return out_enc_data
//    }
//    
    //key packet part
    func getSessionFromPubKeyPackage(_ passphrase: String) throws -> PmSessionSplit? {
        var error : NSError?
        let privKeys = sharedUserDataService.addressPrivKeys
        let out = PmGetSessionFromKeyPacketBinkeys(self, privKeys, passphrase, &error)
        if let err = error {
            throw err
        }
        return out
    }
    
//    func getSessionKeyFromPubKeyPackageWithSingleKey(_ privateKey: String, passphrase: String, publicKey: String) throws -> Data? {
//        var key_session_out : Data?
//        try ObjC.catchException {
//            key_session_out = sharedOpenPGP.getPublicKeySessionKeySingleKey(self, privateKey: privateKey, passphrase: passphrase)
//        }
//        
//        return key_session_out
//    }
    
    func getKeyPackage(strKey publicKey: String) throws -> Data? {
        let session = PmSessionSplit()!
        session.setSession( self)
        session.setAlgo("aes256")
        
        var error : NSError?
        let packet : Data? = PmKeyPacketWithPublicKey(session, publicKey, &error)
        if let err = error {
            throw err
        }
        return packet
    }
    
    func getKeyPackage(dataKey publicKey: Data) throws -> Data? {
        let session = PmSessionSplit()!
        session.setSession( self)
        session.setAlgo("aes256")
        
        var error : NSError?
        let packet : Data? = PmKeyPacketWithPublicKeyBin(session, publicKey, &error)
        if let err = error {
            throw err
        }
        return packet
    }
    
    func getSymmetricPacket(withPwd pwd: String) throws -> Data? {
        let session = PmSessionSplit()
        session?.setSession(self)
        session?.setAlgo("aes256")
        
        
        var error : NSError?
        let packet : Data? = PmSymmetricKeyPacketWithPassword(session, pwd, &error)
        if let err = error {
            throw err
        }
        return packet
    }
    
//    func getPublicSessionKeyPackage(str publicKey: String) throws -> Data? {
//        var out_new_key : Data?
//        try ObjC.catchException {
//            out_new_key = sharedOpenPGP.getNewPublicKeyPackage(self, publicKey: publicKey)
//        }
//        
//        return out_new_key
//    }
//    
//    func getPublicSessionKeyPackage(data publicKey: Data) throws -> Data? {
//        var out_new_key : Data?
//        try ObjC.catchException {
//            out_new_key = sharedOpenPGP.getNewPublicKeyPackageBinary(self, publicKey: publicKey)
//        }
//        return out_new_key
//    }

}
