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

struct AddressResponse: Decodable {
    let id: String
    let action: Int
    let address: Address

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
        let order, priority: Int
        let catchAll, protonMX: Bool
        let confirmationState, hasKeys, flags: Int
        let keys: [Key]
        let signedKeyList: SignedKeyList

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
            case priority = "Priority"
            case catchAll = "CatchAll"
            case protonMX = "ProtonMX"
            case confirmationState = "ConfirmationState"
            case hasKeys = "HasKeys"
            case flags = "Flags"
            case keys = "Keys"
            case signedKeyList = "SignedKeyList"
        }
    }

    struct Key: Decodable {
        let id: String
        let primary: Int
        let flags: Int
        let fingerprint: String
        let fingerprints: [String]
        let publicKey: String
        let active: Int
        let addressForwardingID: String?
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
            case fingerprint = "Fingerprint"
            case fingerprints = "Fingerprints"
            case publicKey = "PublicKey"
            case active = "Active"
            case addressForwardingID = "AddressForwardingID"
            case version = "Version"
            case activation = "Activation"
            case privateKey = "PrivateKey"
            case token = "Token"
            case signature = "Signature"
        }
    }

    struct SignedKeyList: Decodable {
        let minEpochID: Int
        let maxEpochID: Int
        let expectedMinEpochID: Int?
        let data: String
        let obsolescenceToken: String?
        let revision: Int
        let signature: String

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case minEpochID = "MinEpochID"
            case maxEpochID = "MaxEpochID"
            case expectedMinEpochID = "ExpectedMinEpochID"
            case data = "Data"
            case obsolescenceToken = "ObsolescenceToken"
            case revision = "Revision"
            case signature = "Signature"
        }
    }
}
