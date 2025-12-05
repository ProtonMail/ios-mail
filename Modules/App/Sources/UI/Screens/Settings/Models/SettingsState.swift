// Copyright (c) 2024 Proton Technologies AG
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

import InboxCore
import SwiftUI
import proton_app_uniffi

struct SettingsState: Copying {
    var accountInfo: AccountInfo?
    var accountSettings: [AccountSettings]
    var storageInfo: StorageInfo?
    let preferences: [SettingsPreference]
    var userSettings: UserSettings? {
        didSet {
            updateAccountSettings()
        }
    }
    var hasMailboxPassword: Bool {
        didSet {
            updateAccountSettings()
        }
    }

    var showSignInToAnotherDevice: Bool {
        !(userSettings?.flags.edmOptOut ?? true)
    }

    mutating func updateAccountSettings() {
        accountSettings = .stale

        if hasMailboxPassword {
            accountSettings.replace([.changePassword], with: [.changeLoginPassword, .changeMailboxPassword])
        }

        if showSignInToAnotherDevice {
            accountSettings.insert(.qrLogin, at: 0)
        }
    }
}

extension SettingsState {
    static var initial: Self {
        .init(
            accountInfo: nil,
            accountSettings: .stale,
            preferences: SettingsPreference.allCases,
            userSettings: nil,
            hasMailboxPassword: false
        )
    }
}

private extension Array where Element == AccountSettings {
    static var stale: [Element] {
        [.changePassword, .securityKeys]
    }
}
