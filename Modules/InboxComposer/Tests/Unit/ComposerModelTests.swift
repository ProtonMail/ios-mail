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
import InboxCoreUI
import PhotosUI
import ProtonUIFoundations
import SwiftUI
import XCTest
import proton_app_uniffi

import typealias InboxCore.ID

@testable import InboxComposer
@testable import InboxTesting

@MainActor
final class ComposerModelTests: BaseTestCase {
    private var mockDraft: MockDraft!
    private var testContactProvider: ComposerContactProvider!
    private var testPhotosItemsHandler: PhotosPickerItemHandler!
    private var photosPickerTestsHelper: PhotosPickerItemHandlerTestsHelper!
    private var testCameraImageHandler: CameraImageHandler!
    private var testFilesItemsHandler: FilePickerItemHandler!
    private var filePickerTestsHelper: FilePickerItemHandlerTestsHelper!
    private var dismissReasonObserver: [ComposerDismissReason]!
    let dummyName1 = "dummy name"
    let dummyAddress1 = "test1@example.com"
    let dummyValidAddress = "valid_address_format@example.com"
    let dummyInvalidAddress = "invalid_address_format@example"
    let singleRecipient1 = ComposerRecipient.single(
        .init(
            displayName: "",
            address: "inbox1@pm.me",
            validState: .valid,
            privacyLock: nil
        ))
    let singleRecipient2 = ComposerRecipient.single(
        .init(
            displayName: "",
            address: "inbox2@pm.me",
            validState: .valid,
            privacyLock: nil
        ))
    let dummyContent = ComposerContent(head: "<style>dummy style</style>", body: "<body>dummy body</body>")
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        self.testContactProvider = ComposerContactProvider(
            protonContactsDatasource: ComposerTestContactsDatasource(dummyContacts: [
                .makeComposerContactSingle(name: "", email: "a@example.com"),
                .makeComposerContactSingle(name: "", email: "b@example.com"),
                .makeComposerContactSingle(name: "", email: "c@example.com"),
            ])
        )
        self.testPhotosItemsHandler = .init()
        self.photosPickerTestsHelper = try .init()
        self.testCameraImageHandler = .init()
        self.testFilesItemsHandler = .init()
        self.filePickerTestsHelper = try .init()
        self.dismissReasonObserver = []
        self.mockDraft = .defaultMockDraft
        self.mockDraft.mockAttachmentList.attachmentUploadDirectoryURL = photosPickerTestsHelper.destinationFolder
        self.cancellables = []
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try photosPickerTestsHelper.tearDown()
        try filePickerTestsHelper.tearDown()
        testContactProvider = nil
        testPhotosItemsHandler = nil
        testCameraImageHandler = nil
        testFilesItemsHandler = nil
        dismissReasonObserver = nil
        cancellables = nil
        try super.tearDownWithError()
    }

    // MARK: init

    func testInit_whenNoStateIsPassed_itShouldReturnAnEmptyState() {
        let sut = ComposerModel(
            draft: .emptyMock,
            draftOrigin: .new,
            contactProvider: testContactProvider,
            onDismiss: { _ in },
            contactStore: CNContactStorePartialStub(),
            photosItemsHandler: testPhotosItemsHandler,
            cameraImageHandler: testCameraImageHandler,
            fileItemsHandler: testFilesItemsHandler,
            isAddingAttachmentsEnabled: true
        )
        XCTAssertEqual(sut.state.toRecipients, RecipientFieldState.initialState(group: .to))
        XCTAssertEqual(sut.state.ccRecipients, RecipientFieldState.initialState(group: .cc))
        XCTAssertEqual(sut.state.bccRecipients, RecipientFieldState.initialState(group: .bcc))
    }

    // MARK: onLoad

    func testOnLoad_whenOriginIsRemote_itShouldNotNotifyTheUser() async {
        let sut = makeSut(draft: .emptyMock, draftOrigin: .server, contactProvider: testContactProvider)
        await sut.onLoad()
        XCTAssertNil(sut.toast)
    }

    func testOnLoad_whenOriginIsCached_itShouldNotifyTheUser() async {
        let sut = makeSut(draft: .emptyMock, draftOrigin: .cache, contactProvider: testContactProvider)
        await sut.onLoad()
        XCTAssertEqual(sut.toast, .information(message: L10n.Composer.draftLoadedOffline.string))
    }

    func testOnLoad_whenNoToRecipient_itShouldFocusOnToField() async {
        let mockDraft: MockDraft = .makeWithRecipients([singleRecipient1], group: .cc)
        let sut = makeSut(draft: mockDraft, draftOrigin: .cache, contactProvider: testContactProvider)
        await sut.onLoad()
        XCTAssertEqual(sut.state.toRecipients.controllerState, .editing)
        XCTAssertFalse(sut.state.isInitialFocusInBody)
    }

    func testOnLoad_whenAtLeastOneToRecipient_itShouldFocusOnTheBody() async {
        let mockDraft: MockDraft = .makeWithRecipients([singleRecipient1], group: .to)
        let sut = makeSut(draft: mockDraft, draftOrigin: .cache, contactProvider: testContactProvider)
        await sut.onLoad()
        XCTAssertTrue(sut.state.isInitialFocusInBody)
        XCTAssertEqual(sut.state.toRecipients.controllerState, .collapsed)
    }

    func testOnLoad_whenAttachmentWithoutErrorState_itDoesNotPresentsAlert() async throws {
        let mockDraft: MockDraft = .makeWithAttachments([.makeMockDraftAttachment(state: .uploaded)])
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: testContactProvider)

        await sut.onLoad()

        XCTAssertFalse(sut.attachmentAlertState.isAlertPresented)
    }

    func testOnLoad_itCallsSenderAddressValidator() async throws {
        var validateCalled = false
        let testValidatorActions = SenderAddressValidatorActions(validate: { draft, _ in validateCalled = true })
        let sut = makeSut(
            draft: mockDraft,
            draftOrigin: .new,
            contactProvider: .mockInstance,
            senderAddressValidatorActions: testValidatorActions
        )

        await sut.onLoad()

        XCTAssertTrue(validateCalled)
    }

    func testOnLoad_whenAttachmentInErrorState_itPresentsAlert() async throws {
        let draftError = DraftAttachmentError.upload(.reason(.attachmentTooLarge))
        let mockDraft: MockDraft = .makeWithAttachments([.makeMockDraftAttachment(state: .error(draftError))])
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: testContactProvider)

        await sut.onLoad()
        await Task.yield()

        XCTAssertTrue(sut.attachmentAlertState.isAlertPresented)
    }

    func testOnLoad_whenThereAreInlineAttachments_itShouldNotMapThemToUIModels() async throws {
        let dummy1 = DraftAttachment.makeMockDraftAttachment(state: .uploaded, disposition: .inline)
        let dummy2 = DraftAttachment.makeMockDraftAttachment(state: .uploaded, disposition: .attachment)
        mockDraft.mockAttachmentList.mockAttachments = [dummy1, dummy2]
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)

        await sut.onLoad()

        XCTAssertEqual(sut.state.attachments, [dummy2.toDraftAttachmentUIModel()])
    }

    // MARK: startEditingRecipients

    func testStartEditingRecipients_itShouldSetEditingForTargetGroupAndExpandedForOthers() {
        mockDraft.mockToRecipientList = .init(addedRecipients: [singleRecipient1])
        mockDraft.mockCcRecipientList = .init(addedRecipients: [singleRecipient2])
        let sut = makeSut(draft: mockDraft, draftOrigin: .cache, contactProvider: testContactProvider)

        sut.startEditingRecipients(for: .to)
        XCTAssertEqual(sut.state.toRecipients.controllerState, .editing)
        XCTAssertEqual(sut.state.ccRecipients.controllerState, .expanded)
        XCTAssertEqual(sut.state.bccRecipients.controllerState, .expanded)

        sut.startEditingRecipients(for: .bcc)
        XCTAssertEqual(sut.state.toRecipients.controllerState, .expanded)
        XCTAssertEqual(sut.state.ccRecipients.controllerState, .expanded)
        XCTAssertEqual(sut.state.bccRecipients.controllerState, .editing)
    }

    func testStartEditingRecipients_whenHangingInputInEditingFieldIsInvalidFormat_itShouldShowAlert() async {
        let sut = makeSut(draft: .emptyMock, draftOrigin: .cache, contactProvider: testContactProvider)

        sut.startEditingRecipients(for: .to)
        await prepareInput(sut: sut, input: dummyInvalidAddress, for: .to)

        sut.startEditingRecipients(for: .bcc)

        XCTAssertNotNil(sut.state.alert)
    }

    func testStartEditingRecipients_whenNoHangingInputInEditingField_itShouldNotShowAlert() async {
        let sut = makeSut(draft: .emptyMock, draftOrigin: .cache, contactProvider: testContactProvider)

        sut.startEditingRecipients(for: .to)
        await prepareInput(sut: sut, input: dummyValidAddress, for: .to)

        sut.startEditingRecipients(for: .bcc)

        XCTAssertNil(sut.state.alert)
    }

    // MARK: recipientToggleSelection

    func testRecipientToggleSelection_whenGroupIsTo_itShouldUpdateSelectedStatus() {
        let mockDraft: MockDraft = .makeWithRecipients([singleRecipient1, singleRecipient2], group: .to)
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: testContactProvider)

        sut.recipientToggleSelection(group: .to, index: 0)
        XCTAssertTrue(sut.state.toRecipients.recipients[0].isSelected)

        sut.recipientToggleSelection(group: .to, index: 0)
        XCTAssertFalse(sut.state.toRecipients.recipients[0].isSelected)
    }

    // MARK: removeRecipientsThatAreSelected

    func testRemoveRecipientsThatAreSelectedRecipients_itShouldRemoveSelectedItems() {
        let mockDraft: MockDraft = .makeWithRecipients([singleRecipient1, singleRecipient2], group: .to)
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: testContactProvider)
        sut.recipientToggleSelection(group: .to, index: 0)
        XCTAssertTrue(sut.state.toRecipients.recipients[0].isSelected)

        sut.removeRecipientsThatAreSelected(group: .to)
        XCTAssertEqual(sut.state.toRecipients.recipients, [RecipientUIModel(composerRecipient: singleRecipient2, isSelected: false)])
    }

    // MARK: selectLastRecipient

    func testSelectLastRecipient_whenLastRecipientIsNotSelected_itSholdUpdateItsSelectedStatus() {
        let mockDraft: MockDraft = .makeWithRecipients([singleRecipient1, singleRecipient2], group: .to)
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: testContactProvider)

        sut.selectLastRecipient(group: .to)
        XCTAssertTrue(sut.state.toRecipients.recipients.last!.isSelected)
    }

    func testSelectLastRecipient_whenLastRecipientIsSelected_itSholdNotUpdateItsSelectedStatus() {
        let mockDraft: MockDraft = .makeWithRecipients([singleRecipient1, singleRecipient2], group: .to)
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: testContactProvider)

        sut.selectLastRecipient(group: .to)
        XCTAssertTrue(sut.state.toRecipients.recipients.last!.isSelected)
    }

    // MARK: addRecipientFromInput

    func testaddRecipientFromInput_whenInputIsValid_itShouldAddTheRecipient() async {
        let valid = dummyAddress1
        let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: testContactProvider)
        sut.startEditingRecipients(for: .to)
        await prepareInput(sut: sut, input: valid, for: .to)

        sut.addRecipientFromInput()

        XCTAssertEqual(sut.state.toRecipients.recipients.first?.displayName, dummyAddress1)
        XCTAssertTrue(sut.state.ccRecipients.recipients.isEmpty)
        XCTAssertTrue(sut.state.bccRecipients.recipients.isEmpty)
    }

    func testaddRecipientFromInput_whenInputIsValid_andContainsDisplayName_itShouldAddTheRecipient() async {
        let valid = "john <john@example.com>"
        let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: testContactProvider)
        sut.startEditingRecipients(for: .to)
        await prepareInput(sut: sut, input: valid, for: .to)

        sut.addRecipientFromInput()

        XCTAssertEqual(sut.state.toRecipients.recipients.first?.displayName, "john")
        XCTAssertTrue(sut.state.ccRecipients.recipients.isEmpty)
        XCTAssertTrue(sut.state.bccRecipients.recipients.isEmpty)
    }

    func testaddRecipientFromInput_whenInputIsInvalid_itShouldShowAlert() async {
        let invalid = "invalid_address"
        let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: testContactProvider)
        sut.startEditingRecipients(for: .to)
        await prepareInput(sut: sut, input: invalid, for: .to)

        sut.addRecipientFromInput()

        XCTAssertNotNil(sut.state.alert)
        XCTAssertEqual(sut.state.toRecipients.input, invalid)
        XCTAssertTrue(sut.state.toRecipients.recipients.isEmpty)
        XCTAssertTrue(sut.state.ccRecipients.recipients.isEmpty)
        XCTAssertTrue(sut.state.bccRecipients.recipients.isEmpty)
    }

    // MARK: addContact

    func testAddContact_whenIsSingleContact_andHasNameAndEmail_itShouldUpdateTheRecipients() {
        let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: testContactProvider)
        let contact: ComposerContact = .makeComposerContactSingle(name: dummyName1, email: dummyAddress1)
        sut.addContact(group: .to, contact: contact)

        XCTAssertEqual(sut.state.toRecipients.recipients.first?.displayName, dummyName1)
        XCTAssertTrue(sut.state.ccRecipients.recipients.isEmpty)
        XCTAssertTrue(sut.state.bccRecipients.recipients.isEmpty)
    }

    func testAddContact_whenIsAGroup_itShouldUpdateTheRecipientss() {
        let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: testContactProvider)
        let contact = ComposerContact(type: .group(.init(name: dummyName1, entries: [], totalMembers: 3)))
        sut.addContact(group: .to, contact: contact)

        XCTAssertEqual(sut.state.toRecipients.recipients.first?.displayName, dummyName1)
        XCTAssertTrue(sut.state.ccRecipients.recipients.isEmpty)
        XCTAssertTrue(sut.state.bccRecipients.recipients.isEmpty)
    }

    // MARK: matchContacts

    func testMatchContacts_whenThereIsMatch_itShouldUpdateStateWithMatchingContacts() async {
        let mockProvider = ComposerContactProvider.testInstance(datasourceContacts: [
            .makeComposerContactSingle(name: "Adrian", email: "a@example.com"),
            .makeComposerContactSingle(name: "Su", email: "susan.cohen@example.com"),
            .init(type: .group(.init(name: "Team", entries: [], totalMembers: 4))),
        ])

        let tests: [MatchContactCountTestCase] = [("A", 3), ("susan", 1), ("team", 1)]
        for test in tests {
            let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: mockProvider)
            await sut.onLoad()
            await testMatchContact(in: sut, test: test)
        }
    }

    func testMatchContacts_whenThereIsMatch_itShouldUpdateControllerStateWithContactPicker() async {
        let mockProvider = ComposerContactProvider.testInstance(datasourceContacts: [
            .makeComposerContactSingle(name: "Adrian", email: "a@example.com")
        ])
        let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: mockProvider)
        await sut.onLoad()
        XCTAssertEqual(sut.state.toRecipients.controllerState, .editing)

        let expectation = expectation(description: "\(#function)")
        fulfill(
            expectation, in: sut,
            when: { composerState in
                composerState.toRecipients.controllerState == .contactPicker
            })
        sut.matchContact(group: .to, text: "Adrian")
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testMatchContacts_whenThereIsNoMatch_itShouldUpdateStateWithoutMatchingContacts() async {
        let mockProvider = ComposerContactProvider.testInstance(datasourceContacts: [
            .makeComposerContactSingle(name: "Adrian", email: "adrian@example.com")
        ])
        let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: mockProvider)
        await sut.onLoad()

        // Preparing test with a contact match
        let expectation1 = expectation(description: "\(#function)")
        expectation1.assertForOverFulfill = false
        fulfill(
            expectation1, in: sut,
            when: { composerState in
                composerState.toRecipients.input == "Adrian"
                    && composerState.toRecipients.matchingContacts.count == 1
            })
        sut.matchContact(group: .to, text: "Adrian")
        await fulfillment(of: [expectation1], timeout: 1.0)

        // Testing match count will change to 0
        await testMatchContact(in: sut, test: MatchContactCountTestCase(input: "Mark", expectedMatchCount: 0))
    }

    func testMatchContacts_whenThereIsNoMatch_itShouldUpdateControllerStateWithContactEditing() async {
        let mockProvider = ComposerContactProvider.testInstance(datasourceContacts: [
            .makeComposerContactSingle(name: "Adrian", email: "adrian@example.com")
        ])
        let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: mockProvider)
        await sut.onLoad()

        // Preparing test with a contact match
        let expectation1 = expectation(description: "\(#function)")
        expectation1.assertForOverFulfill = false
        fulfill(
            expectation1, in: sut,
            when: { composerState in
                composerState.toRecipients.input == "Adrian"
                    && composerState.toRecipients.controllerState == .contactPicker
            })
        sut.matchContact(group: .to, text: "Adrian")
        await fulfillment(of: [expectation1], timeout: 1.0)

        // Testing `controllerState` will change to `editing`
        let expectation2 = expectation(description: "\(#function)")
        fulfill(
            expectation2, in: sut,
            when: { composerState in
                composerState.toRecipients.input == "Mark" && composerState.toRecipients.controllerState == .editing
            })
        sut.matchContact(group: .to, text: "Mark")
        await fulfillment(of: [expectation2], timeout: 1.0)
    }

    // MARK: endEditingRecipients

    func testEndEditingRecipients_whenThereIsHangingRecipientInput_itShouldAddTheInputAsRecipient() async {
        let hangingInput = dummyValidAddress
        let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: .mockInstance)
        sut.startEditingRecipients(for: .to)

        await prepareInput(sut: sut, input: hangingInput, for: .to)

        sut.endEditingRecipients()
        XCTAssertEqual(sut.state.toRecipients.recipients.count, 1)
        XCTAssertEqual(sut.state.toRecipients.recipients.first?.displayName, hangingInput)
    }

    func testEndEditingRecipients_itShouldCleanInputAndSetControllerStateToCollapsed() async {
        let mockProvider = ComposerContactProvider.testInstance(datasourceContacts: [
            .makeComposerContactSingle(name: "Adrian", email: "adrian@example.com")
        ])
        let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: mockProvider)
        await sut.onLoad()

        // Preparing test with a contact match
        let expectation1 = expectation(description: "\(#function)")
        expectation1.assertForOverFulfill = false
        fulfill(
            expectation1, in: sut,
            when: { composerState in
                composerState.toRecipients.input == "Adrian" && composerState.toRecipients.controllerState == .contactPicker
            })
        sut.matchContact(group: .to, text: "Adrian")
        await fulfillment(of: [expectation1], timeout: 1.0)

        // Testing the `input` and `controllerState` values
        let expectation2 = expectation(description: "\(#function)")
        fulfill(
            expectation2, in: sut,
            when: { composerState in
                composerState.toRecipients.input == "" && composerState.toRecipients.controllerState == .collapsed
            })
        sut.endEditingRecipients()
        await fulfillment(of: [expectation2], timeout: 1.0)
    }

    // MARK: updateSubject

    func testUpdateSubject_itShouldChangeTheSubjectState() async {
        let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: .mockInstance)
        let newSubject = "new subject"
        sut.updateSubject(value: newSubject)
        XCTAssertEqual(sut.state.subject, newSubject)
    }

    // MARK: listSenderAddresses

    func testListSenderAddresses_whenSuccess_itReturnsTheDraftSenderAddressesAvailable() async throws {
        mockDraft.mockSenderList = .ok(.init(available: ["1@example.com, 2@example.com"], active: "2@example.com"))
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)

        let result = try await sut.listSenderAddresses()
        XCTAssertEqual(result.available, ["1@example.com, 2@example.com"])
        XCTAssertEqual(result.active, "2@example.com")
    }

    // MARK: changeSenderAddress

    func testChangeSenderAddress_whenSuccess_itSetsBodyActionToReloadBody() async throws {
        let newAddress = "my_new_address@example.com"
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)

        try await sut.changeSenderAddress(email: newAddress)
        let content = mockDraft.composerContent()
        XCTAssertEqual(sut.bodyAction, ComposerBodyAction.reloadBody(content: content, clearImageCacheFirst: false))
    }

    func testChangeSenderAddress_whenFailure_itDoesNotSetBodyActionToReloadBody() async {
        mockDraft.mockDraftChangeSenderAddressResult = .error(.reason(.addressDisabled))
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)

        do {
            try await sut.changeSenderAddress(email: "my_new_address@example.com")
            XCTFail()
        } catch {}
        XCTAssertEqual(sut.bodyAction, nil)
    }

    func testChangeSenderAddress_whenSuccess_newStateIsCreatedFromExistingDraft() async throws {
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)

        let newHTML = ComposerContent(head: "new head", body: "new body")
        let newAttachments: [DraftAttachment] = [
            .makeMockDraftAttachment(state: .uploaded),
            .makeMockDraftAttachment(state: .uploading),
        ]
        let newSender = "new_sender@example.com"

        mockDraft.mockContent = newHTML
        mockDraft.mockAttachmentList.mockAttachments = newAttachments
        try await sut.changeSenderAddress(email: newSender)

        XCTAssertEqual(sut.state.senderEmail, newSender)
        XCTAssertEqual(sut.state.subject, mockDraft.subject())
        XCTAssertEqual(sut.state.initialContent, newHTML)
        XCTAssertEqual(sut.state.toRecipients.recipients, [RecipientUIModel(composerRecipient: singleRecipient1)])
        XCTAssertEqual(sut.state.attachments, newAttachments.map { $0.toDraftAttachmentUIModel() })
    }

    // MARK: recipients callback

    func testComposerRecipientListCallbackUpdate_whenValidStateHasChanged_itShouldUpdateTheRecipientState() async {
        let makeSingleRecipient: (ComposerRecipientValidState) -> ComposerRecipientSingle = { validState in
            ComposerRecipientSingle(
                displayName: "my friend",
                address: "friend@example.com",
                validState: validState,
                privacyLock: nil
            )
        }
        let singleRecipientValid = ComposerRecipient.single(makeSingleRecipient(.valid))
        let singleRecipientInvalid = ComposerRecipient.single(makeSingleRecipient(.invalid(.unknown)))

        let mockDraft: MockDraft = .makeWithRecipients([singleRecipientValid], group: .to)
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: testContactProvider)
        XCTAssertEqual(sut.state.toRecipients.recipients.first!.isValid, true)

        // We simulate a `validState` update
        mockDraft.mockToRecipientList.addedRecipients = [singleRecipientInvalid]
        mockDraft.mockToRecipientList.callback?.onUpdate()

        XCTAssertEqual(sut.state.toRecipients.recipients.first!.isValid, false)
    }

    func testComposerRecipientListCallbackUpdate_whenValidStateIsAddressDoesNotExist_itShouldShowErrorToast() async {
        let makeSingleRecipient: (ComposerRecipientValidState) -> ComposerRecipientSingle = { validState in
            ComposerRecipientSingle(
                displayName: "my friend",
                address: "friend@example.com",
                validState: validState,
                privacyLock: nil
            )
        }
        let singleRecipientValid = ComposerRecipient.single(makeSingleRecipient(.valid))
        let singleRecipientInvalid = ComposerRecipient.single(makeSingleRecipient(.invalid(.doesNotExist)))

        let mockDraft: MockDraft = .makeWithRecipients([singleRecipientValid], group: .to)
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: testContactProvider)

        // We simulate a `validState` update
        mockDraft.mockToRecipientList.addedRecipients = [singleRecipientInvalid]
        mockDraft.mockToRecipientList.callback?.onUpdate()

        XCTAssertEqual(sut.toast, .error(message: L10n.ComposerError.addressDoesNotExist.string))
    }

    func testComposerRecipientListCallbackUpdate_whenComposerRecipientIsSelected_itShouldKeepTheSelection() async {
        let mockDraft: MockDraft = .makeWithRecipients([singleRecipient1], group: .to)
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: testContactProvider)
        sut.recipientToggleSelection(group: .to, index: 0)
        XCTAssertEqual(sut.state.toRecipients.recipients.first!.isSelected, true)

        mockDraft.mockToRecipientList.callback?.onUpdate()

        XCTAssertEqual(sut.state.toRecipients.recipients.first!.isSelected, true)
    }

    // MARK: addAttachments

    func testAddAttachments_whenSelectingFromPhotos_andIsNotAnImage_itShouldAddAttachmentToDraft() async throws {
        let photo1 = try photosPickerTestsHelper.makeMockPhotosPickerItem(fileName: "video.mp4", createFile: true)
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)

        await sut.addAttachments(selectedPhotosItems: [photo1])

        let destFile1 = photosPickerTestsHelper.destinationFolder.appendingPathComponent("video.mp4")
        XCTAssertEqual(Set(mockDraft.attachmentPathsFor(dispositon: .attachment)), Set([destFile1.path]))
    }

    func testAddAttachments_whenSelectingFromPhotos_andIsAnImage_itShouldAddInlineAttachmentToDraft_andSetBodyAction() async throws {
        let photo1 = try photosPickerTestsHelper.makeMockPhotosPickerItem(fileName: "photo1.jpg", createFile: true)
        mockDraft.mockAttachmentList.mockAttachmentListAddInlineResult = [("photo1.jpg", .ok("13579"))]
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)

        await sut.addAttachments(selectedPhotosItems: [photo1])

        let destFile1 = photosPickerTestsHelper.destinationFolder.appendingPathComponent("photo1.jpg")
        XCTAssertEqual(Set(mockDraft.attachmentPathsFor(dispositon: .inline)), Set([destFile1.path]))
        XCTAssertEqual(sut.bodyAction, ComposerBodyAction.insertInlineImages(cids: ["13579"]))
    }

    func testAddAttachments_whenSelectingFromPhotosReturnsError_itShouldShowAlertError() async throws {
        let draftAddResultError = DraftAttachmentUploadError.reason(.attachmentTooLarge)
        mockDraft.mockAttachmentList.mockAttachmentListAddInlineResult = [("photo1.jpg", .error(draftAddResultError))]
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)

        let photo1 = try photosPickerTestsHelper.makeMockPhotosPickerItem(fileName: "photo1.jpg", createFile: true)
        await sut.addAttachments(selectedPhotosItems: [photo1])

        await Task.yield()

        XCTAssertTrue(sut.attachmentAlertState.isAlertPresented)
    }

    func testAddAttachments_whenSelectingFromFiles_itShouldAddAttachmentToDraft() async throws {
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)
        let file1 = try filePickerTestsHelper.prepareItem(fileName: "file1.txt", createFile: true)

        await sut.addAttachments(filePickerResult: .success([file1]))

        let destFile1 = photosPickerTestsHelper.destinationFolder.appendingPathComponent("file1.txt")
        XCTAssertEqual(Set(mockDraft.attachmentPathsFor(dispositon: .attachment)), Set([destFile1.path]))
    }

    func testAddAttachments_whenSelectingFromFilesReturnedError_itShouldShowAlertError() async throws {
        let draftAddResultError = DraftAttachmentUploadError.reason(.tooManyAttachments)
        mockDraft.mockAttachmentList.mockAttachmentListAddResult = [("file1.txt", .error(draftAddResultError))]
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)

        let file1 = try filePickerTestsHelper.prepareItem(fileName: "file1.txt", createFile: true)
        await sut.addAttachments(filePickerResult: .success([file1]))

        XCTAssertTrue(sut.attachmentAlertState.isAlertPresented)
    }

    func testAddAttachments_whenAddingUIImage_inComposerModeHtml_itShouldAddAttachmentAsInlineImage() async throws {
        let draft = mockDraft!
        draft.mockMimeType = .textHtml
        let sut = makeSut(draft: draft, draftOrigin: .new, contactProvider: .mockInstance)

        await sut.addAttachments(image: .init())

        XCTAssertEqual(Set(mockDraft.attachmentPathsFor(dispositon: .inline)).count, 1)
        XCTAssertEqual(Set(mockDraft.attachmentPathsFor(dispositon: .attachment)).count, 0)
    }

    func testAddAttachments_whenAddingUIImage_inComposerModePlainText_itShouldAddAttachmentAsRegular() async throws {
        let draft = mockDraft!
        draft.mockMimeType = .textPlain
        let sut = makeSut(draft: draft, draftOrigin: .new, contactProvider: .mockInstance)

        await sut.addAttachments(image: .init())

        XCTAssertEqual(Set(mockDraft.attachmentPathsFor(dispositon: .inline)).count, 0)
        XCTAssertEqual(Set(mockDraft.attachmentPathsFor(dispositon: .attachment)).count, 1)
    }

    // MARK: transformInlineAttachmentToRegular(cid:)

    func testTransformInlineAttachmentToRegular_whenSuccess_itShouldSetBodyAction() async throws {
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)

        await sut.transformInlineAttachmentToRegular(cid: "123456")

        XCTAssertEqual(mockDraft.mockAttachmentList.capturedSwapInlineCalls.first, "123456")
        XCTAssertEqual(sut.bodyAction, ComposerBodyAction.removeInlineImage(cid: "123456"))
    }

    func testTransformInlineAttachmentToRegular_whenSuccess_itShouldNotCallRemoveAttachment() async throws {
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)

        await sut.transformInlineAttachmentToRegular(cid: "123456")

        XCTAssertEqual(mockDraft.mockAttachmentList.capturedRemoveIdCalls.count, 0)
    }

    func testTransformInlineAttachmentToRegular_whenSwapFails_itShouldNotSetBodyAction() async throws {
        let dispositionSwapError = DraftAttachmentDispositionSwapError.reason(.invalidState)
        mockDraft.mockAttachmentList.mockAttachmentSwapWithCidResult = .error(dispositionSwapError)
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)

        await sut.transformInlineAttachmentToRegular(cid: "123456")

        XCTAssertEqual(mockDraft.mockAttachmentList.capturedSwapInlineCalls.first, "123456")
        XCTAssertNil(sut.bodyAction)
    }

    func testTransformInlineAttachmentToRegular_whenSwapFails_itShouldShowAToast() async throws {
        let dispositionSwapError = DraftAttachmentDispositionSwapError.reason(.invalidState)
        mockDraft.mockAttachmentList.mockAttachmentSwapWithCidResult = .error(dispositionSwapError)
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)

        await sut.transformInlineAttachmentToRegular(cid: "123456")

        XCTAssertEqual(sut.toast, Toast.error(message: dispositionSwapError.localizedDescription))
    }

    // MARK: removeAttachment(attachment:)

    func testRemoveAttachment_whenAttachmentIsRegular_itShouldNotReloadBody() async throws {
        let attachmentId: ID = 12345
        let draftAttachment: DraftAttachment = .makeMockDraftAttachment(id: attachmentId, state: .uploaded, disposition: .attachment)
        let mockDraft: MockDraft = .makeWithAttachments([draftAttachment])
        mockDraft.mockContent = dummyContent
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)

        await sut.removeAttachment(attachment: draftAttachment.attachment)

        XCTAssertEqual(mockDraft.mockAttachmentList.capturedRemoveIdCalls.first, attachmentId)
        XCTAssertEqual(sut.bodyAction, nil)
    }

    func testRemoveAttachment_whenAttachmentIsInline_itShouldReloadBody() async throws {
        let attachmentId: ID = 12345
        let draftAttachment: DraftAttachment = .makeMockDraftAttachment(id: attachmentId, state: .uploaded, disposition: .inline)
        let mockDraft: MockDraft = .makeWithAttachments([draftAttachment])
        mockDraft.mockContent = dummyContent
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)

        await sut.removeAttachment(attachment: draftAttachment.attachment)

        XCTAssertEqual(mockDraft.mockAttachmentList.capturedRemoveIdCalls.first, attachmentId)
        XCTAssertEqual(sut.bodyAction, ComposerBodyAction.reloadBody(content: dummyContent, clearImageCacheFirst: true))
    }

    // MARK: removeAttachment(cid:)

    func testRemoveAttachment_whenSuccessfullyRemovesAttachment_itShouldSetBodyAction() async throws {
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)

        await sut.removeAttachment(cid: "123456")

        XCTAssertEqual(mockDraft.mockAttachmentList.capturedRemoveContentIdCalls.first, "123456")
        XCTAssertEqual(sut.bodyAction, ComposerBodyAction.removeInlineImage(cid: "123456"))
    }

    func testRemoveAttachment_whenRemoveAttachmentFails_itShouldNotSetBodyAction() async throws {
        let draftAddResultError = DraftAttachmentUploadError.reason(.messageAlreadySent)
        mockDraft.mockAttachmentList.mockAttachmentListRemoveWithCidResult = [("56789", .error(draftAddResultError))]
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)

        await sut.removeAttachment(cid: "56789")

        XCTAssertNil(sut.bodyAction)
    }

    // MARK: passwordProtectionState

    func testPasswordProtectionState_whenDraftHasPasswordAndHint_itShouldReturnTheValues() {
        mockDraft.mockGetPassword = .ok(DraftPassword(password: "12345678", hint: "numbers"))
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)
        let result = sut.passwordProtectionState()
        if case .passwordProtection(let password, let hint) = result {
            XCTAssertEqual(password, "12345678")
            XCTAssertEqual(hint, "numbers")
        } else {
            XCTFail("wrong password protection state")
        }
    }

    func testPasswordProtectionState_whenError_itShouldShowAToast() {
        let error = ProtonError.otherReason(.invalidParameter)
        mockDraft.mockGetPassword = DraftGetPasswordResult.error(error)
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)
        _ = sut.passwordProtectionState()
        XCTAssertEqual(sut.toast, Toast.error(message: error.localizedDescription))
    }

    // MARK: reloadBodyAfterMemoryPressure

    func testReloadBodyAfterMemoryPressure_itShouldSetBodyAction() async {
        mockDraft.mockContent.body = "<html>test body</html>"
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)
        await sut.reloadBodyAfterMemoryPressure()
        XCTAssertEqual(sut.bodyAction, ComposerBodyAction.reloadBody(content: mockDraft.mockContent, clearImageCacheFirst: false))
    }

    // MARK: sendMessage

    func testSendMessage_whenSuccess_itDismissesWithTheCorrectDismissReason() async throws {
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)
        let dismissSpy = DismissSpy()

        await sut.sendMessage(dismissAction: dismissSpy)

        XCTAssertTrue(mockDraft.sendWasCalled)
        XCTAssertEqual(dismissReasonObserver, [.messageSent(messageId: MockDraft.defaultMessageId)])
        XCTAssertEqual(dismissSpy.callsCount, 1)
        XCTAssertEqual(sut.toast, nil)
    }

    func testSendMessage_whenFails_itShowsToastError() async throws {
        let sendError = DraftSendError.reason(.noRecipients)
        mockDraft.mockSendResult = .error(sendError)
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)
        let dismissSpy = DismissSpy()

        await sut.sendMessage(dismissAction: dismissSpy)

        XCTAssertTrue(mockDraft.sendWasCalled)
        XCTAssertEqual(dismissReasonObserver, [])
        XCTAssertEqual(dismissSpy.callsCount, 0)
        XCTAssertEqual(sut.toast, Toast.error(message: sendError.localizedDescription))
    }

    func testSendMessage_atSpecificTime_whenSuccess_itDismissesWithTheCorrectDismissReason() async throws {
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)
        let dismissSpy = DismissSpy()

        let scheduleTime: UInt64 = 1_905_427_712
        await sut.sendMessage(at: scheduleTime.date, dismissAction: dismissSpy)

        XCTAssertTrue(mockDraft.scheduleSendWasCalled)
        XCTAssertEqual(mockDraft.scheduleSendWasCalledWithTime, scheduleTime)
        XCTAssertEqual(dismissReasonObserver, [.messageScheduled(messageId: MockDraft.defaultMessageId)])
        XCTAssertEqual(dismissSpy.callsCount, 1)
        XCTAssertEqual(sut.toast, nil)
    }

    func testSendMessage_atSpecificTime_whenFails_itShowsToastError() async throws {
        let sendError = DraftSendError.reason(.missingAttachmentUploads)
        mockDraft.mockSendResult = .error(sendError)
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)
        let dismissSpy = DismissSpy()

        let scheduleTime: UInt64 = 1_905_427_712
        await sut.sendMessage(at: scheduleTime.date, dismissAction: dismissSpy)

        XCTAssertTrue(mockDraft.scheduleSendWasCalled)
        XCTAssertEqual(mockDraft.scheduleSendWasCalledWithTime, scheduleTime)
        XCTAssertEqual(dismissReasonObserver, [])
        XCTAssertEqual(dismissSpy.callsCount, 0)
        XCTAssertEqual(sut.toast, Toast.error(message: sendError.localizedDescription))
    }

    func testSendMessage_whenThereIsHangingRecipientInput_itShouldAddTheInputAsRecipient() async {
        let validHangingInput = dummyValidAddress
        let dismissSpy = DismissSpy()
        let draft: MockDraft = .emptyMockDraft
        let sut = makeSut(draft: draft, draftOrigin: .new, contactProvider: .mockInstance)
        sut.startEditingRecipients(for: .to)
        await prepareInput(sut: sut, input: validHangingInput, for: .to)

        await sut.sendMessage(dismissAction: dismissSpy)

        let expectedRecipient = ComposerRecipient.single(
            .init(
                displayName: nil,
                address: validHangingInput,
                validState: .valid,
                privacyLock: nil
            ))
        XCTAssertEqual(draft.mockToRecipientList.addedRecipients, [expectedRecipient])
    }

    func testSendMessage_whenThereIsInvalidHangingRecipientInput_itShouldShowAlertAndNotSendTheMessage() async {
        let invalidHangingInput = dummyInvalidAddress
        let dismissSpy = DismissSpy()
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)
        sut.startEditingRecipients(for: .to)
        await prepareInput(sut: sut, input: invalidHangingInput, for: .to)

        await sut.sendMessage(dismissAction: dismissSpy)

        XCTAssertNotNil(sut.state.alert)
        XCTAssertEqual(mockDraft.sendWasCalled, false)
    }

    func testSendMessage_whenRecipientsDoNotSupportExpiration_andUserChoosesToProceed_itShouldSend() async {
        mockDraft.mockDraftExpirationTimeResult = .ok(.threeDays)
        let validationActions = MessageExpirationValidatorActions.dummy(returning: .proceed)

        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance, expirationValidationActions: validationActions)
        let dismissSpy = DismissSpy()

        await sut.sendMessage(dismissAction: dismissSpy)

        XCTAssertTrue(mockDraft.sendWasCalled)
        XCTAssertEqual(dismissReasonObserver, [.messageSent(messageId: MockDraft.defaultMessageId)])
        XCTAssertEqual(dismissSpy.callsCount, 1)
        XCTAssertEqual(sut.toast, nil)
    }

    func testSendMessage_whenRecipientsDoNotSupportExpiration_andUserChoosesDoNotProceed_itShouldNotSend() async {
        mockDraft.mockDraftExpirationTimeResult = .ok(.threeDays)
        let validationActions = MessageExpirationValidatorActions.dummy(returning: .doNotProceed(addPassword: false))

        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance, expirationValidationActions: validationActions)
        let dismissSpy = DismissSpy()

        await sut.sendMessage(dismissAction: dismissSpy)

        XCTAssertFalse(mockDraft.sendWasCalled)
    }

    func testSendMessage_whenRecipientsDoNotSupportExpiration_andUserChoosesAddPassword_itShouldSetPasswordModal() async {
        mockDraft.mockDraftExpirationTimeResult = .ok(.threeDays)
        let validationActions = MessageExpirationValidatorActions.dummy(returning: .doNotProceed(addPassword: true))

        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance, expirationValidationActions: validationActions)
        let dismissSpy = DismissSpy()

        await sut.sendMessage(dismissAction: dismissSpy)

        XCTAssertFalse(mockDraft.sendWasCalled)
        XCTAssertEqual(sut.modalAction, .passwordProtection(password: "", hint: ""))
    }
}

// MARK: Helpers

private extension ComposerModelTests {
    typealias MatchContactCountTestCase = (input: String, expectedMatchCount: Int)

    private func makeSut(
        draft: any AppDraftProtocol,
        draftOrigin: DraftOrigin,
        contactProvider: ComposerContactProvider,
        expirationValidationActions: MessageExpirationValidatorActions = .productionInstance,
        senderAddressValidatorActions: SenderAddressValidatorActions = .productionInstance
    ) -> ComposerModel {
        ComposerModel(
            draft: draft,
            draftOrigin: draftOrigin,
            contactProvider: contactProvider,
            onDismiss: { self.dismissReasonObserver.append($0) },
            contactStore: CNContactStorePartialStub(),
            photosItemsHandler: testPhotosItemsHandler,
            cameraImageHandler: testCameraImageHandler,
            fileItemsHandler: testFilesItemsHandler,
            isAddingAttachmentsEnabled: true,
            expirationValidationActions: expirationValidationActions,
            senderAddressValidatorActions: senderAddressValidatorActions
        )
    }

    private func prepareInput(sut: ComposerModel, input: String, for group: RecipientGroupType) async {
        let expectation = expectation(description: "\(#function)")
        expectation.assertForOverFulfill = false
        fulfill(
            expectation, in: sut,
            when: { composerState in
                composerState.toRecipients.input == input
            })
        sut.matchContact(group: group, text: input)
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testMatchContact(in sut: ComposerModel, test: MatchContactCountTestCase) async {
        let expectation = expectation(description: "\(#function): input '\(test.input)' matches \(test.expectedMatchCount)")
        fulfill(
            expectation, in: sut,
            when: { composerState in
                composerState.toRecipients.input == test.input && composerState.toRecipients.matchingContacts.count == test.expectedMatchCount
            })

        sut.matchContact(group: .to, text: test.input)
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func fulfill(_ expectation: XCTestExpectation, in sut: ComposerModel, when condition: @escaping (ComposerState) -> Bool) {
        sut.$state
            .sink { state in
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

private extension ComposerContact {
    static func makeComposerContactSingle(name: String, email: String) -> ComposerContact {
        let type = ComposerContactType.single(.init(initials: "", name: name, email: email))
        return ComposerContact(id: "__NOT_USED__", type: type, avatarColor: .green)
    }

    init(type: ComposerContactType) {
        self.init(id: "__NOT_USED__", type: type, avatarColor: .blue)
    }
}

extension DraftAttachment {
    static func makeMockDraftAttachment(
        id: ID = .random(),
        name: String = "attachment",
        state: DraftAttachmentState,
        disposition: Disposition = .attachment
    ) -> DraftAttachment {
        let mockMimeType = AttachmentMimeType(mime: "pdf", category: .pdf)
        let mockAttachment = AttachmentMetadata(
            id: id,
            disposition: disposition,
            mimeType: mockMimeType,
            name: name,
            size: 123456,
            isListable: false
        )
        return DraftAttachment(state: state, attachment: mockAttachment, stateModifiedTimestamp: 1_742_829_536)
    }
}

private extension MessageExpirationValidatorActions {
    static func dummy(returning result: MessageExpiryValidationResult) -> Self {
        .init(validate: { _, _ in
            result
        })
    }
}

private extension MockDraft {
    static private var defaultSender: String { "old_sender@example.com" }
    static private var defaultSubject: String { "Test Subject" }
    static private var defaultContent: ComposerContent { .init(head: "Test Head", body: "Test Body") }
    static private var defaultRecipients: [ComposerRecipient] {
        [ComposerRecipient.single(.init(displayName: "", address: "inbox1@pm.me", validState: .valid, privacyLock: nil))]
    }
    static private var defaultAttachments: [DraftAttachment] {
        let mockMimeType = AttachmentMimeType(mime: "pdf", category: .pdf)
        let mockAttachment = AttachmentMetadata(
            id: .random(),
            disposition: .attachment,
            mimeType: mockMimeType,
            name: "attachment_1",
            size: 123456,
            isListable: false
        )
        return [DraftAttachment(state: .uploaded, attachment: mockAttachment, stateModifiedTimestamp: 1_742_829_536)]
    }

    static var defaultMockDraft: MockDraft {
        let attachmentList = MockAttachmentList()
        attachmentList.mockAttachments = defaultAttachments
        return MockDraft(
            mockContent: defaultContent,
            mockSender: defaultSender,
            mockSubject: defaultSubject,
            mockToRecipientList: .init(addedRecipients: defaultRecipients),
            mockCcRecipientList: .init(),
            mockBccRecipientList: .init(),
            mockAttachmentList: attachmentList
        )
    }
    static func makeWithRecipients(_ recipients: [ComposerRecipient], group: RecipientGroupType) -> MockDraft {
        let draft: MockDraft = .emptyMockDraft
        switch group {
        case .to: draft.mockToRecipientList = .init(addedRecipients: recipients)
        case .cc: draft.mockCcRecipientList = .init(addedRecipients: recipients)
        case .bcc: draft.mockBccRecipientList = .init(addedRecipients: recipients)
        }
        return draft
    }

    static func makeWithAttachments(_ attachments: [DraftAttachment]) -> MockDraft {
        let draft: MockDraft = .emptyMockDraft
        let mockAttachmentList = MockAttachmentList()
        mockAttachmentList.mockAttachments = attachments
        draft.mockAttachmentList = mockAttachmentList
        return draft
    }
}
