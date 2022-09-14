//
//  Armored.swift
//  ProtonCore-Crypto - Created on 07/15/22.
//
//  Copyright (c) 2022 Proton Technologies AG
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation
#if canImport(Crypto_VPN)
import Crypto_VPN
#elseif canImport(Crypto)
import Crypto
#endif
import ProtonCore_DataModel

/// predefined armored types
public enum ArmoredType {
    public enum Key {}
    public enum Message {}
    public enum Signature {}
}

/// predefind unarmored types
public enum UnArmoredType {
    public enum Key {}
}

/// armored
public struct Armored<Type> {
    public init(value: String) {
        self.value = value
    }
    
    public let value: String
    
    public var isEmpty: Bool {
        value.isEmpty
    }
}

/// unarmored
public struct UnArmored<Type> {
    public init(value: Data) {
        self.value = value
    }
    public let value: Data
}

// alias
public typealias UnArmoredKey = UnArmored<UnArmoredType.Key>
public typealias ArmoredKey = Armored<ArmoredType.Key>
public typealias ArmoredMessage = Armored<ArmoredType.Message>
public typealias ArmoredSignature = Armored<ArmoredType.Signature>

// extra helpers
extension Armored where Type == ArmoredType.Key {
    
    public func encrypt(clearText: String) throws -> ArmoredMessage {
        return try Encryptor.encrypt(publicKey: self, cleartext: clearText)
    }
    
    public func encrypt(raw: Data) throws -> ArmoredMessage {
        return try Encryptor.encrypt(publicKey: self, clearData: raw)
    }
    
    public func unArmor() throws -> UnArmoredKey {
        let unarmored = try throwingNotNil { error in
            return ArmorUnarmor(self.value, &error)
        }
        return UnArmoredKey.init(value: unarmored)
    }
    
    public var armoredPublicKey: String {
        return self.value.publicKey
    }
    
    public var fingerprint: String {
        return self.value.fingerprint
    }
    
    public var sha256Fingerprint: [String] {
        return self.value.sha256Fingerprint
    }
}

// extra helpers
extension Armored where Type == ArmoredType.Message {
    /// splt encrypted armored message to keypacket & data packet
    /// - Returns: `SplitPacket`
    public func split() throws -> SplitPacket {
        let split = SplitMessage(fromArmored: self.value)
        guard let data = split?.dataPacket else {
            throw ArmoredError.noDataPacket
        }
        guard let key = split?.keyPacket else {
            throw ArmoredError.noKeyPacket
        }
        return SplitPacket.init(dataPacket: data, keyPacket: key)
    }
}
