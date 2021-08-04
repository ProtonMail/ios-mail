//
//  BioProtection.swift
//  ProtonCore-ProtonCore-Keymaker - Created on 18/10/2018.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import Security
import EllipticCurveKeyPair

private enum BioProtectionConstants {
    static let privateLabelKey = "BioProtection" + ".private"
    static let publicLabelKey  = "BioProtection" + ".public"
    static let legacyLabelKey  = "BioProtection" + ".legacy"
    static let versionKey      = "BioProtection" + ".version"
}

public struct BioProtection: ProtectionStrategy {
    public static var keychainLabel: String {
        return "BioProtection"
    }
    
    private typealias Constants = BioProtectionConstants
    public let keychain: Keychain
    private let version: Version = .v1
    
    enum Version: String {
        case lagcy = "0"
        case v1 = "1"
        init(raw: String?) {
            let rawValue = raw ?? "0"
            switch rawValue {
            case "1":
                self = .v1
            default:
                self = .lagcy
            }
        }
    }
    
    public init(keychain: Keychain) {
        self.keychain = keychain
    }
    
    private static func makeAsymmetricEncryptor(in keychain: Keychain) -> EllipticCurveKeyPair.Manager {
        let publicAccessControl = EllipticCurveKeyPair.AccessControl(protection: kSecAttrAccessibleAlwaysThisDeviceOnly, flags: [.userPresence, .privateKeyUsage])
        let privateAccessControl = EllipticCurveKeyPair.AccessControl(protection: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, flags: [.userPresence, .privateKeyUsage])
        let config = EllipticCurveKeyPair.Config(publicLabel: Constants.publicLabelKey,
                                                  privateLabel: Constants.privateLabelKey,
                                                  operationPrompt: "", // "MUCH IMPORTANT SO NEED", //removed by PM's request
                                                  publicKeyAccessControl: publicAccessControl,
                                                  privateKeyAccessControl: privateAccessControl,
                                                  publicKeyAccessGroup: keychain.accessGroup,
                                                  privateKeyAccessGroup: keychain.accessGroup,
                                                  token: .secureEnclave)
        return EllipticCurveKeyPair.Manager(config: config)
    }
    
    // for iOS older than 10.3 - not capable of elliptic curve encryption
    private static func makeSymmetricEncryptor(in keychain: Keychain) -> MainKey {
        guard let key = keychain.data(forKey: Constants.legacyLabelKey) else {
            let oldAccessibility = keychain.accessibility
            let oldAuthPolicy = keychain.authenticationPolicy
            
            keychain.switchAccessibilitySettings(.afterFirstUnlockThisDeviceOnly, authenticationPolicy: .userPresence)
            
            let ethemeralKey = BioProtection.generateRandomValue(length: 32)
            keychain.set(Data(ethemeralKey), forKey: Constants.legacyLabelKey)

            keychain.switchAccessibilitySettings(oldAccessibility, authenticationPolicy: oldAuthPolicy)
            return ethemeralKey
        }
        return key.bytes
    }
    
    public func lock(value: MainKey) throws {
        let locked = try Locked<MainKey>(clearValue: value) { cleartext -> Data in
            if #available(iOS 10.3, *) {
                let encryptor = BioProtection.makeAsymmetricEncryptor(in: self.keychain)
                return try encryptor.encrypt(Data(cleartext))
            } else {
                let ethemeral = BioProtection.makeSymmetricEncryptor(in: self.keychain)
                let locked = try Locked<MainKey>(clearValue: cleartext, with: ethemeral)
                return locked.encryptedValue
            }
        }
        BioProtection.saveCyphertext(locked.encryptedValue, in: self.keychain)
        self.keychain.set(self.version.rawValue, forKey: Constants.versionKey)
    }
    
    public func unlock(cypherBits: Data) throws -> MainKey {
        let locked = Locked<MainKey>(encryptedValue: cypherBits)
        let cleardata = try locked.unlock { cyphertext -> MainKey in
            if #available(iOS 10.3, *) {
                let encryptor = BioProtection.makeAsymmetricEncryptor(in: self.keychain)
                return try encryptor.decrypt(cyphertext).bytes
            } else {
                let curVer: Version = Version.init(raw: self.keychain.string(forKey: Constants.versionKey))
                do {
                    switch curVer {
                    case .lagcy:
                        let ethemeral = BioProtection.makeSymmetricEncryptor(in: self.keychain)
                        let key = try locked.lagcyUnlock(with: ethemeral)
                        try self.lock(value: key)
                        return key
                    default:
                        let ethemeral = BioProtection.makeSymmetricEncryptor(in: self.keychain)
                        return try locked.unlock(with: ethemeral)
                    }
                } catch let error {
                    throw error
                }
            }
        }
        return cleardata
    }
    
    public static func removeCyphertext(from keychain: Keychain) {
        (self as ProtectionStrategy.Type).removeCyphertext(from: keychain)
        try? BioProtection.makeAsymmetricEncryptor(in: keychain).deleteKeyPair()
        keychain.remove(forKey: Constants.legacyLabelKey)
        keychain.remove(forKey: Constants.versionKey)
    }
}
