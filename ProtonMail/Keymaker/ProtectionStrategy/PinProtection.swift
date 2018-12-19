//
//  PinProtection.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 18/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import Crypto
import UICKeyChainStore

public struct PinProtection: ProtectionStrategy {
    public let keychain: UICKeyChainStore
    private let pin: String
    
    public init(pin: String, keychain: UICKeyChainStore) {
        self.pin = pin
        self.keychain = keychain
    }
    
    private static let saltKeychainKey = String(describing: PinProtection.self) + ".salt"
    private static let numberOfIterations: Int = 2000 // bigger number works very slow on iPhone 5S
    enum Errors: Error {
        case saltNotFound
        case failedToDeriveKey
    }
    
    public func lock(value: Keymaker.Key) throws {
        let salt = PinProtection.generateRandomValue(length: 8)
        var error: NSError?
        guard let ethemeralKey = CryptoDeriveKey(pin, salt, &error) else {
            throw error ?? Errors.failedToDeriveKey
        }
        let locked = try Locked<Keymaker.Key>(clearValue: value, with: ethemeralKey)
        
        PinProtection.saveCyphertext(locked.encryptedValue, in: self.keychain)
        self.keychain.setData(Data(bytes: salt), forKey: PinProtection.saltKeychainKey)
    }
    
    public func unlock(cypherBits: Data) throws -> Keymaker.Key {
        guard let salt = self.keychain.data(forKey: PinProtection.saltKeychainKey) else {
            throw Errors.saltNotFound
        }
        var error: NSError?
        guard let ethemeralKey = CryptoDeriveKey(pin, salt, &error) else {
            throw error ?? Errors.failedToDeriveKey
        }
        do {
            let locked = Locked<Keymaker.Key>.init(encryptedValue: cypherBits)
            return try locked.unlock(with: ethemeralKey)
        } catch let error {
            print(error)
            throw error
        }
    }
    
    public static func removeCyphertext(from keychain: UICKeyChainStore) {
        (self as ProtectionStrategy.Type).removeCyphertext(from: keychain)
        keychain.removeItem(forKey: self.saltKeychainKey)
    }
}
