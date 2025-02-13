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

import SwiftUI

struct SidebarOtherItem: Identifiable, Equatable, SelectableItem {
    enum ItemType: String, Equatable {
        case settings
        case subscriptions
        case shareLogs
        case contacts
        case bugReport
        case backgroundTasksLogs
        case signOut
        case createLabel
        case createFolder
    }

    let type: ItemType
    let icon: ImageResource
    let name: String

    // MARK: - Identifiable

    var id: String {
        selectionIdentifier
    }

    // MARK: - SelectableItem

    let isSelected: Bool

    var selectionIdentifier: String {
        type.rawValue
    }

    func copy(isSelected: Bool) -> Self {
        .init(type: type, icon: icon, name: name, isSelected: isSelected)
    }
}
