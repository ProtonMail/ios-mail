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
import XCTest

final class ContactsScreenSnapshotTests: XCTestCase {

    @MainActor
    func testContactsScreenWithContactsLayoutsCorrectOnIphoneX() async throws {
        let provider = GroupedContactsProvider.previewInstance()
        let items = try await provider.allContacts(.testInstance())

        assertSnapshotsOnIPhoneX(of: makeSUT(items: items))
    }

    func testContactsScreenInEmptyStateLayoutsCorrectOnIphoneX() {
        assertSnapshotsOnIPhoneX(of: makeSUT(items: []))
    }

    private func makeSUT(items: [GroupedContacts]) -> ContactsScreen {
        ContactsScreen(
            state: .init(items: items),
            mailUserSession: .testInstance(),
            contactsProvider: .previewInstance()
        )
    }

}
