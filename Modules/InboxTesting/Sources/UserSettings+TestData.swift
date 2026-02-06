// Copyright (c) 2026 Proton Technologies AG
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
import proton_app_uniffi

public extension UserSettings {
    static func settings(crashReports: Bool, telemetry: Bool) -> UserSettings {
        .init(
            crashReports: crashReports,
            dateFormat: .ddMmYyyy,
            density: .comfortable,
            deviceRecovery: false,
            earlyAccess: false,
            email: .init(notify: 0, reset: 0, status: 0, value: .notUsed),
            flags: .init(welcomed: false, edmOptOut: false),
            hideSidePanel: false,
            highSecurity: .init(eligible: false, value: false),
            invoiceText: .notUsed,
            locale: .notUsed,
            logAuth: .advanced,
            news: 0,
            password: .init(mode: 0, expirationTime: nil),
            phone: .init(notify: 0, reset: 0, status: 0, value: .notUsed),
            referral: nil,
            sessionAccountRecovery: false,
            telemetry: telemetry,
            timeFormat: .default,
            twoFactorAuth: .init(allowed: .fido2, enabled: .fido2, expirationTime: nil, registeredKeys: []),
            weekStart: .default,
            welcome: false
        )
    }
}
