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

let OpenPGPErrorDomain = "com.ProtonMail.OpenPGP"

public let sharedOpenPGP = PMNOpenPgp.createInstance()!

extension PMNOpenPgp {
    public enum ErrorCode: Int {
        case badPassphrase = 10001
        case noPrivateKey = 10004
        case badProtonMailPGPMessage = 10006
    }
    
    public func setAddresses (_ addresses : Array<PMNAddress>!) {
        self.cleanAddresses();
        for addr in addresses {
            self.add(addr)
        }
    }
    
    static public func checkPassphrase(_ passphrase: String, forPrivateKey privateKey: String) -> Bool {
        if !checkPassphrase(privateKey, passphrase: passphrase) {
            return false
        }
        return true
    }
    
    public func generateKey(_ passphrase: String, userName: String, domain:String, bits: Int32) throws -> PMNOpenPgpKey? {
        var out_new_key : PMNOpenPgpKey?
        try ObjC.catchException {
            out_new_key = self.generateKey(userName, domain: domain, passphrase: passphrase, bits: bits)
            if out_new_key!.privateKey.isEmpty || out_new_key!.publicKey.isEmpty {
                out_new_key = nil
            }
        }
        return out_new_key
    }
    
    public class func updateKeysPassword(_ old_keys : Array<Key>, old_pass: String, new_pass: String ) throws -> Array<Key> {
        let pm_keys = old_keys.toPMNPgpKeys()
        var out_keys : Array<Key>?
        try ObjC.catchException {
            let new_keys = PMNOpenPgp.updateKeysPassphrase(pm_keys, oldPassphrase: old_pass, newPassphrase: new_pass)
            out_keys = new_keys.toKeys()
        }
        
        guard let outKeys = out_keys, outKeys.count == old_keys.count else {
            throw UpdatePasswordError.keyUpdateFailed.toError()
        }
        
        guard outKeys.count > 0 && outKeys[0].is_updated == true else {
            throw UpdatePasswordError.keyUpdateFailed.toError()
        }
        
        for u_k in outKeys {
            if u_k.is_updated == false {
                continue
            }
            let result = PMNOpenPgp.checkPassphrase(u_k.private_key, passphrase: new_pass)
            guard result == true else {
                throw UpdatePasswordError.keyUpdateFailed.toError()
            }
        }
        return outKeys
    }
    
    
    public class func updateAddrKeysPassword(_ old_addresses : Array<Address>, old_pass: String, new_pass: String ) throws -> Array<Address> {
        var out_addresses = Array<Address>()
        for addr in old_addresses {
            var out_keys : Array<Key>?
            let pm_keys = addr.keys.toPMNPgpKeys()
            
            try ObjC.catchException {
                let new_keys = PMNOpenPgp.updateKeysPassphrase(pm_keys, oldPassphrase: old_pass, newPassphrase: new_pass)
                out_keys = new_keys.toKeys()
            }
            
            guard let outKeys = out_keys, outKeys.count == addr.keys.count else {
                throw UpdatePasswordError.keyUpdateFailed.toError()
            }
            
            guard outKeys.count > 0 && outKeys[0].is_updated == true else {
                throw UpdatePasswordError.keyUpdateFailed.toError()
            }
            
            for u_k in outKeys {
                if u_k.is_updated == false {
                    continue
                }
                let result = PMNOpenPgp.checkPassphrase(u_k.private_key, passphrase: new_pass)
                guard result == true else {
                    throw UpdatePasswordError.keyUpdateFailed.toError()
                }
            }
            
            let new_addr = Address(addressid: addr.address_id,
                                   email: addr.email,
                                   send: addr.send,
                                   receive: addr.receive,
                                   mailbox: addr.mailbox,
                                   display_name: addr.display_name,
                                   signature: addr.signature,
                                   keys: outKeys,
                                   status: addr.status,
                                   type: addr.type)
            
            out_addresses.append(new_addr)
        }
        
        guard out_addresses.count == old_addresses.count else {
            throw UpdatePasswordError.keyUpdateFailed.toError()
        }
        
        return out_addresses
    }
    
    public class func updateKeyPassword(_ private_key: String, old_pass: String, new_pass: String ) throws -> String {
        var out_key : String?
        try ObjC.catchException {
            out_key = PMNOpenPgp.updateSinglePassphrase(private_key, oldPassphrase: old_pass, newPassphrase: new_pass)
            if out_key == nil || out_key!.isEmpty {
                out_key = nil
            }
        }
        
        guard let outKey = out_key else {
            throw UpdatePasswordError.keyUpdateFailed.toError()
        }
        
        guard PMNOpenPgp.checkPassphrase(outKey, passphrase: new_pass) else {
            throw UpdatePasswordError.keyUpdateFailed.toError()
        }
        
        return outKey
    }
}

// MARK: - OpenPGP String extension

extension String {
    
    public func getSignature() throws -> String? {
        var dec_out_att : String?
        try ObjC.catchException {
            dec_out_att = sharedOpenPGP.readClearsignedMessage(self)
        }
        
        return dec_out_att
    }
    
    public func decryptMessage(_ passphrase: String) throws -> String? {
        var out_decrypted : String?
        try ObjC.catchException {
            out_decrypted = sharedOpenPGP.decryptMessage(self, passphras: passphrase)
        }
        
        return out_decrypted
    }
    
    public func decryptMessageWithSinglKey(_ privateKey: String, passphrase: String) throws -> String? {
        var out_decrypted : String?
        try ObjC.catchException {
            out_decrypted = sharedOpenPGP.decryptMessageSingleKey(self, privateKey: privateKey, passphras: passphrase)
        }
        
        return out_decrypted;
    }
    
    public func encryptMessage(_ address_id: String) throws -> String? {
        var out_encrypted : String?
        try ObjC.catchException {
            out_encrypted = sharedOpenPGP.encryptMessage(address_id, plainText: self)
        }
        
        return out_encrypted
    }
    
    public func encryptMessageWithSingleKey(_ publicKey: String) throws -> String? {
        var out_encrypted : String?
        try ObjC.catchException {
            out_encrypted = sharedOpenPGP.encryptMessageSingleKey(publicKey, plainText: self)
        }
        
        return out_encrypted
    }
    
    public func encryptWithPassphrase(_ passphrase: String) throws -> String? {
        var out_encrypted : String?
        try ObjC.catchException {
            out_encrypted = sharedOpenPGP.encryptMessageAes(self, password: passphrase)
        }
        
        return out_encrypted
    }
    
    public func decryptWithPassphrase(_ passphrase: String) throws -> String? {
        var out_dncrypted : String?
        try ObjC.catchException {
            out_dncrypted = sharedOpenPGP.decryptMessageAes(self, password: passphrase)
        }
        
        return out_dncrypted
    }
}

extension Data {
    public func decryptAttachment(_ keyPackage:Data!, passphrase: String) throws -> Data? {
        var dec_out_att : Data?
        try ObjC.catchException {
            dec_out_att = sharedOpenPGP.decryptAttachment(keyPackage, data: self, passphras: passphrase)
        }
        
        return dec_out_att
    }
    
    public func decryptAttachmentWithSingleKey(_ keyPackage:Data!, passphrase: String, publicKey: String, privateKey: String) throws -> Data? {
        var dec_out_att : Data?
        try ObjC.catchException {
            dec_out_att = sharedOpenPGP.decryptAttachmentSingleKey(keyPackage, data: self, privateKey: privateKey, passphras: passphrase)
        }
        
        return dec_out_att
    }
    
    public func encryptAttachment(_ address_id: String, fileName:String) throws -> PMNEncryptPackage? {
        var out_enc_data : PMNEncryptPackage?
        try ObjC.catchException {
            out_enc_data = sharedOpenPGP.encryptAttachment(address_id, unencryptData: self, fileName: fileName)
        }
        
        return out_enc_data
    }
    
    public func encryptAttachmentWithSingleKey(_ publicKey: String, fileName:String) throws -> PMNEncryptPackage? {
        var out_enc_data : PMNEncryptPackage?
        try ObjC.catchException {
            out_enc_data = sharedOpenPGP.encryptAttachmentSingleKey(publicKey, unencryptData: self, fileName: fileName)
        }
        
        return out_enc_data
    }
    
    //key packet part
    public func getSessionKeyFromPubKeyPackage(_ passphrase: String) throws -> Data? {
        var key_session_out : Data?
        try ObjC.catchException {
            key_session_out = sharedOpenPGP.getPublicKeySessionKey(self, passphrase: passphrase)
        }
        
        return key_session_out
    }
    
    public func getSessionKeyFromPubKeyPackageWithSingleKey(_ privateKey: String, passphrase: String, publicKey: String) throws -> Data? {
        var key_session_out : Data?
        try ObjC.catchException {
            key_session_out = sharedOpenPGP.getPublicKeySessionKeySingleKey(self, privateKey: privateKey, passphrase: passphrase)
        }
        
        return key_session_out
    }
    
    public func getPublicSessionKeyPackage(_ publicKey: String) throws -> Data? {
        var out_new_key : Data?
        try ObjC.catchException {
            out_new_key = sharedOpenPGP.getNewPublicKeyPackage(self, publicKey: publicKey)
        }
        
        return out_new_key
    }
    
    public func getSymmetricSessionKeyPackage(_ pwd: String) throws -> Data? {
        var out_sym_key_package : Data?
        try ObjC.catchException {
            out_sym_key_package = sharedOpenPGP.getNewSymmetricKeyPackage(self, password: pwd)
        }
        
        return out_sym_key_package
    }
}
