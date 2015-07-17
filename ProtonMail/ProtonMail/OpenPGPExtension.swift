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

extension OpenPGP {
    enum ErrorCode: Int {
        case badPassphrase = 10001
        case noPrivateKey = 10004
        case badProtonMailPGPMessage = 10006
    }
    
    func checkPassphrase(passphrase: String, forPrivateKey privateKey: String, error: NSErrorPointer?) -> Bool {
        var anError: NSError?
        
        if !CheckPassphrase(privateKey, pass: passphrase, error: &anError) {
            if let error = error {
                error.memory = anError
            }
            
            return false
        }

        return true
    }
    
    
    func generateKey(passphrase: String, userName: String, error: NSErrorPointer?) -> NSMutableDictionary? {
        var anError: NSError?
        if let keys = generate_key(passphrase, username: userName, error: &anError) {
            return keys
        }
        if let error = error {
            error.memory = anError
        }
        return nil
    }
    
    func updatePassphrase(privateKey: String, publicKey: String, old_pass: String, new_pass: String, error: NSErrorPointer?) -> String? {
        var anError: NSError?
        if !SetupKeys(privateKey, pubKey: publicKey, pass: old_pass, error: &anError) {
            if let error = error {
                error.memory = anError
            }
            return nil
        }
        if let new_privkey = update_key_password(old_pass, new_pwd: new_pass, error: &anError) {
            return new_privkey
        }
        if let error = error {
            error.memory = anError
        }
        return nil
    }
}

// MARK: - OpenPGP String extension

extension String {
    
    func decryptWithPrivateKey(privateKey: String, passphrase: String, error: NSErrorPointer?) -> String? {
        let openPGP = OpenPGP()
        
        if !openPGP.CheckPassphrase(privateKey, pass: passphrase, error: nil) {
            return nil
        }
        
        var anError: NSError?
        if let decrypt = openPGP.decrypt_message(privateKey, pass: passphrase, encrypted: self, error: &anError) {
            return decrypt
        }
        
        if let error = error {
            error.memory = anError
        }
        
        return nil
    }
    
    func decryptWithPrivateKey(forLogin privateKey: String, passphrase: String, error: NSErrorPointer?) -> String? {
        let openPGP = OpenPGP()
        
        if !openPGP.checkPassphrase(passphrase, forPrivateKey: privateKey, error: error) {
            return nil
        }
        
        var anError: NSError?
        if let decrypt = openPGP.decrypt_message(self, error: &anError) {
            return decrypt
        }
        
        if let error = error {
            error.memory = anError
        }
        
        return nil
    }
    
    func decryptWithPrivateKey(privateKey: String, passphrase: String, publicKey: String, error: NSErrorPointer?) -> String? {
        let openPGP = OpenPGP()
         var anError: NSError?
        
        if !openPGP.SetupKeys(privateKey, pubKey: publicKey, pass: passphrase, error: &anError) {
            if let error = error {
                error.memory = anError
            }

            return nil
        }
        
       
        if let decrypt = openPGP.decrypt_message(self, error: &anError) {
            return decrypt
        }
        
        if let error = error {
            error.memory = anError
        }
        
        return nil
    }
    
    func encryptWithPublicKey(publicKey: String, error: NSErrorPointer?) -> String? {
        
        var anError: NSError?
        if let encrypt = OpenPGP().encrypt_message(self, pub_key: publicKey, error: &anError) {
            return encrypt
        }
        
        if let error = error {
            error.memory = anError
        }
        
        return nil
    }
    
    func encryptWithPassphrase(passphrase: String, error: NSErrorPointer?) -> String? {
        
        var anError: NSError?
        if let encrypt = OpenPGP().encrypt_message_aes(self, pwd: passphrase, error: &anError) {
            return encrypt
        }
        
        if let error = error {
            error.memory = anError
        }
        
        return nil
    }
    
    func decryptWithPassphrase(passphrase: String, error: NSErrorPointer?) -> String? {
        
        var anError: NSError?
        if let encrypt = OpenPGP().decrypt_message_aes(self, pwd: passphrase, error: &anError) {
            return encrypt
        }
        
        if let error = error {
            error.memory = anError
        }
        
        return nil
    }
}



extension NSData {
    
    func encryptWithPublicKey(publicKey: String, fileName:String, error: NSErrorPointer?) -> NSMutableDictionary? {
        
        var anError: NSError?
        if let encrypt = OpenPGP().encrypt_attachment(self, fileNam: fileName, pub_key: publicKey, error: &anError) {
            return encrypt
        }
        
        if let error = error {
            error.memory = anError
        }
        
        return nil
    }
    
    func encryptWithPublicKeys(publicKeys: NSMutableDictionary, fileName:String, error: NSErrorPointer?) -> NSMutableDictionary? {
        
        var anError: NSError?

        if let encrypt = OpenPGP().encrypt_attachments(self,fileNam:fileName,  pub_keys: publicKeys, error: &anError) {
            return encrypt
        }
        
        if let error = error {
            error.memory = anError
        }
        
        return nil
    }

    func getSessionKeyFromPubKeyPackage(privateKey: String, passphrase: String, publicKey: String, error: NSErrorPointer?) -> NSData? {
        
        var anError: NSError?
        let openPGP = OpenPGP()
        
        if !openPGP.SetupKeys(privateKey, pubKey: publicKey, pass: passphrase, error: &anError) {
            return nil
        }

        if let encrypt = openPGP.getPublicKeySessionKey(self, error: &anError) {
            return encrypt
        }
        
        if let error = error {
            error.memory = anError
        }
        
        return nil
    }
    
    func getPublicSessionKeyPackage(publicKey: String, error: NSErrorPointer?) -> NSData? {
        
        var anError: NSError?
        let openPGP = OpenPGP()

        if let encrypt = openPGP.getNewPublicKeyPackage(self, pub_key: publicKey, error: &anError) {
            return encrypt
        }
        
        if let error = error {
            error.memory = anError
        }
        
        return nil
    }
    
    func getSymmetricSessionKeyPackage(pwd: String, error: NSErrorPointer?) -> NSData? {
        
        var anError: NSError?
        let openPGP = OpenPGP()
        
        if let encrypt = openPGP.getNewSymmetricKeyPackage(self, password: pwd, error: &anError) {
            return encrypt
        }
        
        if let error = error {
            error.memory = anError
        }
        
        return nil
    }
    
    func decryptAttachment(keyPackage:NSData!, passphrase: String, publicKey: String, privateKey: String, error: NSErrorPointer?) -> NSData? {
        
        var anError: NSError?
        let openPGP = OpenPGP()
        
        if !openPGP.SetupKeys(privateKey, pubKey: publicKey, pass: passphrase, error: &anError) {
            return nil
        }
        
        if let encrypt = openPGP.decrypt_attachment(keyPackage, data: self, error: &anError) {
            return encrypt
        }
        
        if let error = error {
            error.memory = anError
        }
        
        return nil
    }
}
