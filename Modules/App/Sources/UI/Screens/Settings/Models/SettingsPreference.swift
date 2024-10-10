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

enum SettingsPreference: CaseIterable, Hashable {
    case email
    case foldersAndLabels
    case filters
    case privacyAndSecurity
    case app

    struct DisplayData {
        let title: LocalizedStringResource
        let subtitle: LocalizedStringResource
        let icon: ImageResource
    }

    var displayData: DisplayData {
        switch self {
        case .email:
            .init(title: L10n.Settings.email, subtitle: L10n.Settings.emailSubtitle, icon: DS.Icon.icEnvelopes)
        case .foldersAndLabels:
            .init(
                title: L10n.Settings.foldersAndLabels,
                subtitle: L10n.Settings.foldersAndLabelsSubtitle,
                icon: DS.Icon.icFolderOpen
            )
        case .filters:
            .init(title: L10n.Settings.filters, subtitle: L10n.Settings.filtersSubtitle, icon: DS.Icon.icSliders)
        case .privacyAndSecurity:
            .init(
                title: L10n.Settings.privacyAndSecurity,
                subtitle: L10n.Settings.privacyAndSecuritySubtitle,
                icon: DS.Icon.icShield2Bolt
            )
        case .app:
            .init(
                title: L10n.Settings.appSettingsTitle, 
                subtitle: L10n.Settings.appSettingsSubtitle,
                icon: DS.Icon.icMobile
            )
        }
    }

}
