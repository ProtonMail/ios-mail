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

import InboxCoreUI
import proton_app_uniffi

enum DeleteConfirmationAlertFactory {
    static func make(for itemToDelete: ContactItemType?) -> AlertViewModel<DeleteItemAlertAction>? {
        guard let item = itemToDelete else {
            return nil
        }

        let actions: [DeleteItemAlertAction] = [.confirm, .cancel]

        switch item {
        case .contact:
            return .init(
                title: L10n.Contacts.DeletionAlert.Contact.title,
                message: L10n.Contacts.DeletionAlert.Contact.message,
                actions: actions
            )
        case .group:
            return .init(
                title: L10n.Contacts.DeletionAlert.ContactGroup.title,
                message: L10n.Contacts.DeletionAlert.ContactGroup.message,
                actions: actions
            )
        }
    }
}
