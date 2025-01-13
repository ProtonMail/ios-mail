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
import SwiftUI

struct SidebarFolder: Equatable, Identifiable, SelectableItem {
    let id: ID
    let parentID: ID?
    let name: String
    let color: Color?
    let unreadCount: UInt64
    let expanded: Bool
    let childFolders: [SidebarFolder]

    var displayColor: Color {
        guard let color else {
            return isSelected ? DS.Color.Sidebar.iconSelected : DS.Color.Sidebar.iconWeak
        }

        return color
    }

    // MARK: - SelectableItem

    let isSelected: Bool

    var selectionIdentifier: String {
        "\(id)"
    }

    func copy(isSelected: Bool) -> Self {
        .init(
            id: id,
            parentID: parentID,
            name: name,
            color: color,
            unreadCount: unreadCount,
            expanded: expanded, 
            childFolders: childFolders,
            isSelected: isSelected
        )
    }
}
