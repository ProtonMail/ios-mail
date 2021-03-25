//
//  Address.swift
//  PMAuthentication - Created on 17/03/2020.
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

public struct Address: Codable {
    public typealias AddressID = String
    public let ID: AddressID
    public let domainID: String?
    public let email: String
    public let send: Int
    public let receive: Int
    public let status: Int
    public let type: Int
    public let order: Int
    public let displayName: String
    public let signature: String
    public let hasKeys: Int
    public let keys: [AddressKey]

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        ID = try values.decode(AddressID.self, forKey: .ID)
        domainID = try values.decodeIfPresent(String.self, forKey: .domainID)
        email = try values.decode(String.self, forKey: .email)
        send = try values.decode(Int.self, forKey: .send)
        receive = try values.decode(Int.self, forKey: .receive)
        status = try values.decode(Int.self, forKey: .status)
        type = try values.decode(Int.self, forKey: .type)
        order = try values.decode(Int.self, forKey: .order)
        displayName = try values.decode(String.self, forKey: .displayName)
        signature = try values.decode(String.self, forKey: .signature)

        if let _hasKeys = try values.decodeIfPresent(Int.self, forKey: .hasKeys) {
            hasKeys = _hasKeys
        } else {
            hasKeys = 0
        }

        if let _keys = try values.decodeIfPresent([AddressKey].self, forKey: .keys) {
            keys = _keys
        } else {
            keys = []
        }
    }
}

public struct AddressKey: Codable {
    public typealias AddressKeyID = String
    public let ID: AddressKeyID
    public let version: Int
    public let flags: Int
    public let privateKey: String
    public let token: String?
    public let signature: String?
    public let primary: Int
    
//    public let Activation: null
}

public struct AddressKeySalt: Codable {
    public typealias AddressKeySaltID = String
    public let ID: AddressKeySaltID
    public let keySalt: String?
}
