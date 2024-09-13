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

import Foundation

enum SettingsItemType: Hashable {
    case account(AccountSettings)
    case preference(SettingsPreference)

    struct DisplayData {
        let title: String
        let subtitle: String
        let webPage: ProtonAuthenticatedWebPage?
    }

    var displayData: DisplayData {
        switch self {
        case .account(let accountSettings):
            .init(title: accountSettings.name, subtitle: accountSettings.email, webPage: .accountSettings)
        case .preference(let settingsPreference):
            .init(
                title: settingsPreference.displayData.title.string,
                subtitle: settingsPreference.displayData.subtitle.string,
                webPage: settingsPreference.webPage
            )
        }
    }

}

private extension SettingsPreference {

    var webPage: ProtonAuthenticatedWebPage? {
        switch self {
        case .email:
            return .emailSettings
        case .foldersAndLabels:
            return .createFolderOrLabel
        case .filters:
            return .spamFiltersSettings
        case .privacyAndSecurity:
            return .privacySecuritySettings
        case .app:
            return nil
        }
    }

}
