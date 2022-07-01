//
//  AddressKey_v2.swift
//  ProtonCore-DataModel - Created on 26.04.22.
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

public struct AddressKey_v2: Decodable, Equatable {
    public let id: String
    public let version: Int
    public let privateKey: String
    public let token, signature: String?
    public let primary: Bool, active: Bool
    public let flags: Flags

    public struct Flags: OptionSet, Decodable {
        public let rawValue: UInt8
        
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        /// 1: Can use key to verify signatures
        public static let verifySignatures          = Flags(rawValue: 1 << 0)
        /// 2: Can use key to encrypt new data
        public static let encryptNewData            = Flags(rawValue: 1 << 1)
        /// 4: Belongs to an external address
        public static let belongsToExternalAddress  = Flags(rawValue: 1 << 2)
    }

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case version = "Version"
        case privateKey = "PrivateKey"
        case token = "Token"
        case signature = "Signature"
        case primary = "Primary"
        case active = "Active"
        case flags = "Flags"
    }
    
    public init(
        id: String,
        version: Int,
        privateKey: String,
        token: String?,
        signature: String?,
        primary: Bool,
        active: Bool,
        flags: Flags
    ) {
        self.id = id
        self.version = version
        self.privateKey = privateKey
        self.token = token
        self.signature = signature
        self.primary = primary
        self.active = active
        self.flags = flags
    }
    
    // MARK: - Decodable

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        version = try container.decode(Int.self, forKey: .version)
        privateKey = try container.decode(String.self, forKey: .privateKey)
        token = try container.decodeIfPresent(String.self, forKey: .token)
        signature = try container.decodeIfPresent(String.self, forKey: .signature)
        primary = try container.decodeBoolFromInt(forKey: .primary)
        active = try container.decodeBoolFromInt(forKey: .active)
        flags = try container.decode(Flags.self, forKey: .flags)
    }
}
