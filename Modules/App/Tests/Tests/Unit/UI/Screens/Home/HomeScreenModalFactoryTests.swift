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
@testable import ProtonMail
import SwiftUI
import ViewInspector
import XCTest

@MainActor
final class HomeScreenModalFactoryTests: XCTestCase {
    func testMakeModal_ForContactsState_ItReturnsContactsScreen() throws {
        let inspect = try modal(for: .contacts)

        XCTAssertNoThrow(try inspect.find(ContactsScreen.self))
    }

    func testMakeModal_ForLabelOrFolderCreationState_ItReturnsLabelOrFolderCreationScreenScreen() throws {
        let inspect = try modal(for: .labelOrFolderCreation)

        XCTAssertNoThrow(try inspect.find(CreateFolderOrLabelScreen.self))
    }

    func testMakeModal_ForSettingsState_ItReturnsSettingsScreen() throws {
        let inspect = try modal(for: .settings)

        XCTAssertNoThrow(try inspect.find(SettingsScreen.self))
    }

    // MARK: - Private

    private func modal(for state: HomeScreen.ModalState) throws -> InspectableView<ViewType.ClassifiedView> {
        let factory = HomeScreenModalFactory(mailUserSession: .dummy, toastStateStore: .init(initialState: .initial))
        return try factory.makeModal(for: state).inspect()
    }
}
