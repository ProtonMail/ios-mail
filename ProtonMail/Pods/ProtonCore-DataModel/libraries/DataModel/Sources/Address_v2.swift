//
//  Address_v2.swift
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

import Foundation

public struct Address_v2: Decodable, Equatable {
    public let id: String
    public let domainID: String?
    public let email: String
    public let send, receive: Bool
    public let status: Status
    public let type: `Type`
    public let order: Int
    public let displayName, signature: String
    public let keys: [AddressKey_v2]
    
    public enum Status: UInt8, Decodable {
        /// 0: disabled
        case disabled
        /// 1: enabled
        case enabled
        /// 2: deleting
        case deleting
    }
    
    public enum `Type`: UInt8, Decodable {
        /**
         * 1: The address a user registered with.
         * Only 1 address (@protonmail.com or @proton.me) per user for new users
         * but older users could have up to 3 of those:
         *  - protonmail.com
         *  - protonmail.ch
         *  - proton.me
         */
        case protonDomain = 1
        /**
         * 2: Additional addresses user can buy on one of our domains.
         * Each user can have zero to N of those
         */
        case protonAlias = 2
        /**
         * 3: Addresses users of organization with custom domain can create for one of their domains.
         * Each user can have zero to N of those
         */
        case customDomain = 3
        /**
         * 4: @pm.me addresses (receive only for free users)
         * Each user can have zero to N of those
         */
        case premiumDomain = 4
        /**
         * 5: Addresses on domains outside of Proton (eg: gmail.com)
         * Each user can have zero to N of those
         */
        case externalDomain = 5
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case domainID = "DomainID"
        case email = "Email"
        case send = "Send"
        case receive = "Receive"
        case status = "Status"
        case type = "Type"
        case order = "Order"
        case displayName = "DisplayName"
        case signature = "Signature"
        case keys = "Keys"
    }
    
    public init(
        id: String,
        domainID: String?,
        email: String,
        send: Bool,
        receive: Bool,
        status: Status,
        type: `Type`,
        order: Int,
        displayName: String,
        signature: String,
        keys: [AddressKey_v2]
    ) {
        self.id = id
        self.domainID = domainID
        self.email = email
        self.send = send
        self.receive = receive
        self.status = status
        self.type = type
        self.order = order
        self.displayName = displayName
        self.signature = signature
        self.keys = keys
    }
    
    // MARK: - Decodable
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        domainID = try container.decodeIfPresent(String.self, forKey: .domainID)
        email = try container.decode(String.self, forKey: .email)
        send = try container.decodeBoolFromInt(forKey: .send)
        receive = try container.decodeBoolFromInt(forKey: .receive)
        status = try container.decode(Status.self, forKey: .status)
        type = try container.decode(`Type`.self, forKey: .type)
        order = try container.decode(Int.self, forKey: .order)
        displayName = try container.decode(String.self, forKey: .displayName)
        signature = try container.decode(String.self, forKey: .signature)
        keys = try container.decode([AddressKey_v2].self, forKey: .keys)
    }
}
