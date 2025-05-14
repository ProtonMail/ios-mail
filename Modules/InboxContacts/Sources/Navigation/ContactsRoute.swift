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
            ContactDetailsScreen(
                model: .init(
                    id: contact.id,
                    avatarInformation: contact.avatarInformation,
                    displayName: contact.name,
                    primaryEmail: contact.emails.first?.email ?? "",
                    primaryPhone: .none,
                    groupItems: []
                )
            )
        case .contactGroupDetails(let id):
            ContactGroupDetailsScreen(id: id)
        }
    }
}
