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

extension Array where Element == SidebarOtherItem {

    static var staleItems: [Element] {
        [
            .init(
                type: .subscriptions,
                icon: DS.Icon.icPencil,
                name: L10n.Settings.subscription.string,
                isSelected: false
            ),
            .init(
                type: .settings,
                icon: DS.Icon.icCogWheel,
                name: L10n.Settings.title.string,
                isSelected: false
            ),
            .init(
                type: .contacts,
                icon: DS.Icon.icUsers,
                name: L10n.Sidebar.contacts.string,
                isSelected: false
            ),
            .init(
                type: .bugReport,
                icon: DS.Icon.icBug,
                name: L10n.Sidebar.bugReport.string,
                isSelected: false
            ),
            .init(
                type: .shareLogs,
                icon: DS.Icon.icBug,
                name: "Share logs".notLocalized,
                isSelected: false
            ),
            .init(
                type: .signOut,
                icon: DS.Icon.icSignOut,
                name: "Sign Out".notLocalized,
                isSelected: false
            )
        ]
    }

}

extension SidebarOtherItem {

    static var createLabel: Self {
        .init(
            type: .createLabel,
            icon: DS.Icon.icPlus,
            name: L10n.Sidebar.createLabel.string,
            isSelected: false
        )
    }

    static var createFolder: Self {
        .init(
            type: .createFolder,
            icon: DS.Icon.icPlus,
            name: L10n.Sidebar.createFolder.string,
            isSelected: false
        )
    }

}
