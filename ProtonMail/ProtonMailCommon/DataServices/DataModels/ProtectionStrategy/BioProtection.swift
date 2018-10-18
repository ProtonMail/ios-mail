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
        case unableToGenerateKeyPair
        case unableToEncryptDataWithPublicKey
        case unableToGetPrivateKeyFromSE
        case unableToDecryptDataWithPrivateKey
    }
    
    var keychainGroup: String?
    private let secureEnclaveLabel: String = "mainKey"
    
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
            let privateKeyAttributes: Dictionary<String, Any> = [
                kSecAttrIsPermanent as String:      true,
                kSecAttrApplicationTag as String:   self.secureEnclaveLabel,
                kSecAttrAccessControl as String:    access
            ]
            let attributes: Dictionary<String, Any> = [
                kSecAttrKeyType as String:          kSecAttrKeyTypeECSECPrimeRandom as String,
                kSecAttrKeySizeInBits as String:    256,
                kSecAttrTokenID as String:          kSecAttrTokenIDSecureEnclave,
                kSecPrivateKeyAttrs as String:      privateKeyAttributes
                
            ]
            
            var publicKey, privateKey: SecKey?
            let status = SecKeyGeneratePair(attributes as CFDictionary, &publicKey, &privateKey)
            guard status == 0, publicKey != nil else {
                throw Errors.unableToGenerateKeyPair
                // TODO: check on non-SecureEnclave-capable device with ios10-11
            }
            
            let locked = try Locked<Keymaker.Key>(clearValue: value) { cleartext -> Data in
                var error: Unmanaged<CFError>?
                let cypherdata = SecKeyCreateEncryptedData(publicKey!,
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
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom as String,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrApplicationTag as String: self.secureEnclaveLabel,
            kSecValueRef as String: publicKey,
            kSecAttrIsPermanent as String: true,
            kSecReturnData as String: true
        ]
        if let group = self.keychainGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        
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
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom as String,
            kSecAttrApplicationTag as String: self.secureEnclaveLabel,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecReturnData as String: true,
            kSecReturnRef as String: true,
            kSecReturnPersistentRef as String: true,
        ]
        if let group = self.keychainGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        return getKey(query: query)
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
    
    @available(iOS 10.0, *)
    private func getPrivateKeyFromSE() -> SecKey? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrLabel as String: self.secureEnclaveLabel,
            kSecReturnRef as String: true,
            kSecUseOperationPrompt as String: "MUCH IMPORTANT SO NEED",
        ]
        if let group = self.keychainGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        return getKey(query: query)
    }
}
