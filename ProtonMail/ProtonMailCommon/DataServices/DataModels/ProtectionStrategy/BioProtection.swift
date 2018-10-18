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
    let secureEnclaveLabel: String = "mainKey"
    
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
                throw NSError(domain: String(describing: Keymaker.self), code: 0, localizedDescription: "Failed to generate SE elliptic keypair")
                // TODO: check on non-SecureEnclave-capable device with ios10-11
            }
            
            let locked = try Locked<Keymaker.Key>(clearValue: value) { cleartext -> Data in
                var error: Unmanaged<CFError>?
                let cypherdata = SecKeyCreateEncryptedData(publicKey!,
                                                           SecKeyAlgorithm.eciesEncryptionStandardX963SHA256AESGCM,
                                                           Data(bytes: cleartext) as CFData,
                                                           &error)
                guard error == nil, cypherdata != nil else {
                    throw NSError(domain: String(describing: Keymaker.self), code: 0, localizedDescription: "Failed to encrypt data with SE publicKey")
                }
                return cypherdata! as Data
            }
            
            self.saveCyphertextInKeychain(locked.encryptedValue)
            // TODO: save public key in keychain
        } else {
            // TODO: save mainKey in keychain with touchID access _shrug_
        }
    }
}
