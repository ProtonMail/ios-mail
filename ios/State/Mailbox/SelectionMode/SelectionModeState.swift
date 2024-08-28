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

/// Keeps the state of the items selected in a Mailbox. This class is agnostic of Messages and Conversations and so it works for both.
final class SelectionModeState: ObservableObject {

    @Published private(set) var hasSelectedItems: Bool
    @Published private(set) var selectionStatus: SelectedItemsStatus
    private(set) var selectedItems: Set<MailboxSelectedItem>

    init(selectedItems: Set<MailboxSelectedItem> = .init()) {
        self.hasSelectedItems = false
        self.selectedItems = selectedItems
        self.selectionStatus = .init(readStatus: .noneRead, starStatus: .noneStarred)
        updateSelectionStatus()
    }

    func addMailboxItem(_ item: MailboxSelectedItem) {
        selectedItems.insert(item)
        hasSelectedItems = true
        updateSelectionStatus()
    }

    func removeMailboxItem(_ item: MailboxSelectedItem) {
        selectedItems.remove(item)
        hasSelectedItems = !selectedItems.isEmpty
        updateSelectionStatus()
    }

    func exitSelectionMode() {
        selectedItems.removeAll()
        hasSelectedItems = false
        updateSelectionStatus()
    }

    /**
     Call this method to refresh the status of the selected items when their status might have changed.
     - Parameter itemProvider: closure that given a collection of item ids, returns the newest status of those items.
     
     - If `itemProvider` does not return one of the selected items, this will be removed from the selection collection. The reason
     being that the item might not exist anymore.
     - If `itemProvider` returns one item that did not belong to the selection collection, that item won't be added to the collection. New
     items should be added calling  `addMailboxItem`.
     */
    func refreshSelectedItemsStatus(itemProvider: (_ mailboxItemIDs: [ID]) -> Set<MailboxSelectedItem> ) {
        let returnedItems = itemProvider(selectedItems.map(\.id))
        let selectedItemsNewStatus = returnedItems.union(returnedItems)
        selectedItems.removeAll()
        selectedItems = selectedItemsNewStatus

        // Given that this method can be frequently called, we only change the `hasSelectedItems` property
        // if the value changes to avoid potential infinite loops with observers.
        let newHasSelectedItemsValue = !selectedItems.isEmpty
        if hasSelectedItems != newHasSelectedItemsValue {
            hasSelectedItems = newHasSelectedItemsValue
        }
        updateSelectionStatus()
    }
}

extension SelectionModeState {

    private func updateSelectionStatus() {
        let readStatus: SelectionReadStatus
        switch selectedItems.filter(\.isRead).count {
        case 0:
            readStatus = .noneRead
        case selectedItems.count:
            readStatus = .allRead
        default:
            readStatus = .someRead
        }
        let starStatus: SelectionStarStatus
        switch selectedItems.filter(\.isStarred).count {
        case 0:
            starStatus = .noneStarred
        case selectedItems.count:
            starStatus = .allStarred
        default:
            starStatus = .someStarred
        }
        selectionStatus = .init(readStatus: readStatus, starStatus: starStatus)
    }
}

struct SelectedItemsStatus {
    let readStatus: SelectionReadStatus
    let starStatus: SelectionStarStatus
}

enum SelectionReadStatus {
    case allRead
    case someRead
    case noneRead

    var atLeastOneRead: Bool {
        switch self {
        case .allRead, .someRead:
            return true
        case .noneRead:
            return false
        }
    }
}

enum SelectionStarStatus {
    case allStarred
    case someStarred
    case noneStarred

    var atLeastOneStarred: Bool {
        switch self {
        case .allStarred, .someStarred:
            return true
        case .noneStarred:
            return false
        }
    }
}
