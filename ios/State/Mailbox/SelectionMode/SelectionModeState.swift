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

@MainActor
final class SelectionModeState: ObservableObject {

    @Published private(set) var hasSelectedItems: Bool
    @Published private(set) var selectionStatus: SelectedItemsStatus
    private(set) var selectedItems: Set<SelectedItem>

    init(selectedItems: Set<SelectedItem> = .init()) {
        self.hasSelectedItems = false
        self.selectedItems = selectedItems
        self.selectionStatus = .init(readStatus: .noneRead, starStatus: .noneStarred)
        updateSelectionStatus()
    }

    func addMailboxItem(_ item: SelectedItem) {
        selectedItems.insert(item)
        hasSelectedItems = true
        updateSelectionStatus()
    }

    func removeMailboxItem(_ item: SelectedItem) {
        selectedItems.remove(item)
        hasSelectedItems = !selectedItems.isEmpty
        updateSelectionStatus()
    }

    func exitSelectionMode() {
        selectedItems.removeAll()
        hasSelectedItems = false
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
