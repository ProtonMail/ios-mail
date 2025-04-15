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

import Foundation
import XCTest

struct UITestConversationCollapsedHeaderEntryModel: ApplicationHolder {
    let index: Int

    // MARK: UI Elements

    private var rootItem: XCUIElement {
        application.otherElements["\(Identifiers.rootItem)#\(index)"]
    }

    private var senderNameText: XCUIElement {
        rootItem.staticTexts[Identifiers.senderName]
    }

    private var officialBadgeIcon: XCUIElement {
        rootItem.staticTexts[Identifiers.officialBadge]
    }

    private var dateText: XCUIElement {
        rootItem.staticTexts[Identifiers.date]
    }

    private var senderAddressText: XCUIElement {
        rootItem.staticTexts[Identifiers.senderAddress]
    }

    private var toRecipientsText: XCUIElement {
        rootItem.buttons[Identifiers.toRecipientsSummary]
    }

    // MARK: Actions

    func expand() {
        toRecipientsText.tap()
    }

    // MARK: Assertions

    func hasSenderName(_ sender: String) {
        XCTAssertEqual(senderNameText.label, sender)
    }

    func hasOfficialBadge(_ value: Bool) {
        XCTAssertEqual(officialBadgeIcon.exists, value)
    }

    func hasSenderAddress(_ address: String) {
        XCTAssertEqual(senderAddressText.label, address)
    }

    func hasDate(_ date: String) {
        XCTAssertEqual(dateText.label, date)
    }

    func hasToRecipientsSummary(_ summary: String) {
        XCTAssertEqual(toRecipientsText.label, summary)
    }
}

private struct Identifiers {
    static let rootItem = "detail.cell.expanded"
    static let senderName = "detail.header.sender.name"
    static let officialBadge = "detail.header.icon.badge"
    static let senderAddress = "detail.header.sender.address"
    static let date = "detail.header.date"
    static let toRecipientsSummary = "detail.header.recipients.summary"
}
