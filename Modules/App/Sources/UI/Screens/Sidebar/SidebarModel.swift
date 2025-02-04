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
import proton_app_uniffi
import SwiftUI

enum SidebarAction {
    case viewAppear
    case select(item: SidebarItem)
    case toggle(folder: SidebarFolder, expand: Bool)
}

final class SidebarModel: Sendable, ObservableObject {
    @Published var state: SidebarState

    private var foldersChangesObservation: SidebarModelsObservation<PMCustomFolder>?
    private var labelsChangesObservation: SidebarModelsObservation<PMCustomLabel>?
    private var systemLabelsChangesObservation: SidebarModelsObservation<PMSystemLabel>?
    private let sidebar: SidebarProtocol

    init(state: SidebarState, sidebar: SidebarProtocol) {
        self.state = state
        self.sidebar = sidebar
    }

    func handle(action: SidebarAction) {
        switch action {
        case .viewAppear:
            initLiveQuery()
        case .select(let item):
            select(item: item)
        case .toggle(let folder, let expand):
            changeVisibility(of: folder, expand: expand)
        }
    }

    private func changeVisibility(of folder: SidebarFolder, expand: Bool) {
        Task {
            if expand {
                _ = await sidebar.expandFolder(localId: folder.id)
            } else {
                _ = await sidebar.collapseFolder(localId: folder.id)
            }
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
            state = state.copy(folders: folders(selectedFolder: item, in: state.folders))
        case .other(let item):
            state = state.copy(other: selected(item: item, keyPath: \.other))
        }
    }

    private func initLiveQuery() {
        foldersChangesObservation = .init(
            sidebar: sidebar,
            labelType: .folder,
            updatedData: sidebar.customFolders
        ) { [weak self] newFolders in
            Dispatcher.dispatchOnMain(.init(block: {
                self?.updateFolders(with: newFolders)
            }))
        }
        labelsChangesObservation = .init(
            sidebar: sidebar,
            labelType: .label,
            updatedData: sidebar.customLabels
        ) { [weak self] newLabels in
            Dispatcher.dispatchOnMain(.init(block: {
                self?.updateLabels(with: newLabels)
            }))
        }
        systemLabelsChangesObservation = .init(
            sidebar: sidebar,
            labelType: .system, 
            updatedData: sidebar.systemLabels
        ) { [weak self] newSystemLabels in
            Dispatcher.dispatchOnMain(.init(block: {
                self?.updateSystemFolders(with: newSystemLabels)
            }))
        }
    }

    private func updateFolders(with newFolders: [PMCustomFolder]) {
        let sidebarFolders = newFolders.map(\.sidebarFolder)
        let sidebarFoldersWithSelection: [SidebarFolder]
        if let selectedFolder = findSelectedFolder(in: state.folders) {
            sidebarFoldersWithSelection = folders(selectedFolder: selectedFolder, in: sidebarFolders)
        } else {
            sidebarFoldersWithSelection = sidebarFolders
        }
        state = state.copy(folders: sidebarFoldersWithSelection)
    }

    private func updateLabels(with newLabels: [PMCustomLabel]) {
        state = state.copy(
            labels: updated(
                newItems: newLabels,
                stateKeyPath: \.labels,
                transformation: { label in label.sidebarLabel }
            )
        )
    }

    private func updateSystemFolders(with newSystemLabels: [PMSystemLabel]) {
        state = state.copy(
            system: updated(
                newItems: newSystemLabels,
                stateKeyPath: \.system,
                transformation: \.sidebarSystemFolder
            )
        )
        selectFirstSystemItemIfNeeded()
    }

    private func updated<Item: SelectableItem, Model>(
        newItems: [Model],
        stateKeyPath: KeyPath<SidebarState, [Item]>,
        transformation: (Model) -> Item?
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
            folders: unselectedFolders(in: state.folders),
            other: unselected(keyPath: \.other),
            createLabel: .createLabel.copy(isSelected: false),
            createFolder: .createFolder.copy(isSelected: false)
        )
    }

    private func unselectedFolders(in folders: [SidebarFolder]) -> [SidebarFolder] {
        folders.map { folder in
            folder
                .copy(isSelected: false)
                .copy(childFolders: unselectedFolders(in: folder.childFolders))
        }
    }

    private func unselected<Item: SelectableItem>(
        keyPath: KeyPath<SidebarState, [Item]>
    ) -> [Item] where Item.SelectableItemType == Item{
        state[keyPath: keyPath].map { item in item.copy(isSelected: false) }
    }

    func folders(selectedFolder: SidebarFolder, in folders: [SidebarFolder]) -> [SidebarFolder] {
        folders.map { folder in
            if folder.selectionIdentifier == selectedFolder.selectionIdentifier {
                return folder.copy(isSelected: true)
            } else {
                return folder.copy(childFolders: self.folders(selectedFolder: selectedFolder, in: folder.childFolders))
            }
        }
    }

    func findSelectedFolder(in folders: [SidebarFolder]) -> SidebarFolder? {
        if let selected = folders.findFirst(for: true, by: \.isSelected) {
            return selected
        }
        let childFolders = folders.flatMap(\.childFolders)
        return childFolders.isEmpty ? nil : findSelectedFolder(in: childFolders)
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
        if state.items.filter(\.isSelected).isEmpty, let first = state.system.first {
            select(item: .system(first))
        }
    }

}

private class SidebarModelsObservation<Model> {

    private let sidebar: SidebarProtocol
    private let labelType: LabelType
    private let updatedData: () async -> Result<[Model], ActionError>
    private let dataUpdate: ([Model]) -> Void

    private let updateCallback = LiveQueryCallbackWrapper()
    private var watchHandle: WatchHandle?

    init(
        sidebar: SidebarProtocol,
        labelType: LabelType,
        updatedData: @escaping () async -> Result<[Model], ActionError>,
        dataUpdate: @escaping ([Model]) -> Void
    ) {
        self.sidebar = sidebar
        self.labelType = labelType
        self.updatedData = updatedData
        self.dataUpdate = dataUpdate
        initLiveQuery()
    }

    deinit {
        watchHandle?.disconnect()
    }

    // MARK: - Private

    private func initLiveQuery() {
        updateCallback.delegate = { [weak self] in
            self?.onLabelsUpdate()
        }

        Task {
            switch await sidebar.watchLabels(labelType: labelType, callback: updateCallback) {
            case .ok(let watchHandle):
                self.watchHandle = watchHandle
                await emitUpdatedModelsIfAvailable()
            case .error:
                break
            }
        }
    }

    private func onLabelsUpdate() {
        Task {
            await emitUpdatedModelsIfAvailable()
        }
    }

    private func emitUpdatedModelsIfAvailable() async {
        if let newData = try? await updatedData().get() {
            dataUpdate(newData)
        }
    }

}

private extension SidebarFolder {

    func copy(childFolders: [SidebarFolder]) -> SidebarFolder {
        .init(
            id: id,
            parentID: parentID,
            name: name,
            color: color,
            unreadCount: unreadCount,
            expanded: expanded,
            childFolders: childFolders,
            isSelected: isSelected
        )
    }

}
