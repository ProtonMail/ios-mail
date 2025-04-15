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
import ProtonMail

struct UITestConversationExpandedHeaderEntryModel: ApplicationHolder {
    let index: Int

    // MARK: UI Elements

    private var rootItem: XCUIElement {
        application.otherElements["\(Identifiers.rootItem)#\(index)"]
            .otherElements[Identifiers.headerRootItem]
    }

    private var senderLabelText: XCUIElement {
        rootItem.staticTexts[Identifiers.senderLabelText]
    }

    private var senderNameText: XCUIElement {
        rootItem.staticTexts[Identifiers.senderNameText]
    }

    private var senderAddressText: XCUIElement {
        rootItem.staticTexts[Identifiers.senderAddressText]
    }

    private var dateLabel: XCUIElement {
        rootItem.staticTexts[Identifiers.dateLabel]
    }

    private var dateText: XCUIElement {
        rootItem.staticTexts[Identifiers.dateText]
    }

    // MARK: Actions

    func tapSender() {
        senderNameText.tap()
    }

    func tapRecipient(ofType type: UITestsRecipientsFieldType, atPosition index: Int) {
        let name = rootItem.staticTexts[Identifiers.recipientName(type: type, atIndex: index)]
        name.tap()
    }

    // MARK: Assertions

    func hasSenderName(_ sender: String) {
        XCTAssertEqual(senderNameText.label, sender)
    }

    func hasSenderAddress(_ address: String) {
        XCTAssertEqual(senderAddressText.label, address)
    }

    func hasDate(_ timestamp: UInt64) {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        XCTAssertEqual(dateText.label, date.formatted(date: .abbreviated, time: .standard))
    }

    func hasNoRecipients(ofType type: UITestsRecipientsFieldType) {
        let label = rootItem.staticTexts[Identifiers.recipientLabel(type: type)]
        XCTAssertFalse(label.exists)
    }

    func hasRecipients(ofType type: UITestsRecipientsFieldType, recipients: [UITestHeaderRecipientEntry]) {
        for recipient in recipients {
            hasRecipient(ofType: type, entry: recipient)
        }
    }

    private func hasRecipient(ofType type: UITestsRecipientsFieldType, entry: UITestHeaderRecipientEntry) {
        let label = rootItem.staticTexts[Identifiers.recipientLabel(type: type)]
        let name = rootItem.staticTexts[Identifiers.recipientName(type: type, atIndex: entry.index)]
        let address = rootItem.staticTexts[Identifiers.recipientAddress(type: type, atIndex: entry.index)]

        XCTAssertTrue(label.exists)
        XCTAssertEqual(name.label, entry.name)
        XCTAssertEqual(address.label, entry.address)
    }
}

private struct Identifiers {
    static let rootItem = "detail.cell.expanded"

    static let headerRootItem = "detail.header.expanded.root"
    static let senderLabelText = "detail.header.expanded.sender.label"
    static let senderNameText = "detail.header.expanded.sender.name"
    static let senderAddressText = "detail.header.expanded.sender.address"

    static func recipientLabel(type: UITestsRecipientsFieldType) -> String {
        "details.header.expanded.\(type.rawValue).label"
    }

    static func recipientName(type: UITestsRecipientsFieldType, atIndex index: Int) -> String {
        "details.header.expanded.\(type.rawValue).name#\(index)"
    }

    static func recipientAddress(type: UITestsRecipientsFieldType, atIndex index: Int) -> String {
        "details.header.expanded.\(type.rawValue).value#\(index)"
    }

    static let dateLabel = "detail.header.expanded.date.label"
    static let dateText = "detail.header.expanded.date.value"
}
