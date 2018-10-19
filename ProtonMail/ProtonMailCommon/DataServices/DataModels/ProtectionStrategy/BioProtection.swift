//
//  BioProtection.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 18/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import Security
import CryptoSwift

struct BioProtection: ProtectionStrategy {
    enum Errors: Error {
        case accessControlError
        case unableToGenerateKeyPair
        case unableToEncryptDataWithPublicKey
        case unableToGetPrivateKeyFromSE
        case unableToDecryptDataWithPrivateKey
    }
    
    var keychainGroup: String
    private let publicLabel: String = "mainKey.public"
    private let privateLabel: String = "mainKey.private"
    
    func lock(value: Keymaker.Key) throws {
        if #available(iOS 10.0, *) {
            // 1. get enclosing key pair from SE
            // 2. encrypt mainKey with public key
            // 3. save publicKey in keychain
            // 4. save encryptedMainKey in keychain
            
            var error: Unmanaged<CFError>?
            let access = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                         kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                                                         .privateKeyUsage,
                                                         &error)!
            guard error == nil else {
                throw Errors.accessControlError
            }
            
            let privateKeyAttributes: Dictionary<String, Any> = [
                kSecAttrIsPermanent as String:      true,
                kSecAttrApplicationTag as String:   self.privateLabel,
                kSecAttrAccessControl as String:    access
            ]
            let attributes: Dictionary<String, Any> = [
                kSecAttrKeyType as String:          kSecAttrKeyTypeECSECPrimeRandom as String,
                kSecAttrKeySizeInBits as String:    256,
                kSecAttrTokenID as String:          kSecAttrTokenIDSecureEnclave,
                kSecPrivateKeyAttrs as String:      privateKeyAttributes
                
            ]
            
            var publicKey, privateKey: SecKey!
            let status = SecKeyGeneratePair(attributes as CFDictionary, &publicKey, &privateKey)
            guard status == 0, publicKey != nil, privateKey != nil else {
                throw Errors.unableToGenerateKeyPair
                // TODO: check on non-SecureEnclave-capable device with ios10-11
            }
            try! self.savePublicKeyInKeychain(publicKey) // FIXME: do we need this publicKey ever again?
            try! self.savePrivateKeyInKeychain(privateKey)
            
            let locked = try Locked<Keymaker.Key>(clearValue: value) { cleartext -> Data in
                var error: Unmanaged<CFError>?
                let cypherdata = SecKeyCreateEncryptedData(publicKey,
                                                           SecKeyAlgorithm.eciesEncryptionStandardX963SHA256AESGCM,
                                                           Data(bytes: cleartext) as CFData,
                                                           &error)
                guard error == nil, cypherdata != nil else {
                    throw Errors.unableToEncryptDataWithPublicKey
                }
                return cypherdata! as Data
            }
            
            self.saveCyphertextInKeychain(locked.encryptedValue)
            //try self.savePublicKeyInKeychain(publicKey!) // do we need this at all?
        } else {
            fatalError()
            // TODO: save mainKey in keychain with touchID access _shrug_
        }
    }
    
    func unlock(cypherBits: Data) throws -> Keymaker.Key {
        if #available(iOS 10.0, *) {
            // 1. get privatekey from SE
            // 3. decrypt cypherbits with privatekey
            // 4. return data
            guard let privateKey = self.getPrivateKeyFromSE() else {
                throw Errors.unableToGetPrivateKeyFromSE
            }
            let locked = Locked<Keymaker.Key>(encryptedValue: cypherBits)
            let cleardata = try locked.unlock { cyphertext -> Keymaker.Key in
                var error: Unmanaged<CFError>?
                let cleardata = SecKeyCreateDecryptedData(privateKey,
                                                          SecKeyAlgorithm.eciesEncryptionStandardX963SHA256AESGCM,
                                                          cyphertext as CFData,
                                                          &error)
                guard error == nil, cleardata != nil else {
                    throw Errors.unableToDecryptDataWithPrivateKey
                }
                return (cleardata! as Data).bytes
            }
            
            return cleardata
        } else {
            fatalError()
            // TODO: get keychain item with touchID access
        }
    }
    
    @available(iOS 10.0, *)
    private func savePublicKeyInKeychain(_ publicKey: SecKey) throws {
        var query: [String: Any] = [
            // TODO
        ]
        query[kSecAttrAccessGroup as String] = self.keychainGroup
        
        var raw: CFTypeRef?
        var status = SecItemAdd(query as CFDictionary, &raw)
        if status == errSecDuplicateItem {
            status = SecItemDelete(query as CFDictionary)
            status = SecItemAdd(query as CFDictionary, &raw)
        }
        
        guard status == errSecSuccess else {
            throw NSError.init(domain: String(describing: Keymaker.self), code: 1, localizedDescription: "Failed to save publicKEy in keychain")
        }
    }
    @available(iOS 10.0, *)
    private func savePrivateKeyInKeychain(_ privateKey: SecKey) throws {
        var query: [String: Any] = [
            // TODO
        ]
        query[kSecAttrAccessGroup as String] = self.keychainGroup
        
        var raw: CFTypeRef?
        var status = SecItemAdd(query as CFDictionary, &raw)
        if status == errSecDuplicateItem {
            status = SecItemDelete(query as CFDictionary)
            status = SecItemAdd(query as CFDictionary, &raw)
        }
        
        guard status == errSecSuccess else {
            throw NSError.init(domain: String(describing: Keymaker.self), code: 1, localizedDescription: "Failed to save publicKEy in keychain")
        }
    }
    
    @available(iOS 10.0, *)
    private func getPublicKeyFromKeychain() -> SecKey? {
        var query: [String: Any] = [
            // TODO
        ]
        query[kSecAttrAccessGroup as String] = self.keychainGroup
        return getKey(query: query)
    }

    @available(iOS 10.0, *)
    private func getPrivateKeyFromSE() -> SecKey? {
        var query: [String: Any] = [
            // TODO
        ]
        query[kSecAttrAccessGroup as String] = self.keychainGroup
        var privateKey: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &privateKey)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        return privateKey as! SecKey
    }
    
    private func getKey(query: Dictionary<String, Any>) -> SecKey? {
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
            let response = result as? Dictionary<String, Any>,
            case let key = response[kSecValueRef as String] as! SecKey else
        {
            return nil
        }
        return key
    }
}
