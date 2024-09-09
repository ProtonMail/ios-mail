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

    var title: LocalizedStringResource {
        switch self {
        case .email:
            L10n.Settings.email
        case .foldersAndLabels:
            L10n.Settings.foldersAndLabels
        case .filters:
            L10n.Settings.filters
        case .privacyAndSecurity:
            L10n.Settings.privacyAndSecurity
        case .app:
            L10n.Settings.appSettingsTitle
        }
    }

    var subtitle: LocalizedStringResource {
        switch self {
        case .email:
            L10n.Settings.emailSubtitle
        case .foldersAndLabels:
            L10n.Settings.foldersAndLabelsSubtitle
        case .filters:
            L10n.Settings.filtersSubtitle
        case .privacyAndSecurity:
            L10n.Settings.privacyAndSecuritySubtitle
        case .app:
            L10n.Settings.appSettingsSubtitle
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
