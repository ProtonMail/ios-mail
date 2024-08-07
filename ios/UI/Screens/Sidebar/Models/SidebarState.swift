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

import Foundation

struct SidebarState {
    let system: [SidebarSystemFolder]
    let labels: [SidebarLabel]
    let other: [SidebarOtherItem]
}

extension SidebarState {

    var items: [SidebarItem] {
        system.map(SidebarItem.system) + labels.map(SidebarItem.label) + other.map(SidebarItem.other)
    }

    static var initial: Self {
        .init(system: [], labels: [], other: .staleItems)
    }

    func copy(system: [SidebarSystemFolder]) -> Self {
        .init(system: system, labels: labels, other: other)
    }

    func copy(labels: [SidebarLabel]) -> Self {
        .init(system: system, labels: labels, other: other)
    }

    func copy(other: [SidebarOtherItem]) -> Self {
        .init(system: system, labels: labels, other: other)
    }

}
