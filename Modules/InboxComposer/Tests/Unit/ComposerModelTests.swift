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
@testable import InboxComposer

final class ComposerModelTests: XCTestCase {
    let dummyAddress1 = "test1@example.com"
    let selectedRecipient = RecipientUIModel(type: .single, address: "inbox1@pm.me", isSelected: true, isValid: true, isEncrypted: false)
    let unselectedRecipient = RecipientUIModel(type: .single, address: "inbox2@pm.me", isSelected: false, isValid: true, isEncrypted: false)

    func testInit_whenNoStateIsPassed_itShouldReturnAnEmptyState() {
        let sut = ComposerModel()
        XCTAssertEqual(sut.state, .init(recipients: []))
    }

    func testRecipientToggleSelection_itShouldUpdateSelectedStatus() {
        let sut = ComposerModel(state: ComposerState(recipients: [unselectedRecipient]))

        sut.recipientToggleSelection(group: .to, index: 0)
        XCTAssertTrue(sut.state.recipients[0].isSelected)

        sut.recipientToggleSelection(group: .to, index: 0)
        XCTAssertFalse(sut.state.recipients[0].isSelected)
    }

    func testRemoveSelectedRecipients_itShouldRemoveSelectedItems() {
        let customState = ComposerState(recipients: [selectedRecipient, unselectedRecipient])
        let sut = ComposerModel(state: customState)

        sut.removeSelectedRecipients(group: .to)
        XCTAssertEqual(sut.state.recipients, [unselectedRecipient])
    }

    func testSelectLastRecipient_whenLastRecipientIsNotSelected_itSholdUpdateItsSelectedStatus() {
        let customState = ComposerState(recipients:  [selectedRecipient, unselectedRecipient])
        let sut = ComposerModel(state: customState)

        sut.selectLastRecipient(group: .to)
        XCTAssertTrue(sut.state.recipients.last!.isSelected)
    }

    func testSelectLastRecipient_whenLastRecipientIsSelected_itSholdNotUpdateItsSelectedStatus() {
        let customState = ComposerState(recipients:  [unselectedRecipient, selectedRecipient])
        let sut = ComposerModel(state: customState)

        sut.selectLastRecipient(group: .to)
        XCTAssertTrue(sut.state.recipients.last!.isSelected)
    }

    func testAddRecipient_itShouldAddTheRecipient() {
        let sut = ComposerModel()
        sut.addRecipient(group: .to, address: dummyAddress1)

        XCTAssertEqual(sut.state.recipients.first?.address, dummyAddress1)
    }
}
