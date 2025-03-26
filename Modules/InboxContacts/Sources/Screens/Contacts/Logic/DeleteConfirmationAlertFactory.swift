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
    static func make(
        for itemToDelete: ContactItemType,
        action: @escaping (DeleteItemAlertAction) -> Void
    ) -> AlertViewModel {
        let actions: [AlertAction] = [
            .confirm(action: { action(.confirm) }),
            .cancel(action: { action(.cancel) })
        ]
        switch itemToDelete {
        case .contact(let contactItem):
            return .init(
                title: L10n.Contacts.DeletionAlert.title(name: contactItem.name),
                message: L10n.Contacts.DeletionAlert.Contact.message,
                actions: actions
            )
        case .group(let groupItem):
            return .init(
                title: L10n.Contacts.DeletionAlert.title(name: groupItem.name),
                message: L10n.Contacts.DeletionAlert.ContactGroup.message,
                actions: actions
            )
        }
    }
}

private extension AlertAction {
    
    static func confirm(action: @escaping () -> Void) -> AlertAction {
        AlertAction(title: L10n.Contacts.DeletionAlert.delete, buttonRole: .destructive, action: action)
    }
    
    static func cancel(action: @escaping () -> Void) -> AlertAction {
        AlertAction(title: L10n.Contacts.DeletionAlert.cancel, buttonRole: .cancel, action: action)
    }

}
