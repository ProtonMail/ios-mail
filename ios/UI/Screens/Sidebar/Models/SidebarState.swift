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
    let folders: [SidebarFolder]
    let other: [SidebarOtherItem]

    let createLabel: SidebarOtherItem
    let createFolder: SidebarOtherItem

    init(
        system: [SidebarSystemFolder],
        labels: [SidebarLabel],
        folders: [SidebarFolder],
        other: [SidebarOtherItem],
        createLabel: SidebarOtherItem,
        createFolder: SidebarOtherItem
    ) {
        self.system = system
        self.labels = labels
        self.folders = folders
        self.other = other
        self.createLabel = createLabel
        self.createFolder = createFolder
    }
}

extension SidebarState {

    var items: [SidebarItem] {
        system.map(SidebarItem.system) +
        labels.map(SidebarItem.label) +
        folders.map(SidebarItem.folder) +
        other.map(SidebarItem.other)
    }

    static var initial: Self {
        .init(
            system: [],
            labels: [],
            folders: [], 
            other: .staleItems,
            createLabel: .createLabel,
            createFolder: .createFolder
        )
    }

    func copy(system: [SidebarSystemFolder]) -> Self {
        .init(
            system: system,
            labels: labels, 
            folders: folders,
            other: other,
            createLabel: createLabel,
            createFolder: createFolder
        )
    }

    func copy(labels: [SidebarLabel]) -> Self {
        .init(
            system: system,
            labels: labels,
            folders: folders, 
            other: other,
            createLabel: createLabel,
            createFolder: createFolder
        )
    }

    func copy(folders: [SidebarFolder]) -> Self {
        .init(
            system: system, 
            labels: labels,
            folders: folders,
            other: other,
            createLabel: createLabel,
            createFolder: createFolder
        )
    }

    func copy(other: [SidebarOtherItem]) -> Self {
        .init(
            system: system,
            labels: labels,
            folders: folders,
            other: other,
            createLabel: createLabel,
            createFolder: createFolder
        )
    }

    func copy(createLabel: SidebarOtherItem) -> Self {
        .init(
            system: system,
            labels: labels,
            folders: folders,
            other: other,
            createLabel: createLabel,
            createFolder: createFolder
        )
    }

    func copy(createFolder: SidebarOtherItem) -> Self {
        .init(
            system: system,
            labels: labels,
            folders: folders,
            other: other,
            createLabel: createLabel,
            createFolder: createFolder
        )
    }

}

extension Array where Element == SidebarFolder {

    var sidebarFolderNodes: [SidebarFolderNode] {
        let foldersByParentId = Dictionary(grouping: self, by: { $0.parentID })

        func buildTree(parentId: UInt64?) -> [SidebarFolderNode] {
            guard let folders = foldersByParentId[parentId] else { return [] }
            return folders.map { folder in
                SidebarFolderNode(folder: folder, children: buildTree(parentId: folder.id))
            }
        }

        return buildTree(parentId: nil)
    }

}
