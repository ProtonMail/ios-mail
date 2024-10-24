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

import Combine

/**
 This class wraps the mailbox item selection state and its modifier.

 The reason to keep the writing logic in a separate object is to be able
 to differentiate entities that only observe the selection state from the 
 ones that are also responsible for updating it.
 */
final class SelectionMode {
    let selectionState: SelectionModeState
    let selectionModifier: SelectionModeStateModifier

    init(selectedItemIDs: Set<ID> = .init()) {
        self.selectionState = .init(selectedItemIDs: selectedItemIDs)
        self.selectionModifier = .init(state: self.selectionState)
    }
}

/**
 Keeps the state of the items selected in a Mailbox.

 The `SelectionModeState` object is a read only class for observation purposes only.
 This class is agnostic of Messages and Conversations and so it works for both.
 */
final class SelectionModeState: ObservableObject {
    @Published fileprivate(set) var hasItems: Bool
    @Published fileprivate(set) var selectedItemIDs: Set<ID>

    init(selectedItemIDs: Set<ID> = .init()) {
        self.hasItems = false
        self.selectedItemIDs = selectedItemIDs
    }
}

/**
 Responsible for updating the `SelectionModeState`
 */
final class SelectionModeStateModifier {
    let state: SelectionModeState

    init(state: SelectionModeState) {
        self.state = state
    }

    func addMailboxItem(withID item: ID) {
        state.selectedItemIDs.insert(item)
        state.hasItems = true
    }

    func removeMailboxItem(withID item: ID) {
        state.selectedItemIDs.remove(item)
        state.hasItems = !state.selectedItemIDs.isEmpty
    }

    func exitSelectionMode() {
        state.selectedItemIDs.removeAll()
        state.hasItems = false
    }

    /**
     Call this method to refresh the status of the selected items when their status might have changed.
     - Parameter itemProvider: closure that given a collection of item ids, returns the newest status of those items.

     - If `itemProvider` does not return one of the selected items, this will be removed from the selection collection. The reason
     being that the item might not exist anymore.
     - If `itemProvider` returns one item that did not belong to the selection collection, that item won't be added to the collection. New
     items should be added calling  `addMailboxItem`.
     */
    func refreshSelectedItemsStatus(itemProvider: (_ mailboxItemIDs: [ID]) -> Set<ID> ) {
        let returnedItems = itemProvider(Array(state.selectedItemIDs))
        let selectedItemsNewStatus = returnedItems.union(returnedItems)
        state.selectedItemIDs.removeAll()
        state.selectedItemIDs = selectedItemsNewStatus

        // Given that this method can be frequently called, we only change the `hasSelectedItems` property
        // if the value changes to avoid potential infinite loops with observers.
        let newHasSelectedItemsValue = !state.selectedItemIDs.isEmpty
        if state.hasItems != newHasSelectedItemsValue {
            state.hasItems = newHasSelectedItemsValue
        }
    }
}
