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

struct LegacyDataProvider {
    enum Key: String, CaseIterable {
        case alternativeRouting = "doh_flag"
        case authCredentials = "authKeychainStoreKeyProtectedWithMainKey"
        case combineContacts = "combine_contact_flag"
        case darkMode = "dark_mode_flag"
        case userInfos = "usersInfoKeyProtectedWithMainKey"
    }

    private let userDefaults: TestableUserDefaults

    init(userDefaults: TestableUserDefaults = .init(suiteName: "group.ch.protonmail.protonmail")) {
        self.userDefaults = userDefaults
    }

    func data(forKey key: Key) -> Data? {
        userDefaults.data(forKey: key.rawValue)
    }

    func object(forKey key: Key) -> Any? {
        userDefaults.object(forKey: key.rawValue)
    }

    func removeAll() {
        userDefaults.removeSuite(named: userDefaults.suiteName)
    }
}

final class TestableUserDefaults: UserDefaults {
    let suiteName: String

    init(suiteName: String) {
        self.suiteName = suiteName
        super.init(suiteName: suiteName)!
    }
}
