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

struct BioProtection: ProtectionStrategy {
    var keychainGroup: String?
    
    private func makeAsymmetricEncryptor() -> EllipticCurveKeyPair.Manager {
        let publicAccessControl = EllipticCurveKeyPair.AccessControl(protection: kSecAttrAccessibleAlwaysThisDeviceOnly, flags: [.userPresence, .privateKeyUsage])
        let privateAccessControl = EllipticCurveKeyPair.AccessControl(protection: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, flags: [.userPresence, .privateKeyUsage])
        let config = EllipticCurveKeyPair.Config(publicLabel: String(describing: BioProtection.self) + ".public",
                                                  privateLabel: String(describing: BioProtection.self) + ".private",
                                                  operationPrompt: "MUCH IMPORTANT SO NEED",
                                                  publicKeyAccessControl: publicAccessControl,
                                                  privateKeyAccessControl: privateAccessControl,
                                                  publicKeyAccessGroup: self.keychainGroup,
                                                  privateKeyAccessGroup: self.keychainGroup,
                                                  fallbackToKeychainIfSecureEnclaveIsNotAvailable: false)
        return EllipticCurveKeyPair.Manager(config: config)
    }
    
    func lock(value: Keymaker.Key) throws {
        let locked = try Locked<Keymaker.Key>(clearValue: value) { cleartext -> Data in
            if #available(iOS 10.3, *) {
                let encryptor = self.makeAsymmetricEncryptor()
                return try encryptor.encrypt(Data(bytes: cleartext))
            } else {
                fatalError("pre ios10.3")
            }
        }
        
        self.saveCyphertextInKeychain(locked.encryptedValue)
    }
    
    func unlock(cypherBits: Data) throws -> Keymaker.Key {
        let locked = Locked<Keymaker.Key>(encryptedValue: cypherBits)
        let cleardata = try locked.unlock { cyphertext -> Keymaker.Key in
            if #available(iOS 10.3, *) {
                let encryptor = self.makeAsymmetricEncryptor()
                return try encryptor.decrypt(cyphertext).bytes
            } else {
                fatalError("pre ios10.3")
            }
        }
        
        return cleardata
    }
}
