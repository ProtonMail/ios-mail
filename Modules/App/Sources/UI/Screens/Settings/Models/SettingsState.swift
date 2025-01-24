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

import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

struct SettingsState {
    let accountSettings: AccountSettings?
    let preferences: [SettingsPreference]
    let presentedWebPage: ProtonAuthenticatedWebPage?
}

extension SettingsState {

    static var initial: Self {
        .init(
            accountSettings: nil,
            preferences: .stale, 
            presentedWebPage: nil
        )
    }
    
    func copy(with accountDetails: AccountDetails) -> Self {
        .init(
            accountSettings: .init(
                name: accountDetails.name,
                email: accountDetails.email,
                avatarInfo: .init(
                    initials: accountDetails.avatarInformation.text,
                    color: Color(hex: accountDetails.avatarInformation.color)
                )
            ),
            preferences: preferences,
            presentedWebPage: presentedWebPage
        )
    }

    func copy(presentedWebPage: ProtonAuthenticatedWebPage?) -> Self {
        .init(accountSettings: accountSettings, preferences: preferences, presentedWebPage: presentedWebPage)
    }

}

private extension Array where Element == SettingsPreference {

    static var stale: [Element] {
        [.email, .foldersAndLabels, .filters, .privacyAndSecurity, .app]
    }

}
