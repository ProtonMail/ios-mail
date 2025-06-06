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

@testable import InboxContacts
import InboxSnapshotTesting
import proton_app_uniffi
import Testing

@MainActor
final class ContactDetailsScreenSnapshotTests {

    @Test
    func testContactDetailsScreenLayoutsCorrectOnIphoneX() {
        let items: [ContactField] = [
            .emails([
                .init(name: "Work", email: "ben.ale@protonmail.com"),
                .init(name: "Private", email: "alexander@proton.me"),
            ]),
            .addresses([
                .init(
                    street: "Lettensteg 10",
                    city: "Zürich",
                    region: .none,
                    postalCode: "8037",
                    country: .none,
                    addrType: []
                ),
                .init(
                    street: "Uetlibergstrasse 872",
                    city: "Zürich",
                    region: .none,
                    postalCode: "8025",
                    country: .none,
                    addrType: []
                ),
            ]),
            .birthday(.string("Jan 23, 2004")),
            .notes([
                "Met Caleb while studying abroad. Amazing memories and a strong friendship."
            ]),
        ]

        let contact: ContactItem = .benjaminAlexander
        let sut = ContactDetailsScreen(
            contact: .benjaminAlexander,
            provider: .previewInstance(),
            state: .init(contact: contact, details: .init(id: contact.id, fields: items))
        )

        assertSnapshotsOnIPhoneX(of: sut)
    }

}
