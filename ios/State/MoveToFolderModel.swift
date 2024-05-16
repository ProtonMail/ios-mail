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

import DesignSystem
import proton_mail_uniffi
import class SwiftUI.UIImage

/**
 Source of truth for folders where Mailbox messages or conversations can be moved to.
 These folders include custom folders created by the user and some specific system folders.
 */
struct MoveToFolderModel {
    private let dependencies: Dependencies

    init(dependencies: Dependencies = .init()) {
        self.dependencies = dependencies
    }

    /// Returns labels representing system folders where a message or conversatino can be moved to e.g. inbox
    func moveToSystemFolders() async -> [LocalLabel] {
        await fetchMovableFolders().filter { $0.systemFolderIdentifier != nil }
    }

    /// Returns an array of top level custom folders, with its children, created by the user.
    ///
    /// All folders and subfolders are returned sorted following the backend `order` parameter.
    func customFoldersHierarchy() async -> [CustomFolder] {
        let allCustomFolders = await fetchMovableFolders().filter { $0.systemFolderIdentifier == nil }
        return foldersHierarchy(from: allCustomFolders)
    }

    private func fetchMovableFolders() async -> [LocalLabel] {
        do {
            guard let userSession = dependencies.appContext.activeUserSession else { return [] }
            return try userSession.movableFolders()
        } catch {
            AppLogger.log(error: error)
            return []
        }
    }
}

extension MoveToFolderModel {

    private func foldersHierarchy(from folders: [LocalLabel]) -> [CustomFolder] {
        var rawFolders: [CustomFolder] = folders
            .sorted(by: { $0.childLevel <= $1.childLevel })
            .map { CustomFolder(folder: $0, children: []) }

        let indexes: [Int] = [Int](0..<rawFolders.count)

        let rawFolderLabelIds = rawFolders.map { $0.folder.id }
        var labelIDToIndex: [PMLocalLabelId: Int] = [:]
        for (labelId, index) in zip(rawFolderLabelIds, indexes) {
            labelIDToIndex[labelId] = index
        }

        var folders = [CustomFolder]()
        for index in indexes.reversed() {
            let hierarchyItem = rawFolders[index]

            guard 
                let parentID = hierarchyItem.folder.parentId,
                let parentIdx = labelIDToIndex[parentID] 
            else {
                folders.insert(hierarchyItem, at: 0)
                continue
            }
            rawFolders[parentIdx].children.insert(hierarchyItem, at: 0)
        }
        return folders.recursivelySorted(by: { $0.folder.order < $1.folder.order })
    }
}

extension MoveToFolderModel {

    struct Dependencies {
        let appContext: AppContext = .shared
    }
}
