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
    let dummyName1 = "dummy name"
    let dummyAddress1 = "test1@example.com"
    let selectedRecipient = RecipientUIModel(type: .single, address: "inbox1@pm.me", isSelected: true, isValid: true, isEncrypted: false)
    let unselectedRecipient = RecipientUIModel(type: .single, address: "inbox2@pm.me", isSelected: false, isValid: true, isEncrypted: false)

    func testInit_whenNoStateIsPassed_itShouldReturnAnEmptyState() {
        let sut = ComposerModel()
        XCTAssertEqual(sut.state.toRecipients, RecipientFieldState.initialState(group: .to))
        XCTAssertEqual(sut.state.ccRecipients, RecipientFieldState.initialState(group: .cc))
        XCTAssertEqual(sut.state.bccRecipients, RecipientFieldState.initialState(group: .bcc))
    }

    // MARK: recipientToggleSelection

    func testRecipientToggleSelection_itShouldUpdateSelectedStatus() {
        var state = ComposerState.initial
        state.toRecipients.recipients = [unselectedRecipient]
        let sut = ComposerModel(state: state)

        sut.recipientToggleSelection(group: .to, index: 0)
        XCTAssertTrue(sut.state.toRecipients.recipients[0].isSelected)

        sut.recipientToggleSelection(group: .to, index: 0)
        XCTAssertFalse(sut.state.toRecipients.recipients[0].isSelected)
    }

    // MARK: removeSelectedRecipients

    func testRemoveSelectedRecipients_itShouldRemoveSelectedItems() {
        var state = ComposerState.initial
        state.toRecipients.recipients = [selectedRecipient, unselectedRecipient]
        let sut = ComposerModel(state: state)

        sut.removeSelectedRecipients(group: .to)
        XCTAssertEqual(sut.state.toRecipients.recipients, [unselectedRecipient])
    }

    // MARK: selectLastRecipient

    func testSelectLastRecipient_whenLastRecipientIsNotSelected_itSholdUpdateItsSelectedStatus() {
        var state = ComposerState.initial
        state.toRecipients.recipients = [selectedRecipient, unselectedRecipient]
        let sut = ComposerModel(state: state)

        sut.selectLastRecipient(group: .to)
        XCTAssertTrue(sut.state.toRecipients.recipients.last!.isSelected)
    }

    func testSelectLastRecipient_whenLastRecipientIsSelected_itSholdNotUpdateItsSelectedStatus() {
        var state = ComposerState.initial
        state.toRecipients.recipients = [unselectedRecipient, selectedRecipient]
        let sut = ComposerModel(state: state)

        sut.selectLastRecipient(group: .to)
        XCTAssertTrue(sut.state.toRecipients.recipients.last!.isSelected)
    }

    // MARK: addRecipient

    func testAddRecipient_itShouldAddTheRecipient() {
        let sut = ComposerModel()
        sut.addRecipient(group: .to, address: dummyAddress1)

        XCTAssertEqual(sut.state.toRecipients.recipients.first?.address, dummyAddress1)
        XCTAssertTrue(sut.state.ccRecipients.recipients.isEmpty)
        XCTAssertTrue(sut.state.bccRecipients.recipients.isEmpty)
    }

    // MARK: addContact

    func testAddContact_whenIsSingleContact_itShouldUpdateTheRecipients() {
        let sut = ComposerModel()
        let contact = ComposerContact(type: .single(.init(name: dummyName1, email: dummyAddress1)))
        sut.addContact(group: .to, contact: contact)

        XCTAssertEqual(sut.state.toRecipients.recipients.first?.address, dummyAddress1)
        XCTAssertTrue(sut.state.ccRecipients.recipients.isEmpty)
        XCTAssertTrue(sut.state.bccRecipients.recipients.isEmpty)
    }

    func testAddContact_whenIsAGroup_itShouldUpdateTheRecipientss() {
        let sut = ComposerModel()
        let contact = ComposerContact(type: .group(.init(name: dummyName1, totalMembers: 3)))
        sut.addContact(group: .to, contact: contact)

        XCTAssertEqual(sut.state.toRecipients.recipients.first?.address, dummyName1)
        XCTAssertTrue(sut.state.ccRecipients.recipients.isEmpty)
        XCTAssertTrue(sut.state.bccRecipients.recipients.isEmpty)
    }

    // MARK: matchContacts

    @MainActor
    func testMatchContacts_whenThereIsMatch_itShouldUpdateStateWithMatchingContacts() {
        let mockProvider = ComposerContactProvider(contacts: [
            .init(type: .single(.init(name: "Adrian", email: "adrian@example.com"))),
            .init(type: .single(.init(name: "Su", email: "susan.cohen@example.com"))),
            .init(type: .group(.init(name: "Team", totalMembers: 4))),
        ])
        let sut = ComposerModel(contactProvider: mockProvider)

        sut.matchContact(group: .to, text: "A")
        XCTAssertEqual(sut.state.toRecipients.matchingContacts.count, 3)

        sut.matchContact(group: .to, text: "susan")
        XCTAssertEqual(sut.state.toRecipients.matchingContacts.count, 1)

        sut.matchContact(group: .to, text: "team")
        XCTAssertEqual(sut.state.toRecipients.matchingContacts.count, 1)
        XCTAssertEqual(sut.state.toRecipients.matchingContacts.first?.type, .group(.init(name: "Team", totalMembers: 4)))
    }

    @MainActor
    func testMatchContacts_whenThereIsMatch_itShouldUpdateControllerStateWithContactPicker() {
        let mockProvider = ComposerContactProvider(contacts: [
            .init(type: .single(.init(name: "Adrian", email: "adrian@example.com")))
        ])
        let sut = ComposerModel(contactProvider: mockProvider)

        sut.matchContact(group: .to, text: "Adrian")
        XCTAssertEqual(sut.state.toRecipients.controllerState, .contactPicker)
    }

    @MainActor
    func testMatchContacts_whenThereIsNoMatch_itShouldUpdateStateWithoutMatchingContacts() {
        let mockProvider = ComposerContactProvider(contacts: [
            .init(type: .single(.init(name: "Adrian", email: "adrian@example.com"))),
            .init(type: .single(.init(name: "Bea", email: "bea@example.com"))),
        ])
        let sut = ComposerModel(contactProvider: mockProvider)

        sut.matchContact(group: .to, text: "Adrian")
        XCTAssertEqual(sut.state.toRecipients.matchingContacts.count, 1)

        sut.matchContact(group: .to, text: "Mark")
        XCTAssertEqual(sut.state.toRecipients.matchingContacts.count, 0)
    }

    @MainActor
    func testMatchContacts_whenThereIsNoMatch_itShouldUpdateControllerStateWithContactPicker() {
        let mockProvider = ComposerContactProvider(contacts: [
            .init(type: .single(.init(name: "Adrian", email: "adrian@example.com"))),
        ])
        let sut = ComposerModel(contactProvider: mockProvider)

        sut.matchContact(group: .to, text: "Adrian")
        XCTAssertEqual(sut.state.toRecipients.matchingContacts.count, 1)
        XCTAssertEqual(sut.state.toRecipients.controllerState, .contactPicker)

        sut.matchContact(group: .to, text: "Mark")
        XCTAssertEqual(sut.state.toRecipients.controllerState, .editing)
    }

    @MainActor
    func testMatchContacts_itShouldUpdateTheInputState() {
        let sut = ComposerModel()

        sut.matchContact(group: .to, text: "Adrian")
        XCTAssertEqual(sut.state.toRecipients.input, "Adrian")
    }

    // MARK: finishEditing

    func testFinishEditing_itShouldUnselectAllRecipients() {
        var state = ComposerState.initial
        state.toRecipients.recipients = [unselectedRecipient, selectedRecipient]
        let sut = ComposerModel(state: state)

        XCTAssertEqual(sut.state.toRecipients.recipients.filter { $0.isSelected }.count, 1)
        sut.finishEditing(group: .to)
        XCTAssertEqual(sut.state.toRecipients.recipients.filter { $0.isSelected }.count, 0)
    }

    @MainActor
    func testFinishEditing_itShouldResetInputState() {
        let sut = ComposerModel()

        sut.matchContact(group: .to, text: "Adrian")
        XCTAssertFalse(sut.state.toRecipients.input.isEmpty)

        sut.finishEditing(group: .to)
        XCTAssertTrue(sut.state.toRecipients.input.isEmpty)
    }

    @MainActor
    func testFinishEditing_itShouldUpdateControllerStateToIdle() {
        let sut = ComposerModel()

        sut.matchContact(group: .to, text: "Adrian")
        XCTAssertEqual(sut.state.toRecipients.controllerState, .editing)

        sut.finishEditing(group: .to)
        XCTAssertEqual(sut.state.toRecipients.controllerState, .idle)
    }
}
