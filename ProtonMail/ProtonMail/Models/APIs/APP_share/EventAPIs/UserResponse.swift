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

struct UserResponse: Decodable {
    let id: String
    let usedSpace: Int
    let maxSpace: Int
    let credit: Int
    let currency: String
    let subscribed: Int
    let keys: [Key]
    let maxUpload: Int
    let role: Int
    let delinquent: Int
    let createTime: Int
    let accountRecovery: ProtonCoreDataModel.AccountRecovery?
    let lockedFlags: ProtonCoreDataModel.LockedFlags?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case usedSpace = "UsedSpace"
        case maxSpace = "MaxSpace"
        case credit = "Credit"
        case currency = "Currency"
        case subscribed = "Subscribed"
        case keys = "Keys"
        case maxUpload = "MaxUpload"
        case role = "Role"
        case delinquent = "Delinquent"
        case createTime = "CreateTime"
        case accountRecovery = "AccountRecovery"
        case lockedFlags = "LockedFlags"
    }

    struct Key: Decodable {
        let id: String
        let version: Int
        let primary: Int
        let recoverySecret: String?
        let recoverySecretSignature: String?
        let privateKey: String
        let fingerprint: String
        let active: Int

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case id = "ID"
            case version = "Version"
            case primary = "Primary"
            case recoverySecret = "RecoverySecret"
            case recoverySecretSignature = "RecoverySecretSignature"
            case privateKey = "PrivateKey"
            case fingerprint = "Fingerprint"
            case active = "Active"
        }
    }
}
