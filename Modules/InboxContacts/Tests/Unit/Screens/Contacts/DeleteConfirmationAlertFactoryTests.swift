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

import Testing

@testable import InboxContacts
@testable import proton_app_uniffi

struct DeleteConfirmationAlertFactoryTests {
    @Test
    func makeAlertForContact_ItReturnsCorrectAlert() throws {
        let itemToDelete: ContactItemType = .contact(.vip)

        let alert = DeleteConfirmationAlertFactory.make(for: itemToDelete, action: { _ in })

        #expect(alert.title == L10n.Contacts.DeletionAlert.title(name: ContactItem.vip.name))
        #expect(alert.message == L10n.Contacts.DeletionAlert.Contact.message)
        #expect(alert.actions.map(\.title.string) == ["Delete", "Cancel"])
        #expect(alert.actions.map(\.buttonRole) == [.destructive, .cancel])
    }

    @Test
    func makeAlertForContactGroup_ItReturnsCorrectAlert() throws {
        let itemToDelete: ContactItemType = .group(.advisorsGroup)

        let alert = DeleteConfirmationAlertFactory.make(for: itemToDelete, action: { _ in })

        #expect(alert.title == L10n.Contacts.DeletionAlert.title(name: ContactGroupItem.advisorsGroup.name))
        #expect(alert.message == L10n.Contacts.DeletionAlert.ContactGroup.message)
        #expect(alert.actions.map(\.title.string) == ["Delete", "Cancel"])
        #expect(alert.actions.map(\.buttonRole) == [.destructive, .cancel])
    }
}
