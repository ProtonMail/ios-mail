
//
//  OpenPGPExtension.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import Crypto
import OpenPGP
import ProtonCore_DataModel

extension Crypto {
    
    static func updateKeysPassword(_ old_keys : [Key], old_pass: String, new_pass: String ) throws -> [Key] {
        var outKeys : [Key] = [Key]()
        for okey in old_keys {
            do {
                let new_private_key = try self.updatePassphrase(privateKey: okey.privateKey, oldPassphrase: old_pass, newPassphrase: new_pass)
                let newK = Key(keyID: okey.keyID, privateKey: new_private_key, isUpdated: true)
                outKeys.append(newK)
            } catch {
                let newK = Key(keyID: okey.keyID, privateKey: okey.privateKey)
                outKeys.append(newK)
            }
        }
        
        guard outKeys.count == old_keys.count else {
            throw UpdatePasswordError.keyUpdateFailed.error
        }
        
        guard outKeys.count > 0 && outKeys[0].isUpdated == true else {
            throw UpdatePasswordError.keyUpdateFailed.error
        }
        
        for u_k in outKeys {
            if u_k.isUpdated == false {
                continue
            }
            let result = u_k.privateKey.check(passphrase: new_pass)
            guard result == true else {
                throw UpdatePasswordError.keyUpdateFailed.error
            }
        }
        return outKeys
    }
    
    
    
    
    static func updateAddrKeysPassword(_ old_addresses : [Address], old_pass: String, new_pass: String ) throws -> [Address] {
        var out_addresses = [Address]()
        for addr in old_addresses {
            var outKeys = [Key]()
            for okey in addr.keys {
                do {
                    let new_private_key = try Crypto.updatePassphrase(privateKey: okey.privateKey,
                                                                      oldPassphrase: old_pass,
                                                                      newPassphrase: new_pass)
                    let newK = Key(keyID: okey.keyID,
                                   privateKey: new_private_key,
                                   keyFlags: okey.keyFlags,
                                   token: nil,
                                   signature: nil,
                                   activation: nil,
                                   active: okey.active,
                                   version: okey.version,
                                   primary: okey.primary,
                                   isUpdated: true)
                    outKeys.append(newK)
                } catch {
                    let newK = Key(keyID: okey.keyID,
                                   privateKey: okey.privateKey,
                                   keyFlags: okey.keyFlags,
                                   token: nil,
                                   signature: nil,
                                   activation: nil,
                                   active: okey.active,
                                   version: okey.version,
                                   primary: okey.primary,
                                   isUpdated: false)
                    outKeys.append(newK)
                }
            }
            
            guard outKeys.count == addr.keys.count else {
                throw UpdatePasswordError.keyUpdateFailed.error
            }
            
            guard outKeys.count > 0 && outKeys[0].isUpdated == true else {
                throw UpdatePasswordError.keyUpdateFailed.error
            }
            
            for u_k in outKeys {
                if u_k.isUpdated == false {
                    continue
                }
                let result = u_k.privateKey.check(passphrase: new_pass)
                guard result == true else {
                    throw UpdatePasswordError.keyUpdateFailed.error
                }
            }
            let new_addr = Address(addressID: addr.addressID,
                                   domainID: addr.domainID,
                                   email: addr.email,
                                   send: addr.send,
                                   receive: addr.receive,
                                   status: addr.status,
                                   type: addr.type,
                                   order: addr.order,
                                   displayName: addr.displayName,
                                   signature: addr.signature,
                                   hasKeys: outKeys.isEmpty ? 0 : 1,
                                   keys: outKeys)
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
    func generateKey(_ passphrase: String, userName: String, domain:String, bits: Int32) throws -> PMNOpenPgpKey? {
        var out_new_key : PMNOpenPgpKey?
        try ObjC.catchException {
            let timeinterval = CryptoGetUnixTime()
            let int32Value = NSNumber(value: timeinterval).int32Value
            let email =  userName + "@" + domain
            out_new_key = self.generateKey(email, domain: email, passphrase: passphrase, bits: bits, time: int32Value)
            if out_new_key!.privateKey.isEmpty || out_new_key!.publicKey.isEmpty {
                out_new_key = nil
            }
        }
        return out_new_key
    }
    
    func generateRandomKeypair() throws -> (passphrase: String, publicKey: String, privateKey: String) {
        let passphrase = UUID().uuidString
        let username = UUID().uuidString
        let domain = "protonmail.com"
        guard let keypair = try self.generateKey(passphrase,
                                                 userName: (username + "@" + domain).isValidEmail() ? username : "noreply",
                                                 domain: domain,
                                                 bits: Int32(2048)) else
        {
            throw NSError(domain: #file, code: 1, localizedDescription: "Failed to generate random keypair")
        }
        return (passphrase, keypair.publicKey, keypair.privateKey)
    }
}


extension Data {
    func decryptAttachment(keyPackage: Data, userKeys: [Data], passphrase: String, keys: [Key]) throws -> Data? {
        var firstError : Error?
        for key in keys {
            do {
                if let token = key.token, let signature = key.signature { //have both means new schema. key is
                    if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
//                        PMLog.D(signature)
                        return try Crypto().decryptAttachment(keyPacket: keyPackage,
                                                              dataPacket: self,
                                                              privateKey: key.privateKey,
                                                              passphrase: plaitToken)
                    }
                } else if let token = key.token { //old schema with token - subuser. key is embed singed
                    if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        //TODO:: try to verify signature here embeded signature
                        return try Crypto().decryptAttachment(keyPacket: keyPackage,
                                                              dataPacket: self,
                                                              privateKey: key.privateKey,
                                                              passphrase: plaitToken)
                    }
                } else {//normal key old schema
                    return try Crypto().decryptAttachment(keyPacket: keyPackage,
                                                          dataPacket: self,
                                                          privateKey: userKeys,
                                                          passphrase: passphrase)
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
    
    
    func decryptAttachment(_ keyPackage: Data, passphrase: String, privKeys: [Data]) throws -> Data? {
        return try Crypto().decryptAttachment(keyPacket: keyPackage, dataPacket: self, privateKey: privKeys, passphrase: passphrase)
    }

    func decryptAttachmentWithSingleKey(_ keyPackage: Data, passphrase: String, privateKey: String) throws -> Data? {
        return try Crypto().decryptAttachment(keyPacket: keyPackage, dataPacket: self, privateKey: privateKey, passphrase: passphrase)
    }
    

    func signAttachment(byPrivKey: String, passphrase: String) throws -> String? {
        return try Crypto().signDetached(plainData: self, privateKey: byPrivKey, passphrase: passphrase)
    }
    
    func encryptAttachment(fileName:String, pubKey: String) throws -> SplitMessage? {
        return try Crypto().encryptAttachment(plainData: self, fileName: fileName, publicKey: pubKey)
    }
    
    // could remove and dirrectly use Crypto()
    static func makeEncryptAttachmentProcessor(fileName:String, totalSize: Int, pubKey: String) throws -> AttachmentProcessor {
        return try Crypto().encryptAttachmentLowMemory(fileName: fileName, totalSize: totalSize, publicKey: pubKey)
    }
    
    //key packet part
    func getSessionFromPubKeyPackage(_ passphrase: String, privKeys: [Data]) throws -> SymmetricKey? {
        return try Crypto().getSession(keyPacket: self, privateKeys: privKeys, passphrase: passphrase)
    }
    
    //key packet part
    func getSessionFromPubKeyPackage(addrPrivKey: String, passphrase: String) throws -> SymmetricKey? {
        return try Crypto().getSession(keyPacket: self, privateKey: addrPrivKey, passphrase: passphrase)
    }
    
    //key packet part
    func getSessionFromPubKeyPackage(userKeys: [Data], passphrase: String, keys: [Key]) throws -> SymmetricKey? {
        var firstError : Error?
        for key in keys {
            do {
                if let token = key.token, let signature = key.signature { //have both means new schema. key is
                    if let plainToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
//                        PMLog.D(signature)
                        return try Crypto().getSession(keyPacket: self, privateKey: key.privateKey, passphrase: plainToken)
                    }
                } else if let token = key.token { //old schema with token - subuser. key is embed singed
                    if let plainToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        //TODO:: try to verify signature here embeded signature
                        return try Crypto().getSession(keyPacket: self, privateKey: key.privateKey, passphrase: plainToken)
                    }
                } else {//normal key old schema
                    return try Crypto().getSession(keyPacket: self, privateKeys: userKeys, passphrase: passphrase)
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
}
