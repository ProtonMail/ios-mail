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
import EllipticCurveKeyPair
import UICKeyChainStore

struct BioProtection: ProtectionStrategy {
    private static var privateLabelKey = String(describing: BioProtection.self) + ".private"
    private static var publicLabelKey = String(describing: BioProtection.self) + ".public"
    private static var legacyLabelKey = String(describing: BioProtection.self) + ".legacy"
    
    private static func makeAsymmetricEncryptor() -> EllipticCurveKeyPair.Manager {
        let publicAccessControl = EllipticCurveKeyPair.AccessControl(protection: kSecAttrAccessibleAlwaysThisDeviceOnly, flags: [.userPresence, .privateKeyUsage])
        let privateAccessControl = EllipticCurveKeyPair.AccessControl(protection: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, flags: [.userPresence, .privateKeyUsage])
        let config = EllipticCurveKeyPair.Config(publicLabel: self.publicLabelKey,
                                                  privateLabel: self.privateLabelKey,
                                                  operationPrompt: "MUCH IMPORTANT SO NEED",
                                                  publicKeyAccessControl: publicAccessControl,
                                                  privateKeyAccessControl: privateAccessControl,
                                                  publicKeyAccessGroup: self.keychain.accessGroup,
                                                  privateKeyAccessGroup: self.keychain.accessGroup,
                                                  fallbackToKeychainIfSecureEnclaveIsNotAvailable: false)
        return EllipticCurveKeyPair.Manager(config: config)
    }
    
    
    // for iOS older than 10.3 - not capable of elliptic curve encryption
    private static func makeSymmetricEncryptor() -> Keymaker.Key {
        guard let key = self.keychain.data(forKey: self.legacyLabelKey) else {
            let oldAccessibility = self.keychain.accessibility
            let oldAuthPolicy = self.keychain.authenticationPolicy
            
            self.keychain.setAccessibility(.afterFirstUnlockThisDeviceOnly, authenticationPolicy: .userPresence)
            
            let ethemeralKey = self.generateRandomValue(length: 32)
            self.keychain.setData(Data(bytes: ethemeralKey), forKey: self.legacyLabelKey)

            self.keychain.setAccessibility(oldAccessibility, authenticationPolicy: oldAuthPolicy)
            return ethemeralKey
        }
        return key.bytes
    }
    
    func lock(value: Keymaker.Key) throws {
        let locked = try Locked<Keymaker.Key>(clearValue: value) { cleartext -> Data in
            if #available(iOS 10.3, *) {
                let encryptor = BioProtection.makeAsymmetricEncryptor()
                return try encryptor.encrypt(Data(bytes: cleartext))
            } else {
                let ethemeral = BioProtection.makeSymmetricEncryptor()
                let locked = try Locked(clearValue: cleartext, with: ethemeral)
                return locked.encryptedValue
            }
        }
        
        BioProtection.saveCyphertextInKeychain(locked.encryptedValue)
    }
    
    func unlock(cypherBits: Data) throws -> Keymaker.Key {
        let locked = Locked<Keymaker.Key>(encryptedValue: cypherBits)
        let cleardata = try locked.unlock { cyphertext -> Keymaker.Key in
            if #available(iOS 10.3, *) {
                let encryptor = BioProtection.makeAsymmetricEncryptor()
                return try encryptor.decrypt(cyphertext).bytes
            } else {
                let ethemeral = BioProtection.makeSymmetricEncryptor()
                return try locked.unlock(with: ethemeral)
            }
        }
        
        return cleardata
    }
    
    static func removeCyphertextFromKeychain() {
        (self as ProtectionStrategy.Type).removeCyphertextFromKeychain()
        try? BioProtection.makeAsymmetricEncryptor().deleteKeyPair()
        self.keychain.removeItem(forKey: self.legacyLabelKey)
    }
}

extension BioProtection {
    static var keychain: UICKeyChainStore {
        return sharedKeychain.keychain
    }
    
    var keychain: UICKeyChainStore {
        return sharedKeychain.keychain
    }
}
