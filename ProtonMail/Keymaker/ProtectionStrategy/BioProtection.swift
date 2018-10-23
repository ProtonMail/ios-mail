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

public struct BioProtection: ProtectionStrategy {
    private static var privateLabelKey = String(describing: BioProtection.self) + ".private"
    private static var publicLabelKey = String(describing: BioProtection.self) + ".public"
    private static var legacyLabelKey = String(describing: BioProtection.self) + ".legacy"
    
    public let keychain: UICKeyChainStore
    
    public init(keychain: UICKeyChainStore) {
        self.keychain = keychain
    }
    
    private static func makeAsymmetricEncryptor(in keychain: UICKeyChainStore) -> EllipticCurveKeyPair.Manager {
        let publicAccessControl = EllipticCurveKeyPair.AccessControl(protection: kSecAttrAccessibleAlwaysThisDeviceOnly, flags: [.userPresence, .privateKeyUsage])
        let privateAccessControl = EllipticCurveKeyPair.AccessControl(protection: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, flags: [.userPresence, .privateKeyUsage])
        let config = EllipticCurveKeyPair.Config(publicLabel: self.publicLabelKey,
                                                  privateLabel: self.privateLabelKey,
                                                  operationPrompt: "MUCH IMPORTANT SO NEED",
                                                  publicKeyAccessControl: publicAccessControl,
                                                  privateKeyAccessControl: privateAccessControl,
                                                  publicKeyAccessGroup: keychain.accessGroup,
                                                  privateKeyAccessGroup: keychain.accessGroup,
                                                  fallbackToKeychainIfSecureEnclaveIsNotAvailable: false)
        return EllipticCurveKeyPair.Manager(config: config)
    }
    
    
    // for iOS older than 10.3 - not capable of elliptic curve encryption
    private static func makeSymmetricEncryptor(in keychain: UICKeyChainStore) -> Keymaker.Key {
        guard let key = keychain.data(forKey: self.legacyLabelKey) else {
            let oldAccessibility = keychain.accessibility
            let oldAuthPolicy = keychain.authenticationPolicy
            
            keychain.setAccessibility(.afterFirstUnlockThisDeviceOnly, authenticationPolicy: .userPresence)
            
            let ethemeralKey = BioProtection.generateRandomValue(length: 32)
            keychain.setData(Data(bytes: ethemeralKey), forKey: self.legacyLabelKey)

            keychain.setAccessibility(oldAccessibility, authenticationPolicy: oldAuthPolicy)
            return ethemeralKey
        }
        return key.bytes
    }
    
    public func lock(value: Keymaker.Key) throws {
        let locked = try Locked<Keymaker.Key>(clearValue: value) { cleartext -> Data in
            if #available(iOS 10.3, *) {
                let encryptor = BioProtection.makeAsymmetricEncryptor(in: self.keychain)
                return try encryptor.encrypt(Data(bytes: cleartext))
            } else {
                let ethemeral = BioProtection.makeSymmetricEncryptor(in: self.keychain)
                let locked = try Locked(clearValue: cleartext, with: ethemeral)
                return locked.encryptedValue
            }
        }
        
        BioProtection.saveCyphertext(locked.encryptedValue, in: self.keychain)
    }
    
    public func unlock(cypherBits: Data) throws -> Keymaker.Key {
        let locked = Locked<Keymaker.Key>(encryptedValue: cypherBits)
        let cleardata = try locked.unlock { cyphertext -> Keymaker.Key in
            if #available(iOS 10.3, *) {
                let encryptor = BioProtection.makeAsymmetricEncryptor(in: self.keychain)
                return try encryptor.decrypt(cyphertext).bytes
            } else {
                let ethemeral = BioProtection.makeSymmetricEncryptor(in: self.keychain)
                return try locked.unlock(with: ethemeral)
            }
        }
        
        return cleardata
    }
    
    public static func removeCyphertext(from keychain: UICKeyChainStore) {
        (self as ProtectionStrategy.Type).removeCyphertext(from: keychain)
        try? BioProtection.makeAsymmetricEncryptor(in: keychain).deleteKeyPair()
        keychain.removeItem(forKey: self.legacyLabelKey)
    }
}
