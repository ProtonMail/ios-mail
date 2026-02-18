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

import InboxTesting
import Testing
import proton_app_uniffi

@testable import InboxContacts

final class GroupedContactsRepositoryTests {
    private lazy var sut: GroupedContactsRepository = .init(
        mailUserSession: MailUserSession(noHandle: .init()),
        contactsProvider: .init(allContacts: { _ in .ok(self.stubbedContacts) })
    )
    private var stubbedContacts: [GroupedContacts] = []

    @Test
    func allContacts_ItReturns0Items() async {
        let items = await sut.allContacts()

        #expect(items == [])
    }

    @Test
    func allContacts_WhenThereAre2Items_ItReturns2Items() async {
        let items: [GroupedContacts] = [
            .init(
                groupedBy: "A",
                items: [
                    .contact(.aliceAdams)
                ]
            ),
            .init(
                groupedBy: "B",
                items: [
                    .contact(.bobAinsworth),
                    .group(.businessGroup),
                ]
            ),
        ]

        stubbedContacts = items

        let contacts = await sut.allContacts()

        #expect(contacts == items)
    }
}
