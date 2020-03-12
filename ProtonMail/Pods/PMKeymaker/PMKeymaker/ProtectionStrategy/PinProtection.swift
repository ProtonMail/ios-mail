//
//  PinProtection.swift
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

private enum GenericPinProtectionConstants {
    static let saltKeychainKey = "PinProtection" + ".salt"
    static let numberOfIterations: Int = 32768
}

public struct GenericPinProtection<SUBTLE: SubtleProtocol>: ProtectionStrategy {
    public let keychain: Keychain
    private let pin: String
    
    public init(pin: String, keychain: Keychain) {
        self.pin = pin
        self.keychain = keychain
    }
    
    private typealias Const = GenericPinProtectionConstants
    
    enum Errors: Error {
        case saltNotFound
        case failedToDeriveKey
    }
    
    public func lock(value: Key) throws {
        let salt = GenericPinProtection<SUBTLE>.generateRandomValue(length: 8)
        var error: NSError?
        guard let ethemeralKey = SUBTLE.DeriveKey(pin, Data(salt), Const.numberOfIterations, &error) else {
            throw error ?? Errors.failedToDeriveKey
        }
        let locked = try GenericLocked<Key, SUBTLE>(clearValue: value, with: ethemeralKey.bytes)
        
        GenericPinProtection<SUBTLE>.saveCyphertext(locked.encryptedValue, in: self.keychain)
        self.keychain.set(Data(salt), forKey: Const.saltKeychainKey)
    }
    
    public func unlock(cypherBits: Data) throws -> Key {
        guard let salt = self.keychain.data(forKey: Const.saltKeychainKey) else {
            throw Errors.saltNotFound
        }
        var error: NSError?
        guard let ethemeralKey = SUBTLE.DeriveKey(pin, salt, Const.numberOfIterations, &error) else {
            throw error ?? Errors.failedToDeriveKey
        }
        do {
            let locked = GenericLocked<Key, SUBTLE>.init(encryptedValue: cypherBits)
            return try locked.unlock(with: ethemeralKey.bytes)
        } catch let error {
            throw error
        }
    }
    
    public static func removeCyphertext(from keychain: Keychain) {
        (self as ProtectionStrategy.Type).removeCyphertext(from: keychain)
        keychain.remove(forKey: Const.saltKeychainKey)
    }
}

extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }
}
