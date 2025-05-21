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
import InboxCoreUI
import PhotosUI
import proton_app_uniffi
import SwiftUI
import XCTest

@MainActor
final class ComposerModelTests: BaseTestCase {
    private var mockDraft: MockDraft!
    private var testDraftSavedToastCoordinator: DraftSavedToastCoordinator!
    private var testContactProvider: ComposerContactProvider!
    private var testPhotosItemsHandler: PhotosPickerItemHandler!
    private var photosPickerTestsHelper: PhotosPickerItemHandlerTestsHelper!
    private var testCameraImageHandler: CameraImageHandler!
    private var testFilesItemsHandler: FilePickerItemHandler!
    private var filePickerTestsHelper: FilePickerItemHandlerTestsHelper!
    private var sendingEventObserver: [SendEvent]!
    let dummyName1 = "dummy name"
    let dummyAddress1 = "test1@example.com"
    let singleRecipient1 = ComposerRecipient.single(.init(displayName: "", address: "inbox1@pm.me", validState: .valid))
    let singleRecipient2 = ComposerRecipient.single(.init(displayName: "", address: "inbox2@pm.me", validState: .valid))
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        self.testDraftSavedToastCoordinator = .init(mailUSerSession: .init(noPointer: .init()), toastStoreState: .init(initialState: .initial))
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
        self.sendingEventObserver = []
        self.mockDraft = .init()
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
        sendingEventObserver = nil
        cancellables = nil
        try super.tearDownWithError()
    }

    // MARK: init

    func testInit_whenNoStateIsPassed_itShouldReturnAnEmptyState() {
        let sut = ComposerModel(
            draft: .emptyMock,
            draftOrigin: .new,
            draftSavedToastCoordinator: testDraftSavedToastCoordinator,
            contactProvider: testContactProvider,
            onSendingEvent: { _ in },
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
        let mockDraft: MockDraft = .makeWithAttachments([.makeMockDraftAttachment(withState: .uploaded)])
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: testContactProvider)

        await sut.onLoad()

        XCTAssertFalse(sut.attachmentAlertState.isAlertPresented)
    }

    func testOnLoad_whenAttachmentInErrorState_itPresentsAlert() async throws {
        let draftError = DraftAttachmentUploadError.reason(.attachmentTooLarge)
        let mockDraft: MockDraft = .makeWithAttachments([.makeMockDraftAttachment(withState: .error(draftError))])
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: testContactProvider)

        await sut.onLoad()

        XCTAssertTrue(sut.attachmentAlertState.isAlertPresented)
    }

    func testOnLoad_whenThereAreInlineAttachments_itShouldNotMapThemToUIModels() async throws {
        let dummy1 = DraftAttachment.makeMockDraftAttachment(withState: .uploaded, disposition: .inline)
        let dummy2 = DraftAttachment.makeMockDraftAttachment(withState: .uploaded, disposition: .attachment)
        mockDraft.mockAttachmentList.mockAttachments = [dummy1, dummy2]
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)

        await sut.onLoad()

        XCTAssertEqual(sut.state.attachments, [dummy2.toDraftAttachmentUIModel()])
    }

    // MARK: startEditingRecipients

    func testStartEditingRecipients_itShouldSetEditingForTargetGroupAndExpandedForOthers() {
        let mockDraft = MockDraft()
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
        await prepareInput(sut: sut, input: "invalid_address@example", for: .to)

        sut.startEditingRecipients(for: .bcc)

        XCTAssertNotNil(sut.state.alert)
    }

    func testStartEditingRecipients_whenNoHangingInputInEditingField_itShouldNotShowAlert() async {
        let sut = makeSut(draft: .emptyMock, draftOrigin: .cache, contactProvider: testContactProvider)

        sut.startEditingRecipients(for: .to)
        await prepareInput(sut: sut, input: "valid_address@example.com", for: .to)

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
        let sut = makeSut(draft: .emptyMock, draftOrigin: .new, contactProvider: testContactProvider)
        sut.startEditingRecipients(for: .to)
        await prepareInput(sut: sut, input: dummyAddress1, for: .to)

        sut.addRecipientFromInput()

        XCTAssertEqual(sut.state.toRecipients.recipients.first?.displayName, dummyAddress1)
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

    // FIXME: When the SDK returns contact groups
////    func testAddContact_whenIsAGroup_itShouldUpdateTheRecipientss() {
//        let sut = ComposerModel(draft: .emptyMock, contactProvider: testContactProvider)
//        let contact = ComposerContact(type: .group(.init(name: dummyName1, totalMembers: 3)))
//        sut.addContact(group: .to, contact: contact)
//
//        XCTAssertEqual(sut.state.toRecipients.recipients.first?.displayName, dummyName1)
//        XCTAssertTrue(sut.state.ccRecipients.recipients.isEmpty)
//        XCTAssertTrue(sut.state.bccRecipients.recipients.isEmpty)
//    }

    // MARK: matchContacts

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

    func testEndEditingRecipients_whenThereIsHangingRecipientInput_itShouldAddTheInputAsRecipient() async {
        let hangingInput = "becky@example.com"
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
        fulfill(expectation1, in: sut, when: { composerState in
            composerState.toRecipients.input == "Adrian" && composerState.toRecipients.controllerState == .contactPicker
        })
        sut.matchContact(group: .to, text: "Adrian")
        await fulfillment(of: [expectation1], timeout: 1.0)

        // Testing the `input` and `controllerState` values
        let expectation2 = expectation(description: "\(#function)")
        fulfill(expectation2, in: sut, when: { composerState in
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

    // MARK: recipients callback

    func testComposerRecipientListCallbackUpdate_whenValidStateHasChanged_itShouldUpdateTheRecipientState() async {
        let makeSingleRecipient: (ComposerRecipientValidState) -> ComposerRecipientSingle = { validState in
            ComposerRecipientSingle(displayName: "my friend", address: "friend@example.com", validState: validState)
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

    @MainActor
    func testComposerRecipientListCallbackUpdate_whenValidStateIsAddressDoesNotExist_itShouldShowErrorToast() async {
        let makeSingleRecipient: (ComposerRecipientValidState) -> ComposerRecipientSingle = { validState in
            ComposerRecipientSingle(displayName: "my friend", address: "friend@example.com", validState: validState)
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

    // MARK: removeAttachment(cid:)

    func testRemoveAttachment_whenSuccessfullyRemovesAttachment_itShouldSetBodyAction() async throws {
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)

        await sut.removeAttachment(cid: "123456")

        XCTAssertEqual(mockDraft.mockAttachmentList.capturedRemoveCalls.first, "123456")
        XCTAssertEqual(sut.bodyAction, ComposerBodyAction.removeInlineImage(cid: "123456"))
    }

    func testRemoveAttachment_whenRemoveAttachmentFails_itShouldNotSetBodyAction() async throws {
        let draftAddResultError = DraftAttachmentUploadError.reason(.messageAlreadySent)
        mockDraft.mockAttachmentList.mockAttachmentListRemoveWithCidResult = [("56789", .error(draftAddResultError))]
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)

        await sut.removeAttachment(cid: "56789")

        XCTAssertNil(sut.bodyAction)
    }

    // MARK: sendMessage

    func testSendMessage_whenSuccess_itNotifiesTheSendEventAndDismisses() async throws {
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)
        let dismissSpy = DismissSpy()

        await sut.sendMessage(dismissAction: dismissSpy)

        XCTAssertTrue(mockDraft.sendWasCalled)
        XCTAssertEqual(sendingEventObserver, [.send])
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
        XCTAssertEqual(sendingEventObserver, [])
        XCTAssertEqual(dismissSpy.callsCount, 0)
        XCTAssertEqual(sut.toast, Toast.error(message: sendError.localizedDescription))
    }

    func testSendMessage_atSpecificTime_whenSuccess_itNotifiesTheSendEventAndDismisses() async throws {
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)
        let dismissSpy = DismissSpy()

        let scheduleTime: UInt64 = 1905427712
        await sut.sendMessage(at: scheduleTime.date, dismissAction: dismissSpy)

        XCTAssertTrue(mockDraft.scheduleSendWasCalled)
        XCTAssertEqual(mockDraft.scheduleSendWasCalledWithTime, scheduleTime)
        XCTAssertEqual(sendingEventObserver, [.scheduleSend(date: scheduleTime.date)])
        XCTAssertEqual(dismissSpy.callsCount, 1)
        XCTAssertEqual(sut.toast, nil)
    }

    func testSendMessage_atSpecificTime_whenFails_itShowsToastError() async throws {
        let sendError = DraftSendError.reason(.missingAttachmentUploads)
        mockDraft.mockSendResult = .error(sendError)
        let sut = makeSut(draft: mockDraft, draftOrigin: .new, contactProvider: .mockInstance)
        let dismissSpy = DismissSpy()

        let scheduleTime: UInt64 = 1905427712
        await sut.sendMessage(at: scheduleTime.date, dismissAction: dismissSpy)

        XCTAssertTrue(mockDraft.scheduleSendWasCalled)
        XCTAssertEqual(mockDraft.scheduleSendWasCalledWithTime, scheduleTime)
        XCTAssertEqual(sendingEventObserver, [])
        XCTAssertEqual(dismissSpy.callsCount, 0)
        XCTAssertEqual(sut.toast, Toast.error(message: sendError.localizedDescription))
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
            onSendingEvent: { self.sendingEventObserver.append($0) },
            permissionsHandler: CNContactStorePartialStub.self,
            contactStore: CNContactStorePartialStub(),
            photosItemsHandler: testPhotosItemsHandler,
            cameraImageHandler: testCameraImageHandler,
            fileItemsHandler: testFilesItemsHandler
        )
    }

    private func prepareInput(sut: ComposerModel, input: String, for group: RecipientGroupType) async {
        let expectation = expectation(description: "\(#function)")
        expectation.assertForOverFulfill = false
        fulfill(expectation, in: sut, when: { composerState in
            composerState.toRecipients.input == input
        })
        sut.matchContact(group: group, text: input)
        await fulfillment(of: [expectation], timeout: 1.0)
    }

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

private extension ComposerContact {

    static func makeComposerContactSingle(name: String, email: String) -> ComposerContact {
        let type = ComposerContactType.single(.init(initials: "", name: name, email: email))
        return ComposerContact(id: "__NOT_USED__", type: type, avatarColor: .green)
    }

    init(type: ComposerContactType) {
        self.init(id: "__NOT_USED__", type: type, avatarColor: .blue)
    }
}

private extension DraftAttachment {

    static func makeMockDraftAttachment(
        withState state: DraftAttachmentState,
        disposition: Disposition = .attachment
    ) -> DraftAttachment {
        let mockMimeType = AttachmentMimeType(mime: "pdf", category: .pdf)
        let mockAttachment = AttachmentMetadata(id: .random(), disposition: disposition, mimeType: mockMimeType, name: "attachment_1", size: 123456)
        return DraftAttachment(state: state, attachment: mockAttachment, stateModifiedTimestamp: 1742829536)
    }
}
