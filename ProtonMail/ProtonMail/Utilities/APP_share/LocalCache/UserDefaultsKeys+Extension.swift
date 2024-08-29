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

extension UserDefaultsKeys {
    static let areContactsCached = plainKey<Int>(named: "isContactsCached", defaultValue: 0)

    static let contactsHistoryTokenPerUser = plainKey(
        named: "contacts_history_token_per_user",
        defaultValue: [String: Data]()
    )

    static let darkModeStatus = rawRepresentableKey(named: "dark_mode_flag", defaultValue: DarkModeStatus.followSystem)

    static let isCombineContactOn = plainKey<Bool>(named: "combine_contact_flag", defaultValue: false)

    static let isAutoImportContactsOn = plainKey(named: "auto_import_contacts_flag", defaultValue: [String: Bool]())

    static let isDohOn = plainKey(named: "doh_flag", defaultValue: true)

    static let isPMMEWarningDisabled = plainKey(named: "isPM_MEWarningDisabledKey", defaultValue: false)

    static let lastTourVersion = plainKey(named: "last_tour_viersion", ofType: Int.self)

    static let didSignUpOnThisDevice = plainKey(named: "didSignUpOnThisDevice", ofType: Bool.self)

    static let pinFailedCount = plainKey(named: "lastPinFailedTimes", defaultValue: 0)

    static let showServerNoticesNextTime = plainKey(named: "showServerNoticesNextTime", defaultValue: "0")

    static let cachedServerNotices = plainKey(named: "cachedServerNotices", defaultValue: [String]())

    /// Dictionary of events with last sent timestamp per user. e.g. ["user-id-1": ["mail.ios.auto_import_contacts-heartbeat": 1707922894]]
    static let telemetryFrequency = plainKey(named: "telemetry_frequency_flag", defaultValue: [String: [String: Int]]())
}
