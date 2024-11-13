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

public struct ContactsScreenState: Copying, Equatable {
    public struct Search: Equatable {
        var query: String
        var isActive: Bool
    }

    var search: Search
    var allItems: [GroupedContacts]
    var itemToDelete: ContactItemType?
    var displayItems: [GroupedContacts] {
        guard search.isActive else {
            return allItems
        }

        let filteredItems = ContactsFilterStrategy
            .filter(searchPhrase: search.query, items: allItems)
            .flatMap(\.item)

        return [.init(groupedBy: "", item: filteredItems)]
    }
}

extension ContactsScreenState {

    public static var initial: Self {
        .init(search: .initial, allItems: [], itemToDelete: nil)
    }

}

extension ContactsScreenState.Search {

    static var initial: Self {
        .init(query: "", isActive: false)
    }

}
