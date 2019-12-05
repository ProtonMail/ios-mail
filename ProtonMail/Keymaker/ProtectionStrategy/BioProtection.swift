//
//  BioProtection.swift
//  ProtonMail - Created on 18/10/2018.
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
import Security
import EllipticCurveKeyPair

public struct BioProtection: ProtectionStrategy {
    private static var privateLabelKey = String(describing: BioProtection.self) + ".private"
    private static var publicLabelKey = String(describing: BioProtection.self) + ".public"
    private static var legacyLabelKey = String(describing: BioProtection.self) + ".legacy"
    
    public let keychain: Keychain
    
    public init(keychain: Keychain) {
        self.keychain = keychain
    }
    
    private static func makeAsymmetricEncryptor(in keychain: Keychain) -> EllipticCurveKeyPair.Manager {
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
    private static func makeSymmetricEncryptor(in keychain: Keychain) -> Keymaker.Key {
        guard let key = keychain.data(forKey: self.legacyLabelKey) else {
            let oldAccessibility = keychain.accessibility
            let oldAuthPolicy = keychain.authenticationPolicy
            
            keychain.switchAccessibilitySettings(.afterFirstUnlockThisDeviceOnly, authenticationPolicy: .userPresence)
            
            let ethemeralKey = BioProtection.generateRandomValue(length: 32)
            keychain.set(Data(ethemeralKey), forKey: self.legacyLabelKey)

            keychain.switchAccessibilitySettings(oldAccessibility, authenticationPolicy: oldAuthPolicy)
            return ethemeralKey
        }
        return key.bytes
    }
    
    public func lock(value: Keymaker.Key) throws {
        let locked = try Locked<Keymaker.Key>(clearValue: value) { cleartext -> Data in
            if #available(iOS 10.3, *) {
                let encryptor = BioProtection.makeAsymmetricEncryptor(in: self.keychain)
                return try encryptor.encrypt(Data(cleartext))
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
    
    public static func removeCyphertext(from keychain: Keychain) {
        (self as ProtectionStrategy.Type).removeCyphertext(from: keychain)
        try? BioProtection.makeAsymmetricEncryptor(in: keychain).deleteKeyPair()
        keychain.remove(forKey: self.legacyLabelKey)
    }
}
