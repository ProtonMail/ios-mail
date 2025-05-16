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
    let _contactDetails: (Id) async -> ContactDetails

    init(contactDetails: @escaping (Id) async -> ContactDetails) {
        _contactDetails = contactDetails
    }

    func contactDetails(forContactID contactID: Id) async -> ContactDetails {
        await _contactDetails(contactID)
    }
}

extension ContactDetailsProvider {

    static func previewInstance() -> Self {
        let groupItems: [[ContactDetailsItem]] = [
            [
                .init(label: "Work", value: "ben.ale@protonmail.com", isInteractive: true),
                .init(label: "Private", value: "alexander@proton.me", isInteractive: true),
            ],
            [
                .init(label: "Address", value: "Lettensteg 10, 8037 Zürich", isInteractive: true),
                .init(label: "Address", value: "Uetlibergstrasse 872, 8025 Zürich", isInteractive: true),
            ],
            [
                .init(label: "Birthday", value: "Jan 23, 2004", isInteractive: false)
            ],
            [
                .init(
                    label: "Note",
                    value: "Met Caleb while studying abroad. Amazing memories and a strong friendship.",
                    isInteractive: false
                )
            ],
        ]

        let details = ContactDetails(
            id: .init(value: 50),
            avatarInformation: .init(text: "B", color: "#3357FF"),
            displayName: "Benjamin Alexander",
            primaryEmail: "ben.ale@protonmail.com",
            primaryPhone: .none,
            groupItems: groupItems
        )

        return .init(contactDetails: { _ in details })
    }

}
