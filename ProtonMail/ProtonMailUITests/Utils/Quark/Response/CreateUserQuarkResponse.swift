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

struct CreateUserQuarkResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case userId = "ID"
        case decryptedUserId = "Dec_ID"
        case name = "Name"
        case password = "Password"
        case status = "Status"
        case recovery = "Recovery"
        case recoveryPhone = "RecoveryPhone"
        case authVersion = "AuthVersion"
        case email = "Email"
        case addressID = "AddressID"
        case statusInfo = "StatusInfo"
    }

    let userId: String
    let decryptedUserId: Int
    let name: String?
    let password: String
    let status: Int
    let recovery: String
    let recoveryPhone: String
    let authVersion: Int
    let email: String?
    let addressID: String?
    let statusInfo: String
}
