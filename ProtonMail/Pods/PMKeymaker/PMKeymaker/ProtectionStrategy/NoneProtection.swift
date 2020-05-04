//
//  NoneProtection.swift
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

public struct NoneProtection: ProtectionStrategy {
    public static var keychainLabel: String {
        return "NoneProtection"
    }
    
    public let keychain: Keychain
    
    public init(keychain: Keychain) {
        self.keychain = keychain
    }
    
    public func lock(value: Key) throws {
        NoneProtection.saveCyphertext(Data(value), in: self.keychain)
    }
    
    public func unlock(cypherBits: Data) throws -> Key {
        return cypherBits.bytes
    }
}
