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

import InboxCore

struct SidebarState: Copying {
    var upsell: SidebarItem?
    var system: [SystemFolder]
    var labels: [SidebarLabel]
    var folders: [SidebarFolder]
    var other: [SidebarOtherItem]
    var createLabel: SidebarOtherItem
    var createFolder: SidebarOtherItem
}

extension SidebarState {

    var items: [SidebarItem] {
        let upsellItems: [SidebarItem] = [upsell].compactMap(\.self)
        let systemItems = system.map(SidebarItem.system)
        let labelItems = labels.map(SidebarItem.label)
        let folderItems = folders.allFolders.map(SidebarItem.folder)
        let otherItems = (other + [createLabel, createFolder]).map(SidebarItem.other)

        return upsellItems + systemItems + labelItems + folderItems + otherItems
    }

    static var initial: Self {
        .init(
            upsell: nil,
            system: [],
            labels: [],
            folders: [],
            other: .staleItems,
            createLabel: .createLabel,
            createFolder: .createFolder
        )
    }

}

private extension SidebarFolder {

    var folderWithChildren: [SidebarFolder] {
        [self] + childFolders.flatMap(\.folderWithChildren)
    }

}

private extension Array where Element == SidebarFolder {

    var allFolders: [SidebarFolder] {
        flatMap(\.folderWithChildren)
    }

}
