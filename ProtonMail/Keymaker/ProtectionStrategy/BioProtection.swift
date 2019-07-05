//
//  BioProtection.swift
//  ProtonMail - Created on 18/10/2018.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation
import Security
import EllipticCurveKeyPair

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
