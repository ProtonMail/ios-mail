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

import DesignSystem
import SwiftUI

enum SettingsPreference: CaseIterable, Equatable {
    case email
    case foldersAndLabels
    case filters
    case privacyAndSecurity
    case app

    var title: String {
        switch self {
        case .email:
            "Email"
        case .foldersAndLabels:
            "Folders and labels"
        case .filters:
            "Filters"
        case .privacyAndSecurity:
            "Privacy and security"
        case .app:
            "App"
        }
    }

    var subtitle: String {
        switch self {
        case .email:
            "Email and mailbox preferences"
        case .foldersAndLabels, .filters:
            "Mailbox organization"
        case .privacyAndSecurity:
            "Spam and tracking protection"
        case .app:
            "Mobile app customization"
        }
    }

    var icon: ImageResource {
        switch self {
        case .email:
            DS.Icon.icEnvelope
        case .foldersAndLabels:
            DS.Icon.icBookmark
        case .filters:
            DS.Icon.icFilter
        case .privacyAndSecurity:
            DS.Icon.icShield2
        case .app:
            DS.Icon.icMobile
        }
    }
}
