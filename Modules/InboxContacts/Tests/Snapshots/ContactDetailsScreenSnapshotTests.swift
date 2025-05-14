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

final class ContactDetailsScreenSnapshotTests: XCTestCase {

    func testContactDetailsScreenLayoutsCorrectOnIphoneX() {
        assertSnapshotsOnIPhoneX(of: makeSUT())
    }

    // MARK: - Private

    private func makeSUT() -> ContactDetailsScreen {
        let groupItems: [[ContactDetailItem]] = [
            [
                .init(label: "Work", value: "ben.ale@protonmail.com", isInteractive: true),
                .init(label: "Private", value: "alexander@proton.me", isInteractive: true)
            ],
            [
                .init(label: "Address", value: "Lettensteg 10, 8037 Zürich", isInteractive: true),
                .init(label: "Address", value: "Uetlibergstrasse 872, 8025 Zürich", isInteractive: true)
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
            ]
        ]

        return .init(
            model: .init(
                id: .init(value: 1_911),
                avatarInformation: .init(text: "B", color: "#3357FF"),
                displayName: "Benjamin Alexander",
                primaryEmail: "ben.ale@protonmail.com",
                primaryPhone: .none,
                groupItems: groupItems
            )
        )
    }

}
