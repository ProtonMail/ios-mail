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
    
    func checkPassphrase(passphrase: String, forPrivateKey privateKey: String, error: NSErrorPointer?) -> Bool {
        if !checkPassphrase(privateKey, passphrase: passphrase) {
            return false
        }
        return true
    }
    
    func generateKey(passphrase: String, userName: String, error: NSErrorPointer?) -> PMNOpenPgpKey? {
        var out_new_key : PMNOpenPgpKey?
        SwiftTryCatch.tryBlock({ () -> Void in
            out_new_key = self.generateKey(userName, domain: "protonmail.com", passphrase: passphrase)
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
    func decryptWithPrivateKey(privateKey: String, passphrase: String, error: NSErrorPointer?) -> String? {
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
    
    func encryptWithPublicKey(publicKey: String, error: NSErrorPointer?) -> String? {
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
    
    func encryptWithPublicKey(publicKey: String, fileName:String, error: NSErrorPointer?) -> PMNEncryptPackage? {
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
    
    //    func encryptWithPublicKeys(publicKeys: NSMutableDictionary, fileName:String, error: NSErrorPointer?) -> NSMutableDictionary? {
    //        let publicKey = publicKeys["self"] as! String;
    //
    //        sharedOpenPGP.encryptAttachmentSingleKey(publicKey, unencryptData: self, fileName: fileName)
    //
    ////        var out_packet [String, PMNEncryptPackage] =
    ////        for (key, value) in publicKeys {
    ////
    ////
    ////            sharedOpenPGP.encryptAttachmentSingleKey(publicKey: String, unencryptData: NSData, fileName: String)
    ////        }
    ////
    //
    ////        - (NSMutableDictionary*) encrypt_attachments:(NSData *)unencrypt_att fileNam:(NSString*)name pub_keys:(NSMutableDictionary*)pub_keys error:(NSError**) err
    ////        {
    ////            NSMutableDictionary *dictX = [[NSMutableDictionary alloc] init];
    ////
    ////            std::string unencrypt_attachment = std::string((char* )[unencrypt_att bytes], [unencrypt_att length]);
    ////            std::string session_key = generat_session_key();
    ////            std::string fileName = [name UTF8String];
    ////
    ////            for(id key in pub_keys)
    ////            {
    ////                std::string user_pub_key = [pub_keys[key] UTF8String];
    ////                PGPPublicKey pub(user_pub_key);
    ////                PGPMessage enrypted_session_key = encrypt_pka_only_session(pub, session_key);
    ////                std::string enrypted_session_key_data = enrypted_session_key.write(1);
    ////                [dictX setObject:[NSData dataWithBytes: enrypted_session_key_data.c_str() length:enrypted_session_key_data.length()] forKey:key];
    ////            }
    ////
    ////            PGPMessage encrypted_att = encrypt_pka_only_data(session_key, unencrypt_attachment, fileName, 9, 0);
    ////            std::string endryp_dat = encrypted_att.write(1);
    ////            [dictX setObject:[NSData dataWithBytes: endryp_dat.c_str() length:endryp_dat.length()] forKey:@"DataPacket"];
    ////
    ////            return dictX;
    ////        }
    //        return nil
    //    }
    
    func getSessionKeyFromPubKeyPackage(privateKey: String, passphrase: String, publicKey: String, error: NSErrorPointer?) -> NSData? {
        var key_session_out : NSData?
        SwiftTryCatch.tryBlock({ () -> Void in
            key_session_out = sharedOpenPGP.getPublicKeySessionKey(self, privateKey: privateKey, passphrase: passphrase)
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
    
    func decryptAttachment(keyPackage:NSData!, passphrase: String, publicKey: String, privateKey: String, error: NSErrorPointer?) -> NSData? {
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
}
