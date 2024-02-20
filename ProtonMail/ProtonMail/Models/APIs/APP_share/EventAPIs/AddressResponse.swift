// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation
import ProtonCoreDataModel

struct AddressResponse: Decodable {
    let id: String
    let action: Int
    let address: Address?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case action = "Action"
        case address = "Address"
    }

    // TODO: Use Address_v2 in ProtonCoreDataModel
    struct Address: Decodable {
        let id, domainID, email: String
        let status, type, receive, send: Int
        let displayName, signature: String
        let order: Int
        let catchAll: Bool
        let confirmationState, hasKeys: Int
        let keys: [Key]

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case id = "ID"
            case domainID = "DomainID"
            case email = "Email"
            case status = "Status"
            case type = "Type"
            case receive = "Receive"
            case send = "Send"
            case displayName = "DisplayName"
            case signature = "Signature"
            case order = "Order"
            case catchAll = "CatchAll"
            case confirmationState = "ConfirmationState"
            case hasKeys = "HasKeys"
            case keys = "Keys"
        }

        func convertToProtonAddressModel() -> ProtonCoreDataModel.Address {
            return ProtonCoreDataModel.Address(
                addressID: id,
                domainID: domainID,
                email: email,
                send: .init(rawValue: send) ?? .inactive,
                receive: .init(rawValue: receive) ?? .inactive,
                status: .init(rawValue: status) ?? .disabled,
                type: .init(rawValue: type) ?? .protonDomain,
                order: order,
                displayName: displayName,
                signature: signature,
                hasKeys: hasKeys,
                keys: keys.map { keyResponse in
                    ProtonCoreDataModel.Key(
                        keyID: keyResponse.id,
                        privateKey: keyResponse.privateKey,
                        keyFlags: keyResponse.flags,
                        token: keyResponse.token,
                        signature: keyResponse.signature,
                        activation: keyResponse.activation,
                        active: keyResponse.active,
                        version: keyResponse.version,
                        primary: keyResponse.primary,
                        isUpdated: false
                    )
                }
            )
        }
    }

    struct Key: Decodable {
        let id: String
        let primary: Int
        let flags: Int
        let active: Int
        let version: Int
        let activation: String?
        let privateKey: String
        let token: String
        let signature: String

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case id = "ID"
            case primary = "Primary"
            case flags = "Flags"
            case active = "Active"
            case version = "Version"
            case activation = "Activation"
            case privateKey = "PrivateKey"
            case token = "Token"
            case signature = "Signature"
        }
    }
}
