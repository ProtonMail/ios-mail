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

import InboxTesting
import proton_app_uniffi

@testable import ProtonMail

final class SidebarSpy: SidebarProtocol, @unchecked Sendable {
    enum CallbackIndex: Int {
        case folder = 0
        case label = 1
        case system = 2
    }

    var stubbedSystemLabels: [PMSystemLabel] = []
    var stubbedCustomFolders: [PMCustomFolder] = []
    var stubbedCustomLabels: [PMCustomLabel] = []
    private(set) var spiedWatchers: [CallbackIndex: LiveQueryCallback] = [:]
    private(set) var collapseFolderInvoked: [ID] = []
    private(set) var expandFolderInvoked: [ID] = []

    // MARK: - SidebarProtocol

    func allCustomFolders() async -> SidebarAllCustomFoldersResult {
        .ok(stubbedCustomFolders)
    }

    func collapseFolder(localId: ID) async -> VoidActionResult {
        collapseFolderInvoked.append(localId)
        return .ok
    }

    func customFolders() async -> SidebarCustomFoldersResult {
        .ok(stubbedCustomFolders)
    }

    func expandFolder(localId: ID) async -> VoidActionResult {
        expandFolderInvoked.append(localId)
        return .ok
    }

    func customLabels() async -> SidebarCustomLabelsResult {
        .ok(stubbedCustomLabels)
    }

    func systemLabels() async -> SidebarSystemLabelsResult {
        .ok(stubbedSystemLabels)
    }

    func watchLabels(callback: LiveQueryCallback) async -> SidebarWatchLabelsResult {
        let lastIndex = spiedWatchers.count - 1
        let mappedIndex: CallbackIndex = lastIndex == -1 ? .folder : .init(rawValue: lastIndex + 1)!
        spiedWatchers[mappedIndex] = callback

        return .ok(WatchHandleDummy(noHandle: .init()))
    }
}
