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

struct IncomingDefaultResponse: Decodable {
    let id: String
    let action: Int
    let incomingDefault: IncomingDefault?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case action = "Action"
        case incomingDefault = "IncomingDefault"
    }

    struct IncomingDefault: Decodable {
        let id: String
        let location: Int
        let type: Int
        let time: Int
        let email: String

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case id = "ID"
            case location = "Location"
            case type = "Type"
            case time = "Time"
            case email = "Email"
        }
    }
}
