//
//  Key+Codable.swift
//  ProtonCore-DataModel - Created on 4/19/21.
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

extension Key {
    enum CodingKeys: String, CodingKey {
        case keyID = "ID"
        case privateKey
        case flags
        
        case token
        case signature
        
        case activation
        
        case primary
        case active
        case version
    }
}

extension Key: Codable {
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let keyID = try container.decode(String.self, forKey: .keyID)
        let privateKey = try container.decodeIfPresent(String.self, forKey: .privateKey)
        
        let flags = try container.decodeIfPresent(Int.self, forKey: .flags)
        
        let token = try container.decodeIfPresent(String.self, forKey: .token)
        let signature = try container.decodeIfPresent(String.self, forKey: .signature)
        
        let activation = try container.decodeIfPresent(String.self, forKey: .activation)
        
        let active = try container.decodeIfPresent(Int.self, forKey: .active)
        let version = try container.decodeIfPresent(Int.self, forKey: .version)
        
        let primary = try container.decodeIfPresent(Int.self, forKey: .primary)
        
        self.init(keyID: keyID, privateKey: privateKey,
                  keyFlags: flags ?? 0,
                  token: token, signature: signature, activation: activation,
                  active: active ?? 0,
                  version: version ?? 0,
                  primary: primary ?? 0)
    }
    
    /// object encode . we don't use it right now. maybe in the future
    /// - Parameter encoder:
    /// - Throws:
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.keyID, forKey: .keyID)
        try container.encodeIfPresent(self.privateKey, forKey: .privateKey)
        
        try container.encodeIfPresent(self.keyFlags, forKey: .flags)
        
        try container.encodeIfPresent(self.token, forKey: .token)
        try container.encodeIfPresent(self.signature, forKey: .signature)
        
        try container.encodeIfPresent(self.activation, forKey: .activation)
        
        try container.encodeIfPresent(self.active, forKey: .active)
        try container.encodeIfPresent(self.version, forKey: .version)
        
        try container.encodeIfPresent(self.primary, forKey: .primary)
    }
}
