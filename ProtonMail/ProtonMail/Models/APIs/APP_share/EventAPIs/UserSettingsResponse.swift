// swiftlint:disable nesting
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

struct UserSettingsResponse: Decodable {
    let email: Email
    let crashReports: Int
    let password: Password
    let passwordMode: Int
    let referral: Referral
    let telemetry: Int
    let twoFactorVerify: TwoFactorVerify
    let weekStart: Int

    enum CodingKeys: String, CodingKey {
        case email = "Email"
        case crashReports = "CrashReports"
        case passwordMode = "PasswordMode"
        case password = "Password"
        case referral = "Referral"
        case telemetry = "Telemetry"
        case twoFactorVerify = "2FA"
        case weekStart = "WeekStart"
    }

    struct Email: Decodable {
        let value: String?
        let notify: Int

        enum CodingKeys: String, CodingKey {
            case value = "Value"
            case notify = "Notify"
        }
    }

    struct TwoFactorVerify: Decodable {
        let enabled: Int

        enum CodingKeys: String, CodingKey {
            case enabled = "Enabled"
        }
    }

    struct Referral: Decodable {
        let link: String
        let eligible: Bool

        enum CodingKeys: String, CodingKey {
            case link = "Link"
            case eligible = "Eligible"
        }
    }

    struct Password: Decodable {
        let mode: Int

        enum CodingKeys: String, CodingKey {
            case mode = "Mode"
        }
    }
}
// swiftlint:enable nesting
