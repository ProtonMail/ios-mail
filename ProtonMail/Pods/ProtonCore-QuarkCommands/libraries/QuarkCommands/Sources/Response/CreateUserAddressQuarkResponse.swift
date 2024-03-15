//
//  CreateUserAddressQuarkResponse.swift
//  ProtonCore-QuarkCommands - Created on 08.12.2023.
//
// Copyright (c) 2023. Proton Technologies AG
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

public struct CreateUserAddressQuarkResponse: Codable {
    public enum CodingKeys: String, CodingKey {
        case addressID = "AddressID"
        case email = "Email"
        case type = "Type"
        case status = "Status"
    }

    public let addressID: Int
    public let email: String
    public let type: Int
    public let status: Int
}
