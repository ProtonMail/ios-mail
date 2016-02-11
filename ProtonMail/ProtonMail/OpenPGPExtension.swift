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
    
    func checkPassphrase(passphrase: String, forPrivateKey privateKey: String, error: NSErrorPointer?) -> Bool {
        if !checkPassphrase(privateKey, passphrase: passphrase) {
            return false
        }
        return true
    }
    
    func generateKey(passphrase: String, userName: String, domain:String, bits: Int32, error: NSErrorPointer?) -> PMNOpenPgpKey? {
        var out_new_key : PMNOpenPgpKey?
        SwiftTryCatch.tryBlock({ () -> Void in
            out_new_key = self.generateKey(userName, domain: domain, passphrase: passphrase, bits: bits)
            if out_new_key!.privateKey.isEmpty || out_new_key!.publicKey.isEmpty {
                out_new_key = nil
            }
            }, catchBlock: { (exc) -> Void in
                if let error = error {
                    error.memory = exc.toError()
                }
            }) { () -> Void in
        }
        return out_new_key;
    }
    
    func updatePassphrase(privateKey: String, publicKey: String, old_pass: String, new_pass: String, error: NSErrorPointer?) -> String? {
        //TODO:: need do migrate
        //        var anError: NSError?
        //        if !SetupKeys(privateKey, pubKey: publicKey, pass: old_pass, error: &anError) {
        //            if let error = error {
        //                error.memory = anError
        //            }
        //            return nil
        //        }
        //        if let new_privkey = update_key_password(old_pass, new_pwd: new_pass, error: &anError) {
        //            return new_privkey
        //        }
        //        if let error = error {
        //            error.memory = anError
        //        }
        return nil
    }
}

// MARK: - OpenPGP String extension

extension String {
    func decryptMessage(passphrase: String, error: NSErrorPointer?) -> String? {
        var out_decrypted : String?;
        SwiftTryCatch.tryBlock({ () -> Void in
            out_decrypted = sharedOpenPGP.decryptMessage(self, passphras: passphrase)
            }, catchBlock: { (exc) -> Void in
                if let error = error {
                    error.memory = exc.toError()
                }
            }) { () -> Void in
        }
        return out_decrypted;
    }
    
    func decryptMessageWithSinglKey(privateKey: String, passphrase: String, error: NSErrorPointer?) -> String? {
        var out_decrypted : String?;
        SwiftTryCatch.tryBlock({ () -> Void in
            out_decrypted = sharedOpenPGP.decryptMessageSingleKey(self, privateKey: privateKey, passphras: passphrase)
            }, catchBlock: { (exc) -> Void in
                if let error = error {
                    error.memory = exc.toError()
                }
            }) { () -> Void in
        }
        return out_decrypted;
    }
    
    func encryptMessage(address_id: String, error: NSErrorPointer?) -> String? {
        var out_encrypted : String?
        SwiftTryCatch.tryBlock({ () -> Void in
            out_encrypted = sharedOpenPGP.encryptMessage(address_id, plainText: self)
            }, catchBlock: { (exc) -> Void in
                if let error = error {
                    error.memory = exc.toError()
                }
            }) { () -> Void in
        }
        return out_encrypted;
    }
    
    func encryptMessageWithSingleKey(publicKey: String, error: NSErrorPointer?) -> String? {
        var out_encrypted : String?
        SwiftTryCatch.tryBlock({ () -> Void in
            out_encrypted = sharedOpenPGP.encryptMessageSingleKey(publicKey, plainText: self)
            }, catchBlock: { (exc) -> Void in
                if let error = error {
                    error.memory = exc.toError()
                }
            }) { () -> Void in
        }
        return out_encrypted;
    }
    
    func encryptWithPassphrase(passphrase: String, error: NSErrorPointer?) -> String? {
        var out_encrypted : String?
        SwiftTryCatch.tryBlock({ () -> Void in
            out_encrypted = sharedOpenPGP.encryptMessageAes(self, password: passphrase)
            }, catchBlock: { (exc) -> Void in
                if let error = error {
                    error.memory = exc.toError()
                }
            }) { () -> Void in
        }
        return out_encrypted
    }
    
    func decryptWithPassphrase(passphrase: String, error: NSErrorPointer?) -> String? {
        var out_dncrypted : String?
        SwiftTryCatch.tryBlock({ () -> Void in
            out_dncrypted = sharedOpenPGP.decryptMessageAes(self, password: passphrase)
            }, catchBlock: { (exc) -> Void in
                if let error = error {
                    error.memory = exc.toError()
                }
            }) { () -> Void in
        }
        return out_dncrypted
    }
}

extension NSData {
    
    func decryptAttachment(keyPackage:NSData!, passphrase: String, error: NSErrorPointer?) -> NSData? {
        var dec_out_att : NSData?
        SwiftTryCatch.tryBlock({ () -> Void in
            dec_out_att = sharedOpenPGP.decryptAttachment(keyPackage, data: self, passphras: passphrase)
            }, catchBlock: { (exc) -> Void in
                if let error = error {
                    error.memory = exc.toError()
                }
            }) { () -> Void in
        }
        return dec_out_att
    }
    
    func decryptAttachmentWithSingleKey(keyPackage:NSData!, passphrase: String, publicKey: String, privateKey: String, error: NSErrorPointer?) -> NSData? {
        var dec_out_att : NSData?
        SwiftTryCatch.tryBlock({ () -> Void in
            dec_out_att = sharedOpenPGP.decryptAttachmentSingleKey(keyPackage, data: self, privateKey: privateKey, passphras: passphrase)
            }, catchBlock: { (exc) -> Void in
                if let error = error {
                    error.memory = exc.toError()
                }
            }) { () -> Void in
        }
        return dec_out_att
    }
    
    func encryptAttachment(address_id: String, fileName:String, error: NSErrorPointer?) -> PMNEncryptPackage? {
        var out_enc_data : PMNEncryptPackage?
        SwiftTryCatch.tryBlock({ () -> Void in
            out_enc_data = sharedOpenPGP.encryptAttachment(address_id, unencryptData: self, fileName: fileName)
            }, catchBlock: { (exc) -> Void in
                if let error = error {
                    error.memory = exc.toError()
                }
            }) { () -> Void in
        }
        return out_enc_data
    }
    
    func encryptAttachmentWithSingleKey(publicKey: String, fileName:String, error: NSErrorPointer?) -> PMNEncryptPackage? {
        var out_enc_data : PMNEncryptPackage?
        SwiftTryCatch.tryBlock({ () -> Void in
            out_enc_data = sharedOpenPGP.encryptAttachmentSingleKey(publicKey, unencryptData: self, fileName: fileName)
            }, catchBlock: { (exc) -> Void in
                if let error = error {
                    error.memory = exc.toError()
                }
            }) { () -> Void in
        }
        return out_enc_data
    }
    
    //key packet part
    func getSessionKeyFromPubKeyPackage(passphrase: String, error: NSErrorPointer?) -> NSData? {
        var key_session_out : NSData?
        SwiftTryCatch.tryBlock({ () -> Void in
            key_session_out = sharedOpenPGP.getPublicKeySessionKey(self, passphrase: passphrase)
            }, catchBlock: { (exc) -> Void in
                if let error = error {
                    error.memory = exc.toError()
                }
            }) { () -> Void in
        }
        return key_session_out
    }
    
    func getSessionKeyFromPubKeyPackageWithSingleKey(privateKey: String, passphrase: String, publicKey: String, error: NSErrorPointer?) -> NSData? {
        var key_session_out : NSData?
        SwiftTryCatch.tryBlock({ () -> Void in
            key_session_out = sharedOpenPGP.getPublicKeySessionKeySingleKey(self, privateKey: privateKey, passphrase: passphrase)
            }, catchBlock: { (exc) -> Void in
                if let error = error {
                    error.memory = exc.toError()
                }
            }) { () -> Void in
        }
        return key_session_out
    }
    
    func getPublicSessionKeyPackage(publicKey: String, error: NSErrorPointer?) -> NSData? {
        var out_new_key : NSData?
        SwiftTryCatch.tryBlock({ () -> Void in
            out_new_key = sharedOpenPGP.getNewPublicKeyPackage(self, publicKey: publicKey)
            }, catchBlock: { (exc) -> Void in
                if let error = error {
                    error.memory = exc.toError()
                }
            }) { () -> Void in
        }
        return out_new_key
    }
    
    func getSymmetricSessionKeyPackage(pwd: String, error: NSErrorPointer?) -> NSData? {
        var out_sym_key_package : NSData?
        SwiftTryCatch.tryBlock({ () -> Void in
            out_sym_key_package = sharedOpenPGP.getNewSymmetricKeyPackage(self, password: pwd)
            }, catchBlock: { (exc) -> Void in
                if let error = error {
                    error.memory = exc.toError()
                }
            }) { () -> Void in
        }
        return out_sym_key_package
    }
}
