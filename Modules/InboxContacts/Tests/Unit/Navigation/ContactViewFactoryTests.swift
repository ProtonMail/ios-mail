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
import proton_app_uniffi
import SwiftUI
import Testing
import ViewInspector

@MainActor
final class ContactViewFactoryTests {
    let sut = ContactViewFactory(mailUserSession: .init(noPointer: .init()))

    @Test
    func testView_ForContactDetailsRoute_ItReturnsContactDetailsScreen() throws {
        let id = Id(value: 1)
        let view = try makeView(for: .contactDetails(.testData(id: id)))

        let inspectableScreen = try view.find(ContactDetailsScreen.self)
        let screen = try inspectableScreen.actualView()

        #expect(screen.contact.id == id)
    }

    @Test
    func testView_ForContactGroupDetailsRoute_ItReturnsContactDetailsScreen() throws {
        let group = ContactGroupItem.advisorsGroup
        let view = try makeView(for: .contactGroupDetails(group))

        let inspectableScreen = try view.find(ContactGroupDetailsScreen.self)
        let screen = try inspectableScreen.actualView()

        #expect(screen.group.id == group.id)
    }

    // MARK: - Private

    private func makeView(for route: ContactsRoute) throws -> InspectableView<ViewType.ClassifiedView> {
        try sut.makeView(for: route).inspect()
    }
}
