//
//  ProtectionStrategy.swift
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

public protocol ProtectionStrategy {
    var keychain: Keychain { get }
    func lock(value: Key) throws
    func unlock(cypherBits: Data) throws -> Key
    static var keychainLabel: String { get }
}
public extension ProtectionStrategy {
    static func saveCyphertext(_ cypher: Data, in keychain: Keychain) {
        keychain.set(cypher, forKey: self.keychainLabel)
    }
    static func removeCyphertext(from keychain: Keychain) {
        keychain.remove(forKey: self.keychainLabel)
    }
    func removeCyphertextFromKeychain() {
        self.keychain.remove(forKey: Self.keychainLabel)
    }
    static func getCypherBits(from keychain: Keychain) -> Data? {
        return keychain.data(forKey: self.keychainLabel)
    }
    func getCypherBits() -> Data? {
        return self.keychain.data(forKey: Self.keychainLabel)
    }
    
    static func generateRandomValue(length: Int) -> Key {
        var newKey = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, newKey.count, &newKey)
        guard status == 0 else {
            fatalError("failed to generate cryptographically secure value")
        }
        return newKey
    }
}
