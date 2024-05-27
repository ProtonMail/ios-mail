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

struct MailWebFixtureQuarkResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case userId = "ID"
        case name = "Name"
        case password = "Password"
        case status = "Status"
        case recovery = "Recovery"
        case recoveryPhone = "RecoveryPhone"
        case authVersion = "AuthVersion"
        case email = "Email"
        case addressID = "AddressID"
        case decryptedAddressId = "AddressID (decrypt)"
        case keySalt = "KeySalt"
        case keyFingerprint = "KeyFingerprint"
        case mailboxPassword = "MailboxPassword"
        case decryptedUserId = "ID (decrypt)"
    }

    let userId: String
    let name: String
    let password: String
    let status: String
    let recovery: String
    let recoveryPhone: String?
    let authVersion: String
    let email: String
    let addressID: String?
    let decryptedAddressId: String?
    let keySalt: String?
    let keyFingerprint: String?
    let mailboxPassword: String?
    let decryptedUserId: String
}
