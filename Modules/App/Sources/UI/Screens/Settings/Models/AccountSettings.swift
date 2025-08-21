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

import InboxDesignSystem
import SwiftUI
import ProtonUIFoundations

enum AccountSettings: CaseIterable, Hashable {
    case qrLogin
    case changePassword
    case changeLoginPassword
    case changeMailboxPassword
    case securityKeys

    struct DisplayData {
        let title: LocalizedStringResource
        let icon: ImageResource
    }

    var displayData: DisplayData {
        switch self {
        case .qrLogin:
            .init(title: L10n.Settings.signInOnAnotherDevice, icon: DS.Icon.icQrCode)
        case .changePassword:
            .init(title: L10n.Settings.App.changePassword, icon: Theme.icon.lock)
        case .changeLoginPassword:
            .init(title: L10n.Settings.App.changeLoginPassword, icon: Theme.icon.lock)
        case .changeMailboxPassword:
            .init(title: L10n.Settings.App.changeMailboxPassword, icon: Theme.icon.lockLayers)
        case .securityKeys:
            .init(title: L10n.Settings.App.securityKeys, icon: Theme.icon.securityKey)
        }
    }
}
