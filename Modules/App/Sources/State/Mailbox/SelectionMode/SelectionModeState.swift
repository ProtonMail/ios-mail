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

/**
 This class wraps the mailbox item selection state and its modifier.

 The reason to keep the writing logic in a separate object is to be able
 to differentiate entities that only observe the selection state from the
 ones that are also responsible for updating it.
 */
final class SelectionMode {
    let selectionState: SelectionModeState
    let selectionModifier: SelectionModeStateModifier

    init(selectedItems: Set<MailboxSelectedItem> = .init()) {
        self.selectionState = .init(selectedItems: selectedItems)
        self.selectionModifier = .init(state: self.selectionState)
    }
}

/**
 Keeps the state of the items selected in a Mailbox.

 The `SelectionModeState` object is a read only class for observation purposes only.
 This class is agnostic of Messages and Conversations and so it works for both.
 */
final class SelectionModeState: ObservableObject {
    var hasItems: Bool { !selectedItems.isEmpty || isSelectAllEnabled }
    var canSelectMoreItems: Bool { remainingSelectionLimit > 0 }

    @Published fileprivate(set) var selectedItems: Set<MailboxSelectedItem>
    @Published fileprivate(set) var isSelectAllEnabled: Bool = false

    private let selectionLimit = 100

    fileprivate var remainingSelectionLimit: Int { selectionLimit - selectedItems.count }

    init(selectedItems: Set<MailboxSelectedItem> = .init()) {
        self.selectedItems = selectedItems
    }
}

/**
 Responsible for updating the `SelectionModeState`
 */
final class SelectionModeStateModifier: @unchecked Sendable {
    let state: SelectionModeState

    init(state: SelectionModeState) {
        self.state = state
    }

    @discardableResult
    func addMailboxItem(_ item: MailboxSelectedItem) -> Bool {
        guard state.canSelectMoreItems else { return false }
        state.selectedItems.insert(item)
        return true
    }

    func removeMailboxItem(_ item: MailboxSelectedItem) {
        state.selectedItems.remove(item)
        state.isSelectAllEnabled = false
    }

    func exitSelectionMode() {
        deselectAll(stayingInSelectAllMode: false)
    }

    func enterSelectAllMode(selecting items: [MailboxSelectedItem]) {
        let numberOfItemsToSelect = min(items.count, state.remainingSelectionLimit)
        state.selectedItems.formUnion(items[..<numberOfItemsToSelect])
        state.isSelectAllEnabled = true
    }

    func exitSelectAllMode() {
        state.isSelectAllEnabled = false
    }

    func deselectAll(stayingInSelectAllMode: Bool) {
        state.selectedItems.removeAll()

        if !stayingInSelectAllMode {
            state.isSelectAllEnabled = false
        }
    }

    /**
     Call this method to refresh the status of the selected items when the mailbox item collection changes.
     - Parameter newMailboxItems: collection of mailbox items that can affect the status of the selected items.
     */
    @MainActor
    func refreshSelectedItemsStatus(newMailboxItems: [MailboxItemCellUIModel]) {
        let currentSelectedIds = state.selectedItems.map(\.id)
        let matchingItems =
            newMailboxItems
            .filter { currentSelectedIds.contains($0.id) }
            .map { $0.toSelectedItem() }

        state.selectedItems = Set(matchingItems)
    }
}
