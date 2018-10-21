//
//  PinProtection.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 18/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import CryptoSwift
import UICKeyChainStore

struct PinProtection: ProtectionStrategy {
    private let pin: String
    init(pin: String) {
        self.pin = pin
    }
    
    private static let saltKeychainKey = String(describing: PinProtection.self) + ".salt"
    private static let numberOfIterations: Int = 2000 // bigger number works very slow on iPhone 5S
    enum Errors: Error {
        case saltNotFound
    }
    
    func lock(value: Keymaker.Key) throws {
        let salt = PinProtection.generateRandomValue(length: 8)
        let ethemeralKey = try PKCS5.PBKDF2(password: Array(pin.utf8), salt: salt, iterations: PinProtection.numberOfIterations, variant: .sha256).calculate()
        let locked = try Locked<Keymaker.Key>(clearValue: value, with: ethemeralKey)
        
        PinProtection.saveCyphertextInKeychain(locked.encryptedValue)
        self.keychain.setData(Data(bytes: salt), forKey: PinProtection.saltKeychainKey)
    }
    
    func unlock(cypherBits: Data) throws -> Keymaker.Key {
        guard let salt = self.keychain.data(forKey: PinProtection.saltKeychainKey) else {
            throw Errors.saltNotFound
        }
        do {
            let ethemeralKey = try PKCS5.PBKDF2(password: Array(pin.utf8), salt: salt.bytes, iterations: PinProtection.numberOfIterations, variant: .sha256).calculate()
            let locked = Locked<Keymaker.Key>.init(encryptedValue: cypherBits)
            return try locked.unlock(with: ethemeralKey)
        } catch let error {
            print(error)
            throw error
        }
    }
    
    static func removeCyphertextFromKeychain() {
        (self as ProtectionStrategy.Type).removeCyphertextFromKeychain()
        self.keychain.removeItem(forKey: self.saltKeychainKey)
    }
}

extension PinProtection {
    static var keychain: UICKeyChainStore {
        return sharedKeychain.keychain
    }
    
    var keychain: UICKeyChainStore {
        return sharedKeychain.keychain
    }
}
