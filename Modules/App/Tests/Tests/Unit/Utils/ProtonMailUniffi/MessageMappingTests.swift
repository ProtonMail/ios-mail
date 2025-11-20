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

import XCTest
import proton_app_uniffi

@testable import ProtonMail

final class MessageMappingTests: XCTestCase {
    private let recipient1: MessageRecipient = .testData(name: "The Rec.A", address: "a@example.com")
    private let recipient2: MessageRecipient = .testData(name: "", address: "b@example.com")
    private let recipient3: MessageRecipient = .testData(name: "The Rec.C", address: "c@example.com")

    func testToMailboxItemCellUIModel_whenSelectedItems_itReturnsTheMessagesAsSelectedIfItMacthes() {
        let message = Message.testData(messageId: 33)

        let result1 = message.toMailboxItemCellUIModel(
            selectedIds: [.init(value: 12)], displaySenderEmail: .random(),
            showLocation: Bool.random()
        )
        XCTAssertFalse(result1.isSelected)

        let result2 = message.toMailboxItemCellUIModel(
            selectedIds: [.init(value: 33)], displaySenderEmail: .random(),
            showLocation: Bool.random()
        )
        XCTAssertTrue(result2.isSelected)
    }

    func testToMailboxItemCellUIModel_whenDoNotDisplaySenderEmail_itReturnsRecipientsInEmailsField() {
        let message = Message.testData(to: [recipient1], cc: [recipient2], bcc: [recipient3])
        let result = message.toMailboxItemCellUIModel(displaySenderEmail: false)
        XCTAssertEqual(result.emails, "The Rec.A, b@example.com, The Rec.C")
    }

    func testToMailboxItemCellUIModel_whenDoNotDisplaySenderEmail_andNoRecipients_itReturnsAPlaceholderInEmailsField() {
        let message = Message.testData(to: [], cc: [], bcc: [])
        let result = message.toMailboxItemCellUIModel(displaySenderEmail: false)
        XCTAssertEqual(result.emails, "(No Recipient)")
    }

    func testToMailboxItemCellUIModel_whenDisplaySenderEmail_itReturnsSenderInEmailsField() {
        let message = Message.testData(to: [recipient1], cc: [recipient2], bcc: [recipient3])
        let result = message.toMailboxItemCellUIModel(displaySenderEmail: true)
        XCTAssertEqual(result.emails, "sender@example.com")
    }

    func testToMailboxItemCellUIModel_whenShowLocationIsTrue_itReturnsTheLocationIcon() {
        let message = Message.testData(to: [recipient1], cc: [recipient2], bcc: [recipient3])
        let result = message.toMailboxItemCellUIModel(showLocation: true)
        XCTAssertNotNil(result.locationIcon)
    }

    func testToMailboxItemCellUIModel_whenShowLocationIsFalse_itReturnsNilForLocationIcon() {
        let message = Message.testData(to: [recipient1], cc: [recipient2], bcc: [recipient3])
        let result = message.toMailboxItemCellUIModel(showLocation: false)
        XCTAssertNil(result.locationIcon)
    }

}

private extension Message {

    func toMailboxItemCellUIModel(showLocation: Bool) -> MailboxItemCellUIModel {
        toMailboxItemCellUIModel(selectedIds: [], displaySenderEmail: Bool.random(), showLocation: showLocation)
    }

    func toMailboxItemCellUIModel(displaySenderEmail: Bool) -> MailboxItemCellUIModel {
        toMailboxItemCellUIModel(selectedIds: [], displaySenderEmail: displaySenderEmail, showLocation: Bool.random())
    }

}

extension String {
    static let notUsed = "__NOT_USED__"
}
