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
import Crypto

public struct PinProtection: ProtectionStrategy {
    public let keychain: Keychain
    private let pin: String
    
    public init(pin: String, keychain: Keychain) {
        self.pin = pin
        self.keychain = keychain
    }
    
    private static let saltKeychainKey = String(describing: PinProtection.self) + ".salt"
    private static let numberOfIterations: Int = 32768
    enum Errors: Error {
        case saltNotFound
        case failedToDeriveKey
    }
    
    public func lock(value: Keymaker.Key) throws {
        let salt = PinProtection.generateRandomValue(length: 8)
        var error: NSError?
        guard let ethemeralKey = SubtleDeriveKey(pin, Data(salt), PinProtection.numberOfIterations, &error) else {
            throw error ?? Errors.failedToDeriveKey
        }
        let locked = try Locked<Keymaker.Key>(clearValue: value, with: ethemeralKey.bytes)
        
        PinProtection.saveCyphertext(locked.encryptedValue, in: self.keychain)
        self.keychain.set(Data(salt), forKey: PinProtection.saltKeychainKey)
    }
    
    public func unlock(cypherBits: Data) throws -> Keymaker.Key {
        guard let salt = self.keychain.data(forKey: PinProtection.saltKeychainKey) else {
            throw Errors.saltNotFound
        }
        var error: NSError?
        guard let ethemeralKey = SubtleDeriveKey(pin, salt, PinProtection.numberOfIterations, &error) else {
            throw error ?? Errors.failedToDeriveKey
        }
        do {
            let locked = Locked<Keymaker.Key>.init(encryptedValue: cypherBits)
            return try locked.unlock(with: ethemeralKey.bytes)
        } catch let error {
            print(error)
            throw error
        }
    }
    
    public static func removeCyphertext(from keychain: Keychain) {
        (self as ProtectionStrategy.Type).removeCyphertext(from: keychain)
        keychain.remove(forKey: self.saltKeychainKey)
    }
}

extension Data {
    var bytes: Array<UInt8> {
        return Array<UInt8>(self)
    }
}
