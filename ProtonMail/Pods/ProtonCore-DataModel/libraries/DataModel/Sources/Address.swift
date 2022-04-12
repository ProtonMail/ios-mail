//
//  Address.swift
//  ProtonCore-DataModel - Created on 17/03/2020.
//
//  Copyright (c) 2019 Proton Technologies AG
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

@objc public final class Address: NSObject, Codable {
    
    @available(*, deprecated, renamed: "String")
    public typealias AddressID = String
    public enum AddressType: Int, Codable {
        case protonDomain = 1       // First address the user created using a Proton Mail domain
        case protonAlias = 2        // Subsequent addresses created using a Proton Mail domain.
        case customDomain = 3       // Custom domain address.
        case premiumDomain = 4      // Premium "pm.me" domain.
        case externalAddress = 5    // External address
    }
    public enum AddressSendReceive: Int, Codable {
        case inactive = 0   // inactive - cannot send or receive, pm.me addresses have inactive for free users
        case active = 1     // active address (Status = 1 and has key)
    }
    public enum AddressStatus: Int, Codable {
        case disabled = 0   // disabled
        case enabled = 1    // enabled, can be set by user
    }
    
    public let addressID: String
    public let domainID: String?
    // email address name
    public let email: String
    public let send: AddressSendReceive
    public let receive: AddressSendReceive
    public let status: AddressStatus
    public let type: AddressType
    // address order
    public let order: Int
    public let displayName: String
    public let signature: String
    public let hasKeys: Int
    public let keys: [Key]
    
    public init(addressID: String, domainID: String?, email: String,
                send: AddressSendReceive, receive: AddressSendReceive, status: AddressStatus, type: AddressType, order: Int, displayName: String, signature: String, hasKeys: Int, keys: [Key]) {
        self.addressID = addressID
        self.domainID = domainID
        self.email = email
        self.send = send
        self.receive = receive
        self.status = status
        self.type = type
        self.order = order
        self.displayName = displayName
        self.signature = signature
        self.hasKeys = hasKeys
        self.keys = keys
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        addressID = try values.decode(String.self, forKey: .addressID)
        domainID = try values.decodeIfPresent(String.self, forKey: .domainID)
        email = try values.decode(String.self, forKey: .email)
        send = try values.decode(AddressSendReceive.self, forKey: .send)
        receive = try values.decode(AddressSendReceive.self, forKey: .receive)
        status = try values.decode(AddressStatus.self, forKey: .status)
        type = try values.decode(AddressType.self, forKey: .type)
        order = try values.decode(Int.self, forKey: .order)
        displayName = try values.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        signature = try values.decodeIfPresent(String.self, forKey: .signature) ?? ""
        
        if let _hasKeys = try values.decodeIfPresent(Int.self, forKey: .hasKeys) {
            hasKeys = _hasKeys
        } else {
            hasKeys = 0
        }
        
        if let _keys = try values.decodeIfPresent([Key].self, forKey: .keys) {
            keys = _keys
        } else {
            keys = []
        }
    }

    public func withUpdated(order newOrder: Int? = nil,
                            displayName newDisplayName: String? = nil,
                            signature newSignature: String? = nil) -> Address {
        Address(addressID: addressID,
                domainID: domainID,
                email: email,
                send: send,
                receive: receive,
                status: status,
                type: type,
                order: newOrder ?? order,
                displayName: newDisplayName ?? displayName,
                signature: newSignature ?? signature,
                hasKeys: hasKeys,
                keys: keys)
    }
}
extension Address {
    override public func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Address else {
            return false
        }
        return self.addressID == rhs.addressID &&
            self.domainID == rhs.domainID &&
            self.email == rhs.email &&
            self.send == rhs.send &&
            self.receive == rhs.receive &&
            self.status == rhs.status &&
            self.type == rhs.type &&
            self.order == rhs.order &&
            self.displayName == rhs.displayName &&
            self.signature == rhs.signature &&
            self.hasKeys == rhs.hasKeys &&
            self.keys == rhs.keys
    }
}
