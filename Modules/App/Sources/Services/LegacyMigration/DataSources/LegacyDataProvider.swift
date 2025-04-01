// Copyright (c) 2025 Proton Technologies AG
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
import InboxCore

struct LegacyDataProvider {
    enum Key: String, CaseIterable {
        // session data
        case authCredentials = "authKeychainStoreKeyProtectedWithMainKey"
        case userInfos = "usersInfoKeyProtectedWithMainKey"

        // settings
        case alternativeRouting = "doh_flag"
        case combineContacts = "combine_contact_flag"
        case darkMode = "dark_mode_flag"

        // signatures
        case addressSignatureStatusPerUser = "user_with_default_signature_status"
        case mobileSignatureContentPerUser = "user_with_local_mobile_signature_mainKeyProtected"
        case mobileSignatureStatusPerUser = "user_with_local_mobile_signature_status"
    }

    private let userDefaults: TestableUserDefaults

    init(userDefaults: TestableUserDefaults = .init(suiteName: "group.ch.protonmail.protonmail")) {
        self.userDefaults = userDefaults
    }

    func data(forKey key: Key) -> Data? {
        userDefaults.data(forKey: key.rawValue)
    }

    func dictionary<ValueType>(forKey key: Key) -> [String: ValueType] {
        object(forKey: key) as? [String: ValueType] ?? [:]
    }

    func object(forKey key: Key) -> Any? {
        userDefaults.object(forKey: key.rawValue)
    }

    func removeAll() {
        userDefaults.removePersistentDomain(forName: userDefaults.suiteName)
    }
}
