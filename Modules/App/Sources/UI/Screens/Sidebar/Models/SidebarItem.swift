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
    case system(SystemFolder)
    case label(SidebarLabel)
    case folder(SidebarFolder)
    case other(SidebarOtherItem)

    var isSelected: Bool {
        switch self {
        case .system(let item):
            item.isSelected
        case .label(let item):
            item.isSelected
        case .other(let item):
            item.isSelected
        case .folder(let item):
            item.isSelected
        }
    }

    var isSelectable: Bool {
        switch self {
        case .system, .label, .folder:
            true
        case .other(let item):
            false
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
            "\(item.id.value)"
        case .label(let item):
            "\(item.id.value)"
        case .folder(let item):
            "\(item.id.value)"
        case .other(let item):
            item.name
        }
    }

}
