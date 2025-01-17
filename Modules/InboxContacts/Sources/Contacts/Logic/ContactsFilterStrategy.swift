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

import proton_app_uniffi

enum ContactsFilterStrategy {
    static func filter(searchPhrase: String, items: [GroupedContacts]) -> [GroupedContacts] {
        guard !searchPhrase.isEmpty else {
            return items
        }

        let containsSearchPhrase: (String) -> Bool = { value in
            value.range(of: searchPhrase, options: .caseInsensitive) != nil
        }

        return items.compactMap { groupedContacts in
            let filteredItems = groupedContacts.items.filter { item in
                switch item {
                case .contact(let contact):
                    let isMatchingOneOfEmails: ([ContactEmailItem]) -> Bool = { contactEmails in
                        contactEmails.contains { contactEmail in containsSearchPhrase(contactEmail.email) }
                    }

                    return containsSearchPhrase(contact.name) || isMatchingOneOfEmails(contact.emails)
                case .group(let group):
                    return containsSearchPhrase(group.name)
                }
            }

            return filteredItems.isEmpty ? nil : groupedContacts.copy(items: filteredItems)
        }
    }
}
