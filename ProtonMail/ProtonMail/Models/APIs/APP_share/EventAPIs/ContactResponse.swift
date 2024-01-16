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

struct ContactResponse: Decodable {
    let id: String
    let action: Int
    let contact: Contact?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case action = "Action"
        case contact = "Contact"
    }

    struct Contact: Decodable {
        let id: String
        let name: String
        let uid: String
        let size: Int
        let createTime: Int
        let modifyTime: Int
        let cards: [VCardData]
        let contactEmails: [ContactEmail]
        let labelIDs: [String]

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case id = "ID"
            case name = "Name"
            case uid = "UID"
            case size = "Size"
            case createTime = "CreateTime"
            case modifyTime = "ModifyTime"
            case cards = "Cards"
            case contactEmails = "ContactEmails"
            case labelIDs = "LabelIDs"
        }

        // swiftlint:disable:next nesting
        struct VCardData: Codable {
            let type: Int
            let data: String
            let signature: String?

            // swiftlint:disable:next nesting
            enum CodingKeys: String, CodingKey {
                case type = "Type"
                case data = "Data"
                case signature = "Signature"
            }
        }
    }
}
