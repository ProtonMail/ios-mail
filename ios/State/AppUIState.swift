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
 Keeps the state for UI components
 */
final class AppUIState: ObservableObject {
    @Published var isSidebarOpen: Bool = false

    init(isSidebarOpen: Bool = false) {
        self.isSidebarOpen = isSidebarOpen
    }
}

@MainActor
final class SelectionMode: ObservableObject {

    @Published private(set) var hasSelectedItems: Bool
    private(set) var selectedItems: Set<PMMailboxItemId>

    init(selectedItems: Set<PMMailboxItemId> = .init()) {
        self.hasSelectedItems = false
        self.selectedItems = selectedItems
    }

    func addMailboxItem(id: PMMailboxItemId) {
        selectedItems.insert(id)
        hasSelectedItems = true
    }

    func removeMailboxItem(id: PMMailboxItemId) {
        selectedItems.remove(id)
        hasSelectedItems = !selectedItems.isEmpty
    }

    func exitSelectionMode() {
        selectedItems.removeAll()
        hasSelectedItems = false
    }
}
