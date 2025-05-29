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

@testable import ProtonMail
import InboxDesignSystem
import InboxTesting
import proton_app_uniffi
import SwiftUI
import XCTest

final class ExclusiveLocation_ModelTests: BaseTestCase {

    struct TestCase {
        let given: ExclusiveLocation
        let expected: MessageDetail.Location
    }

    func testModel_ForGivenLocation_IsMappedCorrectly() {
        let testCases: [TestCase] = [
            .init(
                given: .system(.inbox),
                expected: .init(name: L10n.Mailbox.SystemFolder.inbox, icon: DS.Icon.icInbox.image, iconColor: nil)
            ),
            .init(
                given: .system(.trash),
                expected: .init(name: L10n.Mailbox.SystemFolder.trash, icon: DS.Icon.icTrash.image, iconColor: nil)
            ),
            .init(
                given: .system(.archive),
                expected: .init(name: L10n.Mailbox.SystemFolder.archive, icon: DS.Icon.icArchiveBox.image, iconColor: nil)
            ),
            .init(
                given: .system(.spam),
                expected: .init(name: L10n.Mailbox.SystemFolder.spam, icon: DS.Icon.icFire.image, iconColor: nil)
            ),
            .init(
                given: .system(.snoozed),
                expected: .init(name: L10n.Mailbox.SystemFolder.snoozed, icon: DS.Icon.icClock.image, iconColor: nil)
            ),
            .init(
                given: .system(.scheduled),
                expected: .init(name: L10n.Mailbox.SystemFolder.allScheduled, icon: DS.Icon.icClockPaperPlane.image, iconColor: nil)
            ),
            .init(
                given: .system(.outbox),
                expected: .init(name: L10n.Mailbox.SystemFolder.outbox, icon: DS.Icon.icOutbox.image, iconColor: nil)
            ),
            .init(
                given: .custom(name: "Online shopping", id: .random(), color: .init(value: "FFA500")),
                expected: .init(
                    name: "Online shopping",
                    icon: DS.Icon.icFolderOpenFilled.image,
                    iconColor: Color(hex: "FFA500")
                )
            )
        ]

        testCases.forEach { testCase in
            XCTAssertEqual(testCase.given.model, testCase.expected)
        }
    }

}
