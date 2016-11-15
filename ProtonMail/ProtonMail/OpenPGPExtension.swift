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

let sharedOpenPGP = PMNOpenPgp.createInstance()!

extension PMNOpenPgp {
    enum ErrorCode: Int {
        case badPassphrase = 10001
        case noPrivateKey = 10004
        case badProtonMailPGPMessage = 10006
    }
    
    func setAddresses (addresses : Array<PMNAddress>!) {
        self.cleanAddresses();
        for addr in addresses {
            self.addAddress(addr)
        }
    }
    
    static func checkPassphrase(passphrase: String, forPrivateKey privateKey: String) -> Bool {
        if !checkPassphrase(privateKey, passphrase: passphrase) {
            return false
        }
        return true
    }
    
    func generateKey(passphrase: String, userName: String, domain:String, bits: Int32) throws -> PMNOpenPgpKey? {
        var error : NSError?
        var out_new_key : PMNOpenPgpKey?
        SwiftTryCatch.tryBlock({ () -> Void in
            out_new_key = self.generateKey(userName, domain: domain, passphrase: passphrase, bits: bits)
            if out_new_key!.privateKey.isEmpty || out_new_key!.publicKey.isEmpty {
                out_new_key = nil
            }
            }, catchBlock: { (exc) -> Void in
                error = exc.toError()
            }) { () -> Void in
        }
        if error == nil {
            return out_new_key
        } else {
            throw error!
        }
    }
    
    class func updateKeysPassword(old_keys : Array<Key>, old_pass: String, new_pass: String ) throws -> Array<Key>? {
        var error : NSError?
        let pm_keys = old_keys.toPMNPgpKeys()
        
        var out_keys : Array<Key>?
        SwiftTryCatch.tryBlock({ () -> Void in
            let new_keys = PMNOpenPgp.updateKeysPassphrase(pm_keys, oldPassphrase: old_pass, newPassphrase: new_pass)
            //TODO:: add check
            out_keys = new_keys.toKeys()
            }, catchBlock: { (exc) -> Void in
                error = exc.toError()
        }) { () -> Void in
        }
        if error == nil {
            return out_keys
        } else {
            throw error!
        }
    }
    
    class func updateKeyPassword(private_key: String, old_pass: String, new_pass: String ) throws -> String? {
        var error : NSError?
        var out_key : String?
        SwiftTryCatch.tryBlock({ () -> Void in
            out_key = PMNOpenPgp.updateSinglePassphrase(private_key, oldPassphrase: old_pass, newPassphrase: new_pass)
            if out_key == nil || out_key!.isEmpty {
                out_key = nil
            }
            }, catchBlock: { (exc) -> Void in
                error = exc.toError()
        }) { () -> Void in
        }
        if error == nil {
            return out_key
        } else {
            throw error!
        }

    }
}

// MARK: - OpenPGP String extension

extension String {
    
    func getSignature() throws -> String? {
        var error : NSError?
        var dec_out_att : String?
        SwiftTryCatch.tryBlock({ () -> Void in
            dec_out_att = sharedOpenPGP.readClearsignedMessage(self)
            }, catchBlock: { (exc) -> Void in
                error = exc.toError()
        }) { () -> Void in
        }
        if error == nil {
            return dec_out_att
        } else {
            throw error!
        }
    }
    
    func decryptMessage(passphrase: String) throws -> String? {
        var error : NSError?
        var out_decrypted : String?;
        SwiftTryCatch.tryBlock({ () -> Void in
            out_decrypted = sharedOpenPGP.decryptMessage(self, passphras: passphrase)
            }, catchBlock: { (exc) -> Void in
                error = exc.toError()
            }) { () -> Void in
        }
        if error == nil {
            return out_decrypted
        } else {
            throw error!
        }
    }
    
    func decryptMessageWithSinglKey(privateKey: String, passphrase: String) throws -> String? {
        var error : NSError?
        var out_decrypted : String?;
        SwiftTryCatch.tryBlock({ () -> Void in
            out_decrypted = sharedOpenPGP.decryptMessageSingleKey(self, privateKey: privateKey, passphras: passphrase)
            }, catchBlock: { (exc) -> Void in
                error = exc.toError()
            }) { () -> Void in
        }
        if error == nil {
            return out_decrypted;
        } else {
            throw error!
        }
    }
    
    func encryptMessage(address_id: String) throws -> String? {
        var error : NSError?
        var out_encrypted : String?
        SwiftTryCatch.tryBlock({ () -> Void in
            out_encrypted = sharedOpenPGP.encryptMessage(address_id, plainText: self)
            }, catchBlock: { (exc) -> Void in
                error = exc.toError()
            }) { () -> Void in
        }
        if error == nil {
            return out_encrypted
        } else {
            throw error!
        }
    }
    
    func encryptMessageWithSingleKey(publicKey: String) throws -> String? {
        var error : NSError?
        var out_encrypted : String?
        SwiftTryCatch.tryBlock({ () -> Void in
            out_encrypted = sharedOpenPGP.encryptMessageSingleKey(publicKey, plainText: self)
            }, catchBlock: { (exc) -> Void in
                error = exc.toError()
            }) { () -> Void in
        }
        if error == nil {
            return out_encrypted
        } else {
            throw error!
        }
    }
    
    func encryptWithPassphrase(passphrase: String) throws -> String? {
        var error : NSError?
        var out_encrypted : String?
        SwiftTryCatch.tryBlock({ () -> Void in
            out_encrypted = sharedOpenPGP.encryptMessageAes(self, password: passphrase)
            }, catchBlock: { (exc) -> Void in
                error = exc.toError()
            }) { () -> Void in
        }
        if error == nil {
            return out_encrypted
        } else {
            throw error!
        }
    }
    
    func decryptWithPassphrase(passphrase: String) throws -> String? {
        var error : NSError?
        var out_dncrypted : String?
        SwiftTryCatch.tryBlock({ () -> Void in
            out_dncrypted = sharedOpenPGP.decryptMessageAes(self, password: passphrase)
            }, catchBlock: { (exc) -> Void in
                error = exc.toError()
            }) { () -> Void in
        }
        if error == nil {
            return out_dncrypted
        } else {
            throw error!
        }
    }
}

extension NSData {
    func decryptAttachment(keyPackage:NSData!, passphrase: String) throws -> NSData? {
        var error : NSError?
        var dec_out_att : NSData?
        SwiftTryCatch.tryBlock({ () -> Void in
            dec_out_att = sharedOpenPGP.decryptAttachment(keyPackage, data: self, passphras: passphrase)
            }, catchBlock: { (exc) -> Void in
                error = exc.toError()
            }) { () -> Void in
        }
        if error == nil {
            return dec_out_att
        } else {
            throw error!
        }
    }
    
    func decryptAttachmentWithSingleKey(keyPackage:NSData!, passphrase: String, publicKey: String, privateKey: String) throws -> NSData? {
        var error : NSError?
        var dec_out_att : NSData?
        SwiftTryCatch.tryBlock({ () -> Void in
            dec_out_att = sharedOpenPGP.decryptAttachmentSingleKey(keyPackage, data: self, privateKey: privateKey, passphras: passphrase)
            }, catchBlock: { (exc) -> Void in
                error = exc.toError()
            }) { () -> Void in
        }
        if error == nil {
            return dec_out_att
        } else {
            throw error!
        }
    }
    
    func encryptAttachment(address_id: String, fileName:String) throws -> PMNEncryptPackage? {
        var error : NSError?
        var out_enc_data : PMNEncryptPackage?
        SwiftTryCatch.tryBlock({ () -> Void in
            out_enc_data = sharedOpenPGP.encryptAttachment(address_id, unencryptData: self, fileName: fileName)
            }, catchBlock: { (exc) -> Void in
                error = exc.toError()
            }) { () -> Void in
        }
        if error == nil {
            return out_enc_data
        } else {
            throw error!
        }
    }
    
    func encryptAttachmentWithSingleKey(publicKey: String, fileName:String) throws -> PMNEncryptPackage? {
        var error : NSError?
        var out_enc_data : PMNEncryptPackage?
        SwiftTryCatch.tryBlock({ () -> Void in
            out_enc_data = sharedOpenPGP.encryptAttachmentSingleKey(publicKey, unencryptData: self, fileName: fileName)
            }, catchBlock: { (exc) -> Void in
                error = exc.toError()
            }) { () -> Void in
        }
        if error == nil {
            return out_enc_data
        } else {
            throw error!
        }
    }
    
    //key packet part
    func getSessionKeyFromPubKeyPackage(passphrase: String) throws -> NSData? {
        var error : NSError?
        var key_session_out : NSData?
        SwiftTryCatch.tryBlock({ () -> Void in
            key_session_out = sharedOpenPGP.getPublicKeySessionKey(self, passphrase: passphrase)
            }, catchBlock: { (exc) -> Void in
                error = exc.toError()
            }) { () -> Void in
        }
        if error == nil {
            return key_session_out
        } else {
            throw error!
        }
    }
    
    func getSessionKeyFromPubKeyPackageWithSingleKey(privateKey: String, passphrase: String, publicKey: String) throws -> NSData? {
        var error : NSError?
        var key_session_out : NSData?
        SwiftTryCatch.tryBlock({ () -> Void in
            key_session_out = sharedOpenPGP.getPublicKeySessionKeySingleKey(self, privateKey: privateKey, passphrase: passphrase)
            }, catchBlock: { (exc) -> Void in
                error = exc.toError()
            }) { () -> Void in
        }
        if error == nil {
            return key_session_out
        } else {
            throw error!
        }
    }
    
    func getPublicSessionKeyPackage(publicKey: String) throws -> NSData? {
        var error : NSError?
        var out_new_key : NSData?
        SwiftTryCatch.tryBlock({ () -> Void in
            out_new_key = sharedOpenPGP.getNewPublicKeyPackage(self, publicKey: publicKey)
            }, catchBlock: { (exc) -> Void in
                error = exc.toError()
            }) { () -> Void in
        }
        if error == nil {
            return out_new_key
        } else {
            throw error!
        }
    }
    
    func getSymmetricSessionKeyPackage(pwd: String) throws -> NSData? {
        var error : NSError?
        var out_sym_key_package : NSData?
        SwiftTryCatch.tryBlock({ () -> Void in
            out_sym_key_package = sharedOpenPGP.getNewSymmetricKeyPackage(self, password: pwd)
            }, catchBlock: { (exc) -> Void in
                error = exc.toError()
            }) { () -> Void in
        }
        if error == nil {
            return out_sym_key_package
        } else {
            throw error!
        }
    }
}
