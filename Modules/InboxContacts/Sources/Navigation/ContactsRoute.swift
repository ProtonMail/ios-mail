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
import SwiftUI

enum ContactsRoute: Routable {
    case contactDetails(ContactItem)
    case contactGroupDetails(id: Id)

    @ViewBuilder
    func view() -> some View {
        switch self {
        case .contactDetails(let contact):
            let groupItems: [[ContactDetailItem]] = [
                [
                    .init(label: "Work", value: "ben.ale@protonmail.com", isInteractive: true),
                    .init(label: "Private", value: "alexander@proton.me", isInteractive: true),
                ],
                [
                    .init(label: "Home", value: "+370 (637) 98 998", isInteractive: true),
                    .init(label: "Work", value: "+370 (637) 98 999", isInteractive: true),
                ],
                [
                    .init(label: "Address", value: "Lettensteg 10, 8037 Zurich", isInteractive: true)
                ],
                [
                    .init(label: "Birthday", value: "Dec 09, 2006", isInteractive: false)
                ],
                [
                    .init(
                        label: "Note",
                        value: "Met Caleb while studying abroad. Amazing memories and a strong friendship.",
                        isInteractive: false
                    )
                ]
            ]
            ContactDetailsScreen(
                model: .init(
                    id: contact.id,
                    avatarInformation: contact.avatarInformation,
                    displayName: contact.name,
                    primaryEmail: contact.emails.first?.email ?? "",
                    primaryPhone: .none,
                    groupItems: groupItems
                )
            )
        case .contactGroupDetails(let id):
            ContactGroupDetailsScreen(id: id)
        }
    }
}
