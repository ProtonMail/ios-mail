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

final class ContactCreateOperation: AsyncOperation {
    typealias Dependencies = AnyObject & HasContactDataService

    private unowned let deps: Dependencies // `deps` because of a name clash with Operation
    private let contacts: [ContactObjectVCards]

    init(id: String, contacts: [ContactObjectVCards], dependencies: Dependencies) {
        self.deps = dependencies
        self.contacts = contacts
        super.init(operationID: id)
    }

    override func main() {
        deps.contactService.add(
            contactsCards: contacts.map(\.vCards),
            objectsURIs: [],
            importFromDevice: true
        ) { [weak self] error in
            self?.finish(error: error)
        }
    }
}

final class ContactUpdateOperation: AsyncOperation {
    typealias Dependencies = AnyObject & HasContactDataService

    private unowned let deps: Dependencies // `deps` because of a name clash with Operation
    private let contactID: ContactID
    private let vCards: [CardData]

    init(id: String, contactID: ContactID, vCards: [CardData], dependencies: Dependencies) {
        self.deps = dependencies
        self.contactID = contactID
        self.vCards = vCards
        super.init(operationID: id)
    }

    override func main() {
        deps.contactService.update(contactID: contactID, cards: vCards) { [weak self] error in
            self?.finish(error: error)
        }
    }
}
