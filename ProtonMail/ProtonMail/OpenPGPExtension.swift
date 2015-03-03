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
    
    func checkPassphrase(passphrase: String, forPrivateKey privateKey: String, publicKey: String, error: NSErrorPointer) -> Bool {
        var anError: NSError?
        
        if !SetupKeys(privateKey, pubKey: publicKey, pass: passphrase, error: &anError) {
            if error != nil {
                error.memory = anError
            }
            
            return false
        }

        return true
    }
}

// MARK: - OpenPGP String extension

extension String {
    
    func decryptWithPrivateKey(privateKey: String, passphrase: String, publicKey: String, error: NSErrorPointer) -> String? {
        let openPGP = OpenPGP()
        
        if !openPGP.checkPassphrase(passphrase, forPrivateKey: privateKey, publicKey: publicKey, error: error) {
            return nil
        }
        
        return openPGP.decrypt_message(self, error: error)
    }
    
    func encryptWithPublicKey(publicKey: String, error: NSErrorPointer) -> String? {
        return OpenPGP().encrypt_message(self, pub_key: publicKey, error: error)
    }
}
