// Copyright (c) 2025 Proton Technologies AG
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

struct ContactDetailsProvider {
    let _contactDetails: (ContactDetailsContext) async -> ContactDetails

    init(contactDetails: @escaping (ContactDetailsContext) async -> ContactDetails) {
        _contactDetails = contactDetails
    }

    func contactDetails(for contact: ContactDetailsContext) async -> ContactDetails {
        await _contactDetails(contact)
    }
}

extension ContactDetailsProvider {
    static func productionInstance(mailUserSession: MailUserSession) -> Self {
        .init(contactDetails: { contact in
            let details = try? await getContactDetails(session: mailUserSession, contactId: contact.id).get()
            return .init(contact: contact, details: details)
        })
    }

    static func previewInstance() -> Self {
        let items: [ContactField] = [
            .emails([
                .init(
                    emailType: [.work],
                    email: "ben.ale@protonmail.com",
                    groups: [
                        .init(name: "zhaocheng", color: "#179FD9"),
                        .init(name: "jibohan", color: "#3CBB3A"),
                        .init(name: "shaoni", color: "#8080FF"),
                        .init(name: "qinlangan", color: "#DB60D6"),
                        .init(name: "wuqi", color: "#3CBB3A"),
                        .init(name: "dongke", color: "#1DA583"),
                        .init(name: "ranfei", color: "#BA1E55"),
                        .init(name: "fengying", color: "#B4A40E"),
                    ]
                ),
                .init(emailType: [.video], email: "alexander@proton.me", groups: []),
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

        return .init(contactDetails: { contact in
            .init(
                contact: contact,
                details: .init(
                    id: contact.id,
                    remoteId: "remote_\(contact.id.value)",
                    avatarInformation: contact.avatarInformation,
                    extendedName: .init(last: .none, first: .none),
                    fields: items
                )
            )
        })
    }
}
