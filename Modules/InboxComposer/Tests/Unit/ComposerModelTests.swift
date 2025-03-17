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
import Contacts
@testable import InboxComposer
@testable import InboxTesting
import InboxContacts
import proton_app_uniffi
import struct SwiftUI.Color
import XCTest

final class ComposerModelTests: XCTestCase {
    private var testDraftSavedToastCoordinator: DraftSavedToastCoordinator!
    private var testContactProvider: ComposerContactProvider!
    private var testPhotosItemsHandler: PhotosPickerItemHandler!
    private var testCameraImageHandler: CameraImageHandler!
    private var testFilesItemsHandler: FilePickerItemHandler!
    let dummyName1 = "dummy name"
    let dummyAddress1 = "test1@example.com"
    let singleRecipient1 = ComposerRecipient.single(.init(displayName: "", address: "inbox1@pm.me", validState: .valid))
    let singleRecipient2 = ComposerRecipient.single(.init(displayName: "", address: "inbox2@pm.me", validState: .valid))
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        self.testDraftSavedToastCoordinator = .init(mailUSerSession: .init(noPointer: .init()), toastStoreState: .init(initialState: .initial))
        self.testContactProvider = ComposerContactProvider(
            protonContactsDatasource: ComposerTestContactsDatasource(dummyContacts: [
                .makeComposerContactSingle(name: "", email: "a@example.com"),
                .makeComposerContactSingle(name: "", email: "b@example.com"),
                .makeComposerContactSingle(name: "", email: "c@example.com"),
            ])
        )
        self.testPhotosItemsHandler = .init(toastStateStore: .init(initialState: .initial))
        self.testCameraImageHandler = .init(toastStateStore: .init(initialState: .initial))
        self.testFilesItemsHandler = .init(toastStateStore: .init(initialState: .initial))
        self.cancellables = []
    }

    override func tearDown() {
        super.tearDown()
        self.testContactProvider = nil
        self.testPhotosItemsHandler = nil
        self.testCameraImageHandler = nil
        self.testFilesItemsHandler = nil
        self.cancellables = nil
    }

    func testInit_whenNoStateIsPassed_itShouldReturnAnEmptyState() {
        let sut = ComposerModel(
            draft: .emptyMock,
            draftOrigin: .new,
            draftSavedToastCoordinator: testDraftSavedToastCoordinator,
            contactProvider: testContactProvider,
            onSendingEvent: {},
            permissionsHandler: CNContactStorePartialStub.self,
            contactStore: CNContactStorePartialStub(),
            photosItemsHandler: testPhotosItemsHandler,
            cameraImageHandler: testCameraImageHandler,
            fileItemsHandler: testFilesItemsHandler
        )
        XCTAssertEqual(sut.state.toRecipients, RecipientFieldState.initialState(group: .to))
        XCTAssertEqual(sut.state.ccRecipients, RecipientFieldState.initialState(group: .cc))
        XCTAssertEqual(sut.state.bccRecipients, RecipientFieldState.initialState(group: .bcc))
    }

    // MARK: onLoad

    func testInit_whenOriginIsRemote_itShouldNotNotifyTheUser() async {
        let sut = makeSut(draft: .emptyMock, draftOrigin: .server, contactProvider: testContactProvider)
        await sut.onLoad()
        XCTAssertNil(sut.toast)
    }

    func testInit_whenOriginIsCached_itShouldNotifyTheUser() async {
        let sut = makeSut(draft: .emptyMock, draftOrigin: .cache, contactProvider: testContactProvider)
        await sut.onLoad()
        XCTAssertEqual(sut.toast, .information(message: L10n.Composer.draftLoadedOffline.string))
    }

    // MARK: recipientToggleSelection

    @MainActor
    func testRecipientToggleSelection_whenGroupIsTo_itShouldUpdateSelectedStatus() {
        let mockDraft: MockDraft = .makeWithRecipients([singleRecipient1, singleRecipient2], group: .to)
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: testContactProvider)

        sut.recipientToggleSelection(group: .to, index: 0)
        XCTAssertTrue(sut.state.toRecipients.recipients[0].isSelected)

        sut.recipientToggleSelection(group: .to, index: 0)
        XCTAssertFalse(sut.state.toRecipients.recipients[0].isSelected)
    }

    // MARK: removeRecipientsThatAreSelected

    @MainActor
    func testRemoveRecipientsThatAreSelectedRecipients_itShouldRemoveSelectedItems() {
        let mockDraft: MockDraft = .makeWithRecipients([singleRecipient1, singleRecipient2], group: .to)
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: testContactProvider)
        sut.recipientToggleSelection(group: .to, index: 0)
        XCTAssertTrue(sut.state.toRecipients.recipients[0].isSelected)

        sut.removeRecipientsThatAreSelected(group: .to)
        XCTAssertEqual(sut.state.toRecipients.recipients, [RecipientUIModel(composerRecipient: singleRecipient2, isSelected: false)])
    }

    // MARK: selectLastRecipient

    @MainActor
    func testSelectLastRecipient_whenLastRecipientIsNotSelected_itSholdUpdateItsSelectedStatus() {
        let mockDraft: MockDraft = .makeWithRecipients([singleRecipient1, singleRecipient2], group: .to)
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: testContactProvider)

        sut.selectLastRecipient(group: .to)
        XCTAssertTrue(sut.state.toRecipients.recipients.last!.isSelected)
    }

    @MainActor
    func testSelectLastRecipient_whenLastRecipientIsSelected_itSholdNotUpdateItsSelectedStatus() {
        let mockDraft: MockDraft = .makeWithRecipients([singleRecipient1, singleRecipient2], group: .to)
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: testContactProvider)

        sut.selectLastRecipient(group: .to)
        XCTAssertTrue(sut.state.toRecipients.recipients.last!.isSelected)
    }

    // MARK: addRecipient

    @MainActor
    func testAddRecipient_itShouldAddTheRecipient() {
        let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: testContactProvider)
        sut.addRecipient(group: .to, address: dummyAddress1)

        XCTAssertEqual(sut.state.toRecipients.recipients.first?.displayName, dummyAddress1)
        XCTAssertTrue(sut.state.ccRecipients.recipients.isEmpty)
        XCTAssertTrue(sut.state.bccRecipients.recipients.isEmpty)
    }

    // MARK: addContact

    @MainActor
    func testAddContact_whenIsSingleContact_andHasNameAndEmail_itShouldUpdateTheRecipients() {
        let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: testContactProvider)
        let contact: ComposerContact = .makeComposerContactSingle(name: dummyName1, email: dummyAddress1)
        sut.addContact(group: .to, contact: contact)

        XCTAssertEqual(sut.state.toRecipients.recipients.first?.displayName, dummyName1)
        XCTAssertTrue(sut.state.ccRecipients.recipients.isEmpty)
        XCTAssertTrue(sut.state.bccRecipients.recipients.isEmpty)
    }

    // FIXME: When the SDK returns contact groups
//    @MainActor
//    func testAddContact_whenIsAGroup_itShouldUpdateTheRecipientss() {
//        let sut = ComposerModel(draft: .emptyMock, contactProvider: testContactProvider)
//        let contact = ComposerContact(type: .group(.init(name: dummyName1, totalMembers: 3)))
//        sut.addContact(group: .to, contact: contact)
//
//        XCTAssertEqual(sut.state.toRecipients.recipients.first?.displayName, dummyName1)
//        XCTAssertTrue(sut.state.ccRecipients.recipients.isEmpty)
//        XCTAssertTrue(sut.state.bccRecipients.recipients.isEmpty)
//    }

    // MARK: matchContacts

    @MainActor
    func testMatchContacts_whenThereIsMatch_itShouldUpdateStateWithMatchingContacts() async {
        let mockProvider = ComposerContactProvider.testInstance(datasourceContacts: [
            .makeComposerContactSingle(name: "Adrian", email: "a@example.com"),
            .makeComposerContactSingle(name: "Su", email: "susan.cohen@example.com"),
            .init(type: .group(.init(name: "Team", totalMembers: 4))),
        ])

        let tests: [MatchContactCountTestCase] = [("A", 3), ("susan", 1), ("team", 1)]
        for test in tests {
            let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: mockProvider)
            await sut.onLoad()
            await testMatchContact(in: sut, test: test)
        }
    }

    @MainActor
    func testMatchContacts_whenThereIsMatch_itShouldUpdateControllerStateWithContactPicker() async {
        let mockProvider = ComposerContactProvider.testInstance(datasourceContacts: [
            .makeComposerContactSingle(name: "Adrian", email: "a@example.com")
        ])
        let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: mockProvider)
        await sut.onLoad()
        XCTAssertEqual(sut.state.toRecipients.controllerState, .editing)

        let expectation = expectation(description: "\(#function)")
        fulfill(expectation, in: sut, when: { composerState in
            composerState.toRecipients.controllerState == .contactPicker
        })
        sut.matchContact(group: .to, text: "Adrian")
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    @MainActor
    func testMatchContacts_whenThereIsNoMatch_itShouldUpdateStateWithoutMatchingContacts() async {
        let mockProvider = ComposerContactProvider.testInstance(datasourceContacts: [
            .makeComposerContactSingle(name: "Adrian", email: "adrian@example.com")
        ])
        let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: mockProvider)
        await sut.onLoad()

        // Preparing test with a contact match
        let expectation1 = expectation(description: "\(#function)")
        expectation1.assertForOverFulfill = false
        fulfill(expectation1, in: sut, when: { composerState in
            composerState.toRecipients.input == "Adrian" 
            && composerState.toRecipients.matchingContacts.count == 1
        })
        sut.matchContact(group: .to, text: "Adrian")
        await fulfillment(of: [expectation1], timeout: 1.0)

        // Testing match count will change to 0
        await testMatchContact(in: sut, test: MatchContactCountTestCase(input: "Mark", expectedMatchCount: 0))
    }

    @MainActor
    func testMatchContacts_whenThereIsNoMatch_itShouldUpdateControllerStateWithContactEditing() async {
        let mockProvider = ComposerContactProvider.testInstance(datasourceContacts: [
            .makeComposerContactSingle(name: "Adrian", email: "adrian@example.com")
        ])
        let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: mockProvider)
        await sut.onLoad()

        // Preparing test with a contact match
        let expectation1 = expectation(description: "\(#function)")
        expectation1.assertForOverFulfill = false
        fulfill(expectation1, in: sut, when: { composerState in
            composerState.toRecipients.input == "Adrian" 
            && composerState.toRecipients.controllerState == .contactPicker
        })
        sut.matchContact(group: .to, text: "Adrian")
        await fulfillment(of: [expectation1], timeout: 1.0)

        // Testing `controllerState` will change to `editing`
        let expectation2 = expectation(description: "\(#function)")
        fulfill(expectation2, in: sut, when: { composerState in
            composerState.toRecipients.input == "Mark" && composerState.toRecipients.controllerState == .editing
        })
        sut.matchContact(group: .to, text: "Mark")
        await fulfillment(of: [expectation2], timeout: 1.0)
    }

    // MARK: endEditingRecipients

    @MainActor
    func testEndEditingRecipients_itShouldCleanInputAndSetControllerStateToIdle() async {
        let mockProvider = ComposerContactProvider.testInstance(datasourceContacts: [
            .makeComposerContactSingle(name: "Adrian", email: "adrian@example.com")
        ])
        let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: mockProvider)
        await sut.onLoad()

        // Preparing test with a contact match
        let expectation1 = expectation(description: "\(#function)")
        expectation1.assertForOverFulfill = false
        fulfill(expectation1, in: sut, when: { composerState in
            composerState.toRecipients.input == "Adrian" && composerState.toRecipients.controllerState == .contactPicker
        })
        sut.matchContact(group: .to, text: "Adrian")
        await fulfillment(of: [expectation1], timeout: 1.0)

        // Testing the `input` and `controllerState` values
        let expectation2 = expectation(description: "\(#function)")
        fulfill(expectation2, in: sut, when: { composerState in
            composerState.toRecipients.input == "" && composerState.toRecipients.controllerState == .idle
        })
        sut.endEditingRecipients()
        await fulfillment(of: [expectation2], timeout: 1.0)
    }

    // MARK: updateSubject

    @MainActor
    func testUpdateSubject_itShouldChangeTheSubjectState() async {
        let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: .mockInstance)
        let newSubject = "new subject"
        sut.updateSubject(value: newSubject)
        XCTAssertEqual(sut.state.subject, newSubject)
    }

    // MARK: callback

    // FIXME: - Test is failing failing
//    @MainActor
//    func testComponerRecpientListCallbackUpdate_whenValidStateHasChanged_itShouldUpdateTheRecipientState() async {
//        let makeSingleRecipient: (ComposerRecipientValidState) -> ComposerRecipientSingle = { validState in
//            ComposerRecipientSingle(displayName: "a", address: "a@example.com", validState: validState)
//        }
//        let singleRecipientValid = ComposerRecipient.single(makeSingleRecipient(.valid))
//        let singleRecipientInvalid = ComposerRecipient.single(makeSingleRecipient(.invalid(.doesNotExist)))
//
//        let mockDraft: MockDraft = .makeWithRecipients([singleRecipientValid], group: .to)
//        let sut = ComposerModel(draft: mockDraft, contactProvider: testContactProvider)
//        XCTAssertEqual(sut.state.toRecipients.recipients.first!.isValid, true)
//
//        // We simulate a `validState` update
//        mockDraft.mockToRecipientList.addedRecipients = [singleRecipientInvalid]
//        mockDraft.mockToRecipientList.callback?.onUpdate()
//
//        XCTAssertEqual(sut.state.toRecipients.recipients.first!.isValid, false)
//    }

    @MainActor
    func testComponerRecpientListCallbackUpdate_whenComposerRecipientIsSelected_itShouldKeepTheSelection() async {
        let mockDraft: MockDraft = .makeWithRecipients([singleRecipient1], group: .to)
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: testContactProvider)
        sut.recipientToggleSelection(group: .to, index: 0)
        XCTAssertEqual(sut.state.toRecipients.recipients.first!.isSelected, true)

        mockDraft.mockToRecipientList.callback?.onUpdate()

        XCTAssertEqual(sut.state.toRecipients.recipients.first!.isSelected, true)
    }
}

// MARK: Helpers

private extension ComposerModelTests {
    typealias MatchContactCountTestCase=(input: String, expectedMatchCount: Int)

    private func makeSut(draft: any AppDraftProtocol, draftOrigin: DraftOrigin, contactProvider: ComposerContactProvider) -> ComposerModel {
        ComposerModel(
            draft: draft,
            draftOrigin: draftOrigin,
            draftSavedToastCoordinator: testDraftSavedToastCoordinator,
            contactProvider: contactProvider,
            onSendingEvent: {},
            permissionsHandler: CNContactStorePartialStub.self,
            contactStore: CNContactStorePartialStub(),
            photosItemsHandler: testPhotosItemsHandler,
            cameraImageHandler: testCameraImageHandler,
            fileItemsHandler: testFilesItemsHandler
        )
    }

    @MainActor
    func testMatchContact(in sut: ComposerModel, test: MatchContactCountTestCase) async {
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

    func allContacts() async -> ComposerContactsResult {
        .init(
            contacts: dummyContacts,
            filter: { query in
                dummyContacts.filter { contact in
                    contact.toMatch.contains { elementToMatch in elementToMatch.contains(query) }
                }
            }
        )
    }
}

private extension ComposerContact {
    
    var toMatch: [String] {
        switch self.type {
        case .group(let group):
            [group.name.toContactMatchFormat()]
        case .single(let singleItem):
            [singleItem.name.toContactMatchFormat(), singleItem.email.toContactMatchFormat()]
        }
    }
    
}

extension ComposerState {

    static func mockState(matchingContacts: [ComposerContact], controllerState: RecipientControllerStateType) -> ComposerState {
        .init(
            toRecipients: .init(group: .to, recipients: [], input: .empty, matchingContacts: matchingContacts, controllerState: controllerState),
            ccRecipients: .initialState(group: .cc),
            bccRecipients: .initialState(group: .bcc),
            senderEmail: .empty,
            subject: .empty,
            attachments: [],
            initialBody: .empty,
            editingRecipientsGroup: nil
        )
    }
}

private extension ComposerContact {

    static func makeComposerContactSingle(name: String, email: String) -> ComposerContact {
        let type = ComposerContactType.single(.init(initials: "", name: name, email: email))
        return ComposerContact(id: "__NOT_USED__", type: type, avatarColor: .green)
    }

    init(type: ComposerContactType) {
        self.init(id: "__NOT_USED__", type: type, avatarColor: .blue)
    }
}
