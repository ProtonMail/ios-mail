//
//  CreateUserQuarkResponse.swift
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

public struct CreateUserQuarkResponse: Codable {
    public enum CodingKeys: String, CodingKey {
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
        case decryptedUserId = "Dec_ID"
        case statusInfo = "StatusInfo"
    }

    public let userId: String
    public let name: String?
    public let password: String
    public let status: Int
    public let recovery: String?
    public let recoveryPhone: String?
    public let authVersion: Int
    public let email: String?
    public let addressID: String?
    public let decryptedAddressId: Int?
    public let keySalt: String?
    public let keyFingerprint: String?
    public let mailboxPassword: String?
    public let decryptedUserId: Int
    public let statusInfo: String
}
