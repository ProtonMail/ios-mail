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

import Combine
@testable import InboxComposer
import struct SwiftUI.Color
import XCTest

final class ComposerModelTests: XCTestCase {
    private var testContactProvider: ComposerContactProvider!
    let dummyName1 = "dummy name"
    let dummyAddress1 = "test1@example.com"
    let selectedRecipient = RecipientUIModel(type: .single, address: "inbox1@pm.me", isSelected: true, isValid: true, isEncrypted: false)
    let unselectedRecipient = RecipientUIModel(type: .single, address: "inbox2@pm.me", isSelected: false, isValid: true, isEncrypted: false)
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        self.testContactProvider = ComposerContactProvider(
            protonContactsDatasource: ComposerTestContactsDatasource(dummyContacts: [
                .init(type: .single(.init(email: "a@example.com"))),
                .init(type: .single(.init(email: "b@protonmail.com"))),
                .init(type: .single(.init(email: "c@pm.me"))),
            ])
        )
        self.cancellables = []
    }

    override func tearDown() {
        super.tearDown()
        self.testContactProvider = nil
        self.cancellables = nil
    }

    func testInit_whenNoStateIsPassed_itShouldReturnAnEmptyState() {
        let sut = ComposerModel(contactProvider: testContactProvider)
        XCTAssertEqual(sut.state.toRecipients, RecipientFieldState.initialState(group: .to))
        XCTAssertEqual(sut.state.ccRecipients, RecipientFieldState.initialState(group: .cc))
        XCTAssertEqual(sut.state.bccRecipients, RecipientFieldState.initialState(group: .bcc))
    }

    // MARK: recipientToggleSelection

    @MainActor
    func testRecipientToggleSelection_itShouldUpdateSelectedStatus() {
        var state = ComposerState.initial
        state.toRecipients.recipients = [unselectedRecipient]
        let sut = ComposerModel(state: state, contactProvider: testContactProvider)

        sut.recipientToggleSelection(group: .to, index: 0)
        XCTAssertTrue(sut.state.toRecipients.recipients[0].isSelected)

        sut.recipientToggleSelection(group: .to, index: 0)
        XCTAssertFalse(sut.state.toRecipients.recipients[0].isSelected)
    }

    // MARK: removeSelectedRecipients

    @MainActor
    func testRemoveSelectedRecipients_itShouldRemoveSelectedItems() {
        var state = ComposerState.initial
        state.toRecipients.recipients = [selectedRecipient, unselectedRecipient]
        let sut = ComposerModel(state: state, contactProvider: testContactProvider)

        sut.removeSelectedRecipients(group: .to)
        XCTAssertEqual(sut.state.toRecipients.recipients, [unselectedRecipient])
    }

    // MARK: selectLastRecipient

    @MainActor
    func testSelectLastRecipient_whenLastRecipientIsNotSelected_itSholdUpdateItsSelectedStatus() {
        var state = ComposerState.initial
        state.toRecipients.recipients = [selectedRecipient, unselectedRecipient]
        let sut = ComposerModel(state: state, contactProvider: testContactProvider)

        sut.selectLastRecipient(group: .to)
        XCTAssertTrue(sut.state.toRecipients.recipients.last!.isSelected)
    }

    @MainActor
    func testSelectLastRecipient_whenLastRecipientIsSelected_itSholdNotUpdateItsSelectedStatus() {
        var state = ComposerState.initial
        state.toRecipients.recipients = [unselectedRecipient, selectedRecipient]
        let sut = ComposerModel(state: state, contactProvider: testContactProvider)

        sut.selectLastRecipient(group: .to)
        XCTAssertTrue(sut.state.toRecipients.recipients.last!.isSelected)
    }

    // MARK: addRecipient

    @MainActor
    func testAddRecipient_itShouldAddTheRecipient() {
        let sut = ComposerModel(contactProvider: testContactProvider)
        sut.addRecipient(group: .to, address: dummyAddress1)

        XCTAssertEqual(sut.state.toRecipients.recipients.first?.address, dummyAddress1)
        XCTAssertTrue(sut.state.ccRecipients.recipients.isEmpty)
        XCTAssertTrue(sut.state.bccRecipients.recipients.isEmpty)
    }

    // MARK: addContact

    @MainActor
    func testAddContact_whenIsSingleContact_itShouldUpdateTheRecipients() {
        let sut = ComposerModel(contactProvider: testContactProvider)
        let contact = ComposerContact(type: .single(.init(name: dummyName1, email: dummyAddress1)))
        sut.addContact(group: .to, contact: contact)

        XCTAssertEqual(sut.state.toRecipients.recipients.first?.address, dummyAddress1)
        XCTAssertTrue(sut.state.ccRecipients.recipients.isEmpty)
        XCTAssertTrue(sut.state.bccRecipients.recipients.isEmpty)
    }

    @MainActor
    func testAddContact_whenIsAGroup_itShouldUpdateTheRecipientss() {
        let sut = ComposerModel(contactProvider: testContactProvider)
        let contact = ComposerContact(type: .group(.init(name: dummyName1, totalMembers: 3)))
        sut.addContact(group: .to, contact: contact)

        XCTAssertEqual(sut.state.toRecipients.recipients.first?.address, dummyName1)
        XCTAssertTrue(sut.state.ccRecipients.recipients.isEmpty)
        XCTAssertTrue(sut.state.bccRecipients.recipients.isEmpty)
    }

    // MARK: matchContacts

    @MainActor
    func testMatchContacts_whenThereIsMatch_itShouldUpdateStateWithMatchingContacts() async {
        let mockProvider = ComposerContactProvider.testInstance(datasourceContacts: [
            .init(type: .single(.init(name: "Adrian", email: "adrian@example.com"))),
            .init(type: .single(.init(name: "Su", email: "susan.cohen@example.com"))),
            .init(type: .group(.init(name: "Team", totalMembers: 4))),
        ])

        let tests: [MatchContactTestCase] = [("A", 3), ("susan", 1), ("team", 1)]
        for test in tests {
            let sut = ComposerModel(contactProvider: mockProvider)
            await sut.onLoad()
            await testMatchContact(in: sut, test: test)
        }
    }

    @MainActor
    func testMatchContacts_whenThereIsMatch_itShouldUpdateControllerStateWithContactPicker() async {
        let mockProvider = ComposerContactProvider.testInstance(datasourceContacts: [
            .init(type: .single(.init(name: "Adrian", email: "adrian@example.com")))
        ])
        let sut = ComposerModel(contactProvider: mockProvider)
        await sut.onLoad()

        let expectation = expectation(description: "\(#function)")
        fulfill(expectation, in: sut, when: { composerState in
            composerState.toRecipients.controllerState == .contactPicker
        })
        sut.matchContact(group: .to, text: "Adrian")
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    @MainActor
    func testMatchContacts_whenThereIsNoMatch_itShouldUpdateStateWithoutMatchingContacts() async {
        let initialState = ComposerState.mockState(
            matchingContacts: [.init(type: .single(.init(name: "Adrian", email: "adrian@example.com")))],
            controllerState: .editing
        )
        let mockProvider = ComposerContactProvider.testInstance(datasourceContacts: [
            .init(type: .single(.init(name: "Adrian", email: "adrian@example.com"))),
            .init(type: .single(.init(name: "Bea", email: "bea@example.com"))),
        ])

        let sut = ComposerModel(state: initialState, contactProvider: mockProvider)
        await sut.onLoad()
        XCTAssertEqual(sut.state.toRecipients.matchingContacts.count, 1)

        await testMatchContact(in: sut, test: MatchContactTestCase(input: "Mark", expectedMatchCount: 0))
    }

    @MainActor
    func testMatchContacts_whenThereIsNoMatch_itShouldUpdateControllerStateWithContactEditing() async {
        let initialState = ComposerState.mockState(
            matchingContacts: [.init(type: .single(.init(name: "Adrian", email: "adrian@example.com")))],
            controllerState: .contactPicker
        )
        let mockProvider = ComposerContactProvider.testInstance(datasourceContacts: [
            .init(type: .single(.init(name: "Adrian", email: "adrian@example.com")))
        ])

        let sut = ComposerModel(state: initialState, contactProvider: mockProvider)
        XCTAssertEqual(sut.state.toRecipients.matchingContacts.count, 1)
        XCTAssertEqual(sut.state.toRecipients.controllerState, .contactPicker)
        await sut.onLoad()

        let expectation = expectation(description: "\(#function)")
        expectation.assertForOverFulfill = false
        fulfill(expectation, in: sut, when: { composerState in
            composerState.toRecipients.input == "Mark" && composerState.toRecipients.controllerState == .editing
        })
        sut.matchContact(group: .to, text: "Mark")
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: endEditingRecipients

    @MainActor
    func testEndEditingRecipients_itShouldCleanInputAndSetControllerStateToIdle() async {
        let initialState = ComposerState.mockState(
            matchingContacts: [.init(type: .single(.init(name: "Adrian", email: "adrian@example.com")))],
            controllerState: .contactPicker
        )
        let mockProvider = ComposerContactProvider.testInstance(datasourceContacts: [
            .init(type: .single(.init(name: "Adrian", email: "adrian@example.com")))
        ])

        let sut = ComposerModel(state: initialState, contactProvider: mockProvider)
        XCTAssertEqual(sut.state.toRecipients.matchingContacts.count, 1)
        XCTAssertEqual(sut.state.toRecipients.controllerState, .contactPicker)

        let expectation = expectation(description: "\(#function)")
        fulfill(expectation, in: sut, when: { composerState in
            composerState.toRecipients.input == "" && composerState.toRecipients.controllerState == .idle
        })
        sut.endEditingRecipients()
        await fulfillment(of: [expectation], timeout: 1.0)
    }
}

// MARK: Helpers

private extension ComposerModelTests {
    typealias MatchContactTestCase=(input: String, expectedMatchCount: Int)

    @MainActor
    func testMatchContact(in sut: ComposerModel, test: MatchContactTestCase) async {
        let expectation = expectation(description: "\(#function): input '\(test.input)' matches \(test.expectedMatchCount)")
        fulfill(expectation, in: sut, when: { composerState in
            composerState.toRecipients.input == test.input && composerState.toRecipients.matchingContacts.count == test.expectedMatchCount
        })

        sut.matchContact(group: .to, text: test.input)
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func fulfill(_ expectation: XCTestExpectation, in sut: ComposerModel, when condition: @escaping (ComposerState) -> Bool) {
        sut.$state.sink { state in
            guard condition(state) else { return }
            expectation.fulfill()
        }
        .store(in: &cancellables)
    }
}

extension ComposerContactProvider {

    static func testInstance(datasourceContacts: [ComposerContact] = []) -> ComposerContactProvider {
        .init(protonContactsDatasource: ComposerTestContactsDatasource(dummyContacts: datasourceContacts))
    }
}

struct ComposerTestContactsDatasource: ComposerContactsDatasource {
    var dummyContacts: [ComposerContact] = []

    func allContacts() async -> [ComposerContact] {
        dummyContacts
    }
}


extension ComposerState {

    static func mockState(matchingContacts: [ComposerContact], controllerState: RecipientControllerStateType) -> ComposerState {
        .init(
            toRecipients: .init(group: .to, recipients: [], input: .empty, matchingContacts: matchingContacts, controllerState: controllerState),
            ccRecipients: .initialState(group: .cc),
            bccRecipients: .initialState(group: .bcc),
            editingRecipientsGroup: nil
        )
    }
}

extension ComposerContact {

    init(type: ComposerContactType) {
        self.init(type: type, avatarColor: .blue)
    }
}
