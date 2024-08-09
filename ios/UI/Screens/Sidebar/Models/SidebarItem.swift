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
    case system(SidebarSystemFolder)
    case label(SidebarLabel)
    case folder(SidebarFolder)
    case other(SidebarOtherItem)

    var isSelected: Bool {
        switch self {
        case .system(let item):
            return item.isSelected
        case .label(let item):
            return item.isSelected
        case .other(let item):
            return item.isSelected
        case .folder(let item):
            return item.isSelected
        }
    }

    var isSelectable: Bool {
        switch self {
        case .system, .label, .folder:
            return true
        case .other(let item):
            return item.type.isSelectable
        }
    }

    func copy(isSelected: Bool) -> SidebarItem {
        switch self {
        case .system(let item):
            return .system(item.copy(isSelected: isSelected))
        case .label(let item):
            return .label(item.copy(isSelected: isSelected))
        case .folder(let item):
            return .folder(item.copy(isSelected: isSelected))
        case .other(let item):
            return .other(item.copy(isSelected: isSelected))
        }
    }

    // MARK: - Identifiable

    var id: String {
        switch self {
        case .system(let item):
            return "\(item.localID)"
        case .label(let item):
            return "\(item.localID)"
        case .folder(let item):
            return "\(item.id)"
        case .other(let item):
            return item.name
        }
    }

}
