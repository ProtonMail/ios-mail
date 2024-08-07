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

enum SidebarItem: Equatable, Identifiable {
    case system(SidebarSystemFolderUIModel)
    case other(SidebarOtherItemUIModel)

    var isSelected: Bool {
        switch self {
        case .system(let item):
            return item.isSelected
        case .other(let item):
            return item.isSelected
        }
    }

    var isSelectable: Bool {
        switch self {
        case .system:
            return true
        case .other(let otherItem):
            return otherItem.type.isSelectable
        }
    }

    var unreadCount: String? {
        switch self {
        case .other:
            return nil
        case .system(let item):
            return item.unreadCount
        }
    }

    var icon: ImageResource {
        switch self {
        case .system(let systemFolder):
            return systemFolder.identifier.icon
        case .other(let otherItem):
            return otherItem.icon
        }
    }

    var name: String {
        switch self {
        case .system(let systemFolder):
            return systemFolder.identifier.humanReadable.string
        case .other(let otherItem):
            return otherItem.name
        }
    }

    func copy(isSelected: Bool) -> SidebarItem {
        switch self {
        case .system(let systemFolder):
            return .system(systemFolder.copy(isSelected: isSelected))
        case .other(let otherItem):
            return .other(otherItem.copy(isSelected: isSelected))
        }
    }

    // MARK: - Identifiable

    var id: String {
        switch self {
        case .system(let systemFolder):
            return "\(systemFolder.localID)"
        case .other(let otherItem):
            return otherItem.name
        }
    }

}

extension Array where Element == SidebarItem {

    var system: [SidebarItem] {
        filter { item in
            switch item {
            case .system:
                return true
            case .other:
                return false
            }
        }
    }

    var other: [SidebarItem] {
        filter { item in
            switch item {
            case .system:
                return false
            case .other:
                return true
            }
        }
    }

}
