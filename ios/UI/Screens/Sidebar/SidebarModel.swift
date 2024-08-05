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

import proton_mail_uniffi
import SwiftUI

@Observable
final class SidebarModel: ObservableObject {
    var state: SidebarState

    var sidebarState: [SidebarItem] {
        state.system.map(SidebarItem.system) + state.other.map(SidebarItem.other)
    }

    private var systemFolderQuery: MailLabelsLiveQuery?
    private let dependencies: Dependencies

    init(state: SidebarState = .init(system: [], other: .staleItems), dependencies: Dependencies = .init()) {
        self.state = state
        self.dependencies = dependencies
    }

    func onViewWillAppear() async {
        await initLiveQuery()
    }

    func select(sidebarItem: SidebarItem) {
        guard sidebarItem.isSelectable else { return }
        unselect()
        switch sidebarItem {
        case .system(let systemFolder):
            select(item: systemFolder, keyPath: \.system)
        case .other(let otherItem):
            select(item: otherItem, keyPath: \.other)
        }
    }

    // MARK: - Private

    private func initLiveQuery() async {
        guard let userContext = dependencies.appContext.activeUserSession else { return }
        systemFolderQuery = userContext.newSystemLabelsObservedQuery(cb: self)
    }

    private func updateData() {
        guard let systemFolderQuery else { return }
        do {
            let selectedSystemItem = state.system.first(where: { $0.isSelected })
            let systemFolders = try systemFolderQuery.value()
                .compactMap(\.systemFolder)
                .map { $0.copy(isSelected: $0.selectionIdentifier == selectedSystemItem?.selectionIdentifier) }

            state.system = systemFolders
            selectFirstIfNeeded()
        } catch {
            AppLogger.log(error: error)
        }
    }

    private func select<Item: SelectableItem>(
        item: Item,
        keyPath: WritableKeyPath<SidebarState, [Item]>
    ) where Item.SelectableItemType == Item {
        state[keyPath: keyPath] = state[keyPath: keyPath]
            .map { $0.copy(isSelected: item.selectionIdentifier == $0.selectionIdentifier) }
    }

    private func unselect() {
        state.system = state.system.map { $0.copy(isSelected: false) }
        state.other = state.other.map { $0.copy(isSelected: false) }
    }

    private func selectFirstIfNeeded() {
        if sidebarState.filter(\.isSelected).isEmpty, let first = sidebarState.first(where: { $0.isSelectable }) {
            select(sidebarItem: first)
        }
    }

}

extension SidebarModel: MailboxLiveQueryUpdatedCallback, Sendable {

    func onUpdated() {
        Task { @MainActor in
            updateData()
        }
    }

}

extension SidebarModel {

    struct Dependencies {
        let appContext: AppContext = .shared
    }

}
