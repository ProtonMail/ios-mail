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

enum SidebarAction {
    case viewAppear
    case select(item: SidebarItem)
}

@Observable
final class SidebarModel: Sendable {
    private(set) var state: SidebarState

    private var systemFolderQuery: SidebarLiveQuery?
    private var labelsQuery: SidebarLiveQuery?
    private var foldersQuery: SidebarLiveQuery?
    private let dependencies: Dependencies

    init(state: SidebarState = .initial, dependencies: Dependencies = .init()) {
        self.state = state
        self.dependencies = dependencies
    }

    func handle(action: SidebarAction) {
        switch action {
        case .viewAppear:
            initLiveQuery()
        case .select(let item):
            select(item: item)
        }
    }

    // MARK: - Private

    private func select(item: SidebarItem) {
        guard item.isSelectable else { return }
        unselectAll()
        switch item {
        case .system(let item):
            state = state.copy(system: selected(item: item, keyPath: \.system))
        case .label(let item):
            state = state.copy(labels: selected(item: item, keyPath: \.labels))
        case .folder(let item):
            state = state.copy(folders: selected(item: item, keyPath: \.folders))
        case .other(let item):
            select(item: item)
        }
    }

    private func select(item: SidebarOtherItem) {
        switch item.type {
        case .createLabel:
            state = state.copy(createLabel: .createLabel.copy(isSelected: true))
        case .createFolder:
            state = state.copy(createFolder: .createFolder.copy(isSelected: true))
        default:
            state = state.copy(other: selected(item: item, keyPath: \.other))
        }
    }

    private func initLiveQuery() {
        guard let userContext = dependencies.activeUserSession else { return }
        systemFolderQuery = SidebarLiveQuery(
            queryFactory: userContext.newSystemLabelsObservedQuery,
            dataUpdate: { newFolders in
                Dispatcher.dispatchOnMain(.init(block: { [weak self] in
                    self?.updateSystemFolders(with: newFolders)
                }))
            }
        )
        labelsQuery = SidebarLiveQuery(
            queryFactory: userContext.newLabelLabelsObservedQuery,
            dataUpdate: { newLabels in
                Dispatcher.dispatchOnMain(.init(block: { [weak self] in
                    self?.updateLabels(with: newLabels)
                }))
            }
        )
        foldersQuery = SidebarLiveQuery(
            queryFactory: userContext.newFolderLabelsObservedQuery,
            dataUpdate: { newFolders in
                Dispatcher.dispatchOnMain(.init(block: { [weak self] in
                    self?.updateFolders(with: newFolders)
                }))
            }
        )
    }

    private func updateSystemFolders(with newSystemFolders: [LocalLabelWithCount]) {
        state = state.copy(
            system: updated(
                newItems: newSystemFolders,
                stateKeyPath: \.system,
                transformation: \.sidebarSystemFolder
            )
        )
        selectFirstSystemItemIfNeeded()
    }

    private func updateLabels(with newLabels: [LocalLabelWithCount]) {
        state = state.copy(
            labels: updated(
                newItems: newLabels,
                stateKeyPath: \.labels,
                transformation: { label in label.sidebarLabel }
            )
        )
    }

    private func updateFolders(with newFolders: [LocalLabelWithCount]) {
        state = state.copy(
            folders: updated(
                newItems: newFolders,
                stateKeyPath: \.folders,
                transformation: { folder in folder.sidebarFolder }
            )
        )
    }

    private func updated<Item: SelectableItem>(
        newItems: [LocalLabelWithCount],
        stateKeyPath: KeyPath<SidebarState, [Item]>,
        transformation: (LocalLabelWithCount) -> Item?
    ) -> [Item] where Item.SelectableItemType == Item {
        let selectedItem = state[keyPath: stateKeyPath].first(where: \.isSelected)
        let newItems = newItems
            .compactMap(transformation)
            .map { item in item.copy(isSelected: item.selectionIdentifier == selectedItem?.selectionIdentifier) }
        return newItems
    }

    private func unselectAll() {
        state = .init(
            system: unselected(keyPath: \.system),
            labels: unselected(keyPath: \.labels), 
            folders: unselected(keyPath: \.folders),
            other: unselected(keyPath: \.other),
            createLabel: .createLabel.copy(isSelected: false),
            createFolder: .createFolder.copy(isSelected: false)
        )
    }

    private func unselected<Item: SelectableItem>(
        keyPath: KeyPath<SidebarState, [Item]>
    ) -> [Item] where Item.SelectableItemType == Item{
        state[keyPath: keyPath].map { item in item.copy(isSelected: false) }
    }

    private func selected<Item: SelectableItem>(
        item: Item,
        keyPath: KeyPath<SidebarState, [Item]>
    ) -> [Item] where Item.SelectableItemType == Item {
        state[keyPath: keyPath]
            .map { currentItem in
                currentItem.copy(isSelected: item.selectionIdentifier == currentItem.selectionIdentifier)
            }
    }

    private func selectFirstSystemItemIfNeeded() {
        if state.items.filter(\.isSelected).isEmpty, let first = state.items.first(where: \.isSelectable) {
            select(item: first)
        }
    }

}

extension SidebarModel {

    struct Dependencies {
        let activeUserSession: MailUserSessionProtocol?

        init(activeUserSession: MailUserSessionProtocol? = AppContext.shared.activeUserSession) {
            self.activeUserSession = activeUserSession
        }
    }

}

private class SidebarLiveQuery: MailboxLiveQueryUpdatedCallback {

    private let dataUpdate: ([LocalLabelWithCount]) -> Void
    private var query: MailLabelsLiveQuery?

    init(
        queryFactory: @escaping (MailboxLiveQueryUpdatedCallback) -> MailLabelsLiveQuery,
        dataUpdate: @escaping ([LocalLabelWithCount]) -> Void
    ) {
        self.dataUpdate = dataUpdate
        self.query = queryFactory(self)
    }

    // MARK: - MailboxLiveQueryUpdatedCallback

    func onUpdated() {
        do {
            let newItems = try query.unsafelyUnwrapped.value()
            dataUpdate(newItems)
        } catch {
            AppLogger.log(error: error)
        }
    }

}
