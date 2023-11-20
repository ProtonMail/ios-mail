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

struct NewContactEmailsResponse: Decodable {
    let id: String
    let action: Int
    let contactEmail: ContactEmail?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case action = "Action"
        case contactEmail = "ContactEmail"
    }
}

struct ContactEmail: Decodable {
    let id: String
    let name: String
    let email: String
    let isProton: Int
    let type: [String]
    let defaults: Int
    let order: Int
    let lastUsedTime: Int
    let contactID: String
    let labelIDs: [String]

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case name = "Name"
        case email = "Email"
        case isProton = "IsProton"
        case type = "Type"
        case defaults = "Defaults"
        case order = "Order"
        case lastUsedTime = "LastUsedTime"
        case contactID = "ContactID"
        case labelIDs = "LabelIDs"
    }
}
