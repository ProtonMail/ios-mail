// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail
import ProtonCoreDataModel
import ProtonCoreTestingToolkitUnitTestsDoh
import ProtonCoreTestingToolkitUnitTestsServices

class ConversationViewModelTests: XCTestCase {

    private var sut: ConversationViewModel!
    var contextProviderMock: MockCoreDataContextProvider!
    var featureFlagCache: MockFeatureFlagCache!
    var messageMock: MessageEntity!
    var internetStatusProviderMock: MockInternetConnectionStatusProviderProtocol!
    var toolbarActionProviderMock: MockToolbarActionProvider!
    var saveToolbarActionUseCaseMock: MockSaveToolbarActionSettingsForUsersUseCase!
    var userManagerStub: UserManager!
    var userIntroductionProgressProviderMock: MockUserIntroductionProgressProvider!
    var coordinatorMock: MockConversationCoordinator!
    var nextMessageAfterMoveStatusProviderMock: MockNextMessageAfterMoveStatusProvider!
    var notificationCenterMock: NotificationCenter!
    var apiServiceMock: APIServiceMock!
    var imageTempUrl: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.contextProviderMock = MockCoreDataContextProvider()
        let fakeConversationObject = Conversation(context: contextProviderMock.viewContext)
        let fakeConversation = ConversationEntity(fakeConversationObject)
        apiServiceMock = APIServiceMock()
        apiServiceMock.sessionUIDStub.fixture = String.randomString(10)
        apiServiceMock.dohInterfaceStub.fixture = DohMock()
        featureFlagCache = .init()
        userManagerStub = UserManager(api: apiServiceMock)
        internetStatusProviderMock = .init()
        internetStatusProviderMock.statusStub.fixture = .connectedViaWiFi
        toolbarActionProviderMock = MockToolbarActionProvider()
        saveToolbarActionUseCaseMock = MockSaveToolbarActionSettingsForUsersUseCase()
        userIntroductionProgressProviderMock = MockUserIntroductionProgressProvider()
        coordinatorMock = MockConversationCoordinator(conversation: fakeConversation)
        nextMessageAfterMoveStatusProviderMock = .init()
        notificationCenterMock = .init()
        makeSUT(labelID: "", conversation: fakeConversationObject)

        // Prepare for api mock to write image data to disk
        imageTempUrl = FileManager.default.temporaryDirectory
            .appendingPathComponent("senderImage", isDirectory: true)
        try FileManager.default.createDirectory(at: imageTempUrl, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        sut = nil
        featureFlagCache = nil
        messageMock = nil
        internetStatusProviderMock = nil
        toolbarActionProviderMock = nil
        userManagerStub = nil
        apiServiceMock = nil

        try FileManager.default.removeItem(at: imageTempUrl)
        try super.tearDownWithError()
    }

    func testFocusModeIsEnabledByDefault() {
        XCTAssert(sut.focusedMode)
    }

    func testScrollingDisablesFocusedMode() {
        sut.scrollViewDidScroll()

        XCTAssertFalse(sut.focusedMode)
    }

    func testInstructionToLeaveFocusedModeIsFiredOnce() {
        var callbackCount = 0
        sut.leaveFocusedMode = {
            callbackCount += 1
        }

        sut.scrollViewDidScroll()
        sut.scrollViewDidScroll()

        XCTAssertEqual(callbackCount, 1)
    }

    func testAreAllMessagesInThreadInTheTrash_whenAllAreInTrash_ReturnsTrue() {
        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(location: .trash)),
            .message(viewModel: makeFakeViewModel(location: .trash))
        ]
        XCTAssertTrue(sut.areAllMessagesInThreadInTheTrash)
    }

    func testAreAllMessagesInThreadInTheTrash_whenNotAllAreInTrash_ReturnsFalse() {
        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(location: .trash)),
            .message(viewModel: makeFakeViewModel(location: .inbox))
        ]
        XCTAssertFalse(sut.areAllMessagesInThreadInTheTrash)
    }

    func testAreAllMessagesInThreadInTheTrash_whenThereAreNoMessages_ReturnsFalse() {
        sut.messagesDataSource = []
        XCTAssertFalse(sut.areAllMessagesInThreadInTheTrash)
    }

    func testAreAllMessagesInThreadInSpam_whenAllAreInSpam_ReturnsTrue() {
        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(location: .spam)),
            .message(viewModel: makeFakeViewModel(location: .spam))
        ]
        XCTAssertTrue(sut.areAllMessagesInThreadInSpam)
    }

    func testAreAllMessagesInThreadInSpam_whenNotAllAreInSpam_ReturnsFalse() {
        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(location: .spam)),
            .message(viewModel: makeFakeViewModel(location: .inbox))
        ]
        XCTAssertFalse(sut.areAllMessagesInThreadInSpam)
    }

    func testAreAllMessagesInThreadInSpam_whenThereAreNoMessages_ReturnsFalse() {
        sut.messagesDataSource = []
        XCTAssertFalse(sut.areAllMessagesInThreadInSpam)
    }

    func testToolbarActionTypes_inSpam_typesContainsDelete() {
        makeSUT(labelID: Message.Location.spam.labelID)

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markUnread,
                                .delete,
                                .moveTo,
                                .labelAs,
                                .more])
    }

    func testToolbarActionTypes_inTrash_typesContainsDelete() {
        makeSUT(labelID: Message.Location.trash.labelID)

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markUnread,
                                .delete,
                                .moveTo,
                                .labelAs,
                                .more])
    }

    func testToolbarActionTypes_allMessagesAreTrash_typesContainsDelete() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(location: .trash))
        ]

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markUnread,
                                .delete,
                                .moveTo,
                                .labelAs,
                                .more])
    }

    func testToolbarActionTypes_allMessagesAreSpam_typesContainsDelete() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(location: .spam))
        ]

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markUnread,
                                .delete,
                                .moveTo,
                                .labelAs,
                                .more])
    }

    func testToolbarActionTypes_notInSpamAndTrash_typesContainsTrash() {
        let locations = Message.Location.allCases.filter { $0 != .spam && $0 != .trash }

        for location in locations {
            makeSUT(labelID: location.labelID)
            let result = sut.toolbarActionTypes()
            XCTAssertEqual(result, [.markUnread,
                                    .trash,
                                    .moveTo,
                                    .labelAs,
                                    .more])
        }
    }

    func testToolbarActionTypes_lastMessageIsScheduleSend_notReplyForwardAction() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        toolbarActionProviderMock.messageToolbarActions = [.replyOrReplyAll, .forward]
        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(location: .scheduled))
        ]

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.more])
    }

    func testToolbarActionTypes_toolbarHasReplyAndReplyAllActionAndForward_shoudBeConvertedToConversationVersion() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        toolbarActionProviderMock.messageToolbarActions = [.replyOrReplyAll, .forward]
        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(location: .inbox))
        ]

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.replyInConversation, .forwardInConversation, .more])
    }

    func testToolbarActionTypes_toolbarHasReplyAndReplyAllActionAndForward_withMultipleRecipients_shoudBeConvertedToConversationVersion() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        toolbarActionProviderMock.messageToolbarActions = [.replyOrReplyAll, .forward]
        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(location: .inbox, multipleRecipients: true))
        ]

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.replyAllInConversation, .forwardInConversation, .more])
    }

    func testToolbarActionTypes_inSpam_toolbarHasArchiveAndMoveToSpamActions_MoveToSpamShouldBeConveredToMoveToInbox() {
        makeSUT(labelID: Message.Location.spam.labelID)
        toolbarActionProviderMock.messageToolbarActions = [.archive, .spam]
        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(location: .inbox, multipleRecipients: true))
        ]

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.archive, .spamMoveToInbox, .more])
    }

    func testToolbarActionTypes_inArchive_toolbarHasArchiveAndMoveToSpamActions_ArchiveShouldBeConveredToMoveToInbox() {
        makeSUT(labelID: Message.Location.archive.labelID)
        toolbarActionProviderMock.messageToolbarActions = [.archive, .spam]
        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(location: .archive, multipleRecipients: true))
        ]

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.inbox, .spam, .more])
    }

    func testToolbarActionTypes_inInbox_toolbarHasArchive_oneOfMessagesIsArchived_shouldKeepArchiveAction() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        toolbarActionProviderMock.messageToolbarActions = [.archive]
        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(location: .archive, multipleRecipients: true)),
            .message(viewModel: makeFakeViewModel(location: .inbox, multipleRecipients: true))
        ]

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.archive, .more])
    }

    func testToolbarActionTypes_inInbox_toolbarHasArchive_AllMessagesAreArchived_archiveShouldBeConveredToMoveToInbox() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        toolbarActionProviderMock.messageToolbarActions = [.archive]
        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(location: .archive, multipleRecipients: true)),
            .message(viewModel: makeFakeViewModel(location: .archive, multipleRecipients: true))
        ]

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.inbox, .more])
    }

    func testToolbarCustomizationCurrentTypes_notContainsMoreAction() {
        toolbarActionProviderMock.conversationToolbarActions = []

        XCTAssertFalse(sut.actionsForToolbarCustomizeView().contains(.more))
    }

    func testToolbarCustomizationCurrentTypes_setReadAction_withReadConversation_hasUnreadAction() {
        let fakeConversation = makeConversationWithUnread(of: "1", unreadCount: 0)
        makeSUT(labelID: "1", conversation: fakeConversation)
        toolbarActionProviderMock.conversationToolbarActions = [.markUnread]

        XCTAssertTrue(sut.actionsForToolbarCustomizeView().contains(.markUnread))
        XCTAssertFalse(sut.actionsForToolbarCustomizeView().contains(.markRead))
    }

    func testToolbarCustomizationCurrentTypes_setUnreadAction_withUnreadConversation_hasReadAction() {
        let fakeConversation = makeConversationWithUnread(of: "1", unreadCount: 1)
        makeSUT(labelID: "1", conversation: fakeConversation)
        userManagerStub.messageToolbarActions = [.markUnread]

        XCTAssertTrue(sut.actionsForToolbarCustomizeView().contains(.markRead))
        XCTAssertFalse(sut.actionsForToolbarCustomizeView().contains(.markUnread))
    }

    func testToolbarCustomizationCurrentTypes_setStarAction_withStarredConversation_hasUnStarAction() {
        let fakeConversation = makeConversationWithUnread(of: Message.Location.starred.labelID, unreadCount: 1)
        makeSUT(labelID: "1", conversation: fakeConversation)
        toolbarActionProviderMock.messageToolbarActions = [.star]

        XCTAssertTrue(sut.actionsForToolbarCustomizeView().contains(.unstar))
        XCTAssertFalse(sut.actionsForToolbarCustomizeView().contains(.star))
    }

    func testToolbarCustomizationCurrentTypes_setUnstarAction_withUnstarredConversation_hasStarAction() {
        let fakeConversation = makeConversationWithUnread(of: "1", unreadCount: 1)
        makeSUT(labelID: "1", conversation: fakeConversation)
        toolbarActionProviderMock.messageToolbarActions = [.star]

        XCTAssertTrue(sut.actionsForToolbarCustomizeView().contains(.star))
        XCTAssertFalse(sut.actionsForToolbarCustomizeView().contains(.unstar))
    }

    func testUpdateToolbarActions_updateActionWithoutMoreAction() {
        saveToolbarActionUseCaseMock.callExecute.bodyIs { _, _, completion  in
            completion(.success(Void()))
        }
        let e = expectation(description: "Closure is called")
        sut.updateToolbarActions(actions: [.unstar, .markRead]) { _ in
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(saveToolbarActionUseCaseMock.callExecute.wasCalledExactlyOnce)
        XCTAssertEqual(saveToolbarActionUseCaseMock.callExecute.lastArguments?.first.preference.messageActions, [.unstar, .markRead])
    }

    func testUpdateToolbarActions_updateActionWithMoreAction() {
        saveToolbarActionUseCaseMock.callExecute.bodyIs { _, _, completion  in
            completion(.success(Void()))
        }
        let e = expectation(description: "Closure is called")
        sut.updateToolbarActions(actions: [.unstar, .markRead, .more]) { _ in
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(saveToolbarActionUseCaseMock.callExecute.wasCalledExactlyOnce)
        XCTAssertEqual(saveToolbarActionUseCaseMock.callExecute.lastArguments?.first.preference.messageActions, [.unstar, .markRead])

        let e2 = expectation(description: "Closure is called")
        sut.updateToolbarActions(actions: [.more, .unstar, .markRead]) { _ in
            e2.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(saveToolbarActionUseCaseMock.callExecute.wasCalled)
        XCTAssertEqual(saveToolbarActionUseCaseMock.callExecute.lastArguments?.first.preference.messageActions, [.unstar, .markRead])
    }

    func testHandleActionSheetAction_starAction_completionNotCalled() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(location: .spam))
        ]
        let e = expectation(description: "Closure should be called")

        sut.handleActionSheetAction(.star,
                                    message: messageMock,
                                    body: nil) { shouldDismissView in
            XCTAssertFalse(shouldDismissView)
            e.fulfill()
        }

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testHandleActionSheetAction_unStarAction_completionNotCalled() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(location: .spam))
        ]
        let e = expectation(description: "Closure should be called")

        sut.handleActionSheetAction(.unstar,
                                    message: messageMock,
                                    body: nil) { shouldDismissView in
            XCTAssertFalse(shouldDismissView)
            e.fulfill()
        }

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testHandleActionSheetAction_viewInLightModeAction_completionNotCalled() throws {
        makeSUT(labelID: Message.Location.inbox.labelID)
        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(location: .spam))
        ]

        sut.handleActionSheetAction(.viewInLightMode,
                                    message: messageMock,
                                    body: nil) { shouldDismissView in
            XCTAssertFalse(shouldDismissView)
        }
        let bodyModel = try XCTUnwrap(sut.messagesDataSource.first(where: { $0.message?.messageID == messageMock.messageID })?.messageViewModel?.state.expandedViewModel?.messageContent.messageBodyViewModel)
        // Render update switch thread, wait for 1 second to get updated value
        let exp = expectation(description: "wait for 1 second")
        let result = XCTWaiter.wait(for: [exp], timeout: 1)
        if result == XCTWaiter.Result.timedOut {
            XCTAssertEqual(bodyModel.currentMessageRenderStyle, .lightOnly)
        } else {
            XCTFail("Delay interrupted")
        }
    }

    func testHandleActionSheetAction_viewInLightModeAction_messageNotFound_completionNotCalled() throws {
        makeSUT(labelID: Message.Location.inbox.labelID)
        let e = expectation(description: "Closure should be called")
        messageMock = makeMessageMock(location: .inbox)

        sut.handleActionSheetAction(.viewInLightMode,
                                    message: messageMock,
                                    body: nil) { shouldDismissView in
            XCTAssertTrue(shouldDismissView)
            e.fulfill()
        }

        let model = sut.messagesDataSource.first(where: { $0.message?.messageID == messageMock.messageID })
        XCTAssertNil(model)

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testHandleActionSheetAction_viewInDarkModeAction_completionNotCalled() throws {
        makeSUT(labelID: Message.Location.inbox.labelID)
        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(location: .spam))
        ]
        let e = expectation(description: "Closure should be called")

        sut.handleActionSheetAction(.viewInDarkMode,
                                    message: messageMock,
                                    body: nil) { shouldDismissView in
            XCTAssertFalse(shouldDismissView)
            e.fulfill()
        }

        let result = try XCTUnwrap(sut.messagesDataSource.first(where: { $0.message?.messageID == messageMock.messageID })).messageViewModel?.state.expandedViewModel?.messageContent.messageBodyViewModel.currentMessageRenderStyle
        XCTAssertEqual(result, .dark)

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testHandleActionSheetAction_viewInDarkModeAction_messageNotFound_completionNotCalled() throws {
        makeSUT(labelID: Message.Location.inbox.labelID)
        let e = expectation(description: "Closure should be called")
        messageMock = makeMessageMock(location: .inbox)

        sut.handleActionSheetAction(.viewInDarkMode,
                                    message: messageMock,
                                    body: nil) { shouldDismissView in
            XCTAssertTrue(shouldDismissView)
            e.fulfill()
        }

        let model = sut.messagesDataSource.first(where: { $0.message?.messageID == messageMock.messageID })
        XCTAssertNil(model)

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testShouldShowToolbarCustomizeSpotlight_userHasNotSeenSpotlight_returnTrue() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        userIntroductionProgressProviderMock.shouldShowSpotlightStub.bodyIs { _, key, _ in
            XCTAssertEqual(key, .toolbarCustomization)
            return true
        }

        XCTAssertTrue(sut.shouldShowToolbarCustomizeSpotlight())
    }

    func testShouldShowToolbarCustomizeSpotlight_userHasSeenSpotlight_returnFalse() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        userIntroductionProgressProviderMock.shouldShowSpotlightStub.bodyIs { _, key, _ in
            XCTAssertEqual(key, .toolbarCustomization)
            return false
        }

        XCTAssertFalse(sut.shouldShowToolbarCustomizeSpotlight())
    }

    func testSendSwipeNotification_withFlagIsFalse_notificationShouldNotSend() {
        let e = XCTNSNotificationExpectation(name: .pagesSwipeExpectation, object: nil, notificationCenter: notificationCenterMock)
        e.isInverted = true
        nextMessageAfterMoveStatusProviderMock.shouldMoveToNextMessageAfterMoveStub.fixture = false

        sut.sendSwipeNotificationIfNeeded(isInPageView: true)

        wait(for: [e], timeout: 2)
    }

    func testSendSwipeNotification_withFlagIsTrue_notificationIsSent() {
        let e = XCTNSNotificationExpectation(name: .pagesSwipeExpectation, object: nil, notificationCenter: notificationCenterMock)
        nextMessageAfterMoveStatusProviderMock.shouldMoveToNextMessageAfterMoveStub.fixture = true

        sut.sendSwipeNotificationIfNeeded(isInPageView: true)

        wait(for: [e], timeout: 1)
	}

    func testSendSwipeNotification_withFlagIsTrue_notInPageView_notificationDoesNotSend() {
        let e = XCTNSNotificationExpectation(name: .pagesSwipeExpectation, object: nil, notificationCenter: notificationCenterMock)
        e.isInverted = true
        nextMessageAfterMoveStatusProviderMock.shouldMoveToNextMessageAfterMoveStub.fixture = true

        sut.sendSwipeNotificationIfNeeded(isInPageView: false)

        wait(for: [e], timeout: 2)
    }

    func testFocusedMode_lastNonExpandedMessage_isPartiallyVisibile() {
        makeSUT(labelID: Message.Location.inbox.labelID)

        sut.headerSectionDataSource = [
            .trashedHint
        ]

        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(isExpanded: false)),
            .message(viewModel: makeFakeViewModel(isExpanded: false)),
            .message(viewModel: makeFakeViewModel(isExpanded: false)),
            .message(viewModel: makeFakeViewModel(isExpanded: true))
        ]

        XCTAssertEqual(sut.headerCellVisibility(at: 0), .hidden)

        XCTAssertEqual(sut.messageCellVisibility(at: 0), .hidden)
        XCTAssertEqual(sut.messageCellVisibility(at: 1), .hidden)
        XCTAssertEqual(sut.messageCellVisibility(at: 2), .partial)
        XCTAssertEqual(sut.messageCellVisibility(at: 3), .full)
    }

    func testFocusedMode_skipsOverTrashedMessagesAndHint() {
        makeSUT(labelID: Message.Location.inbox.labelID)

        sut.headerSectionDataSource = [
            .trashedHint
        ]

        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(isExpanded: false, location: .inbox)),
            .message(viewModel: makeFakeViewModel(isExpanded: false, location: .inbox)),
            .message(viewModel: makeFakeViewModel(isExpanded: false, location: .trash)),
            .message(viewModel: makeFakeViewModel(isExpanded: true, location: .inbox))
        ]

        XCTAssertEqual(sut.headerCellVisibility(at: 0), .hidden)

        XCTAssertEqual(sut.messageCellVisibility(at: 0), .hidden)
        XCTAssertEqual(sut.messageCellVisibility(at: 1), .partial)
        XCTAssertEqual(sut.messageCellVisibility(at: 2), .hidden)
        XCTAssertEqual(sut.messageCellVisibility(at: 3), .full)
    }

    func testFocusedMode_ifAllPreviousMessagesAreTrashed_partiallyShowsTrashedHint() {
        makeSUT(labelID: Message.Location.inbox.labelID)

        sut.headerSectionDataSource = [
            .trashedHint
        ]

        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(isExpanded: false, location: .trash)),
            .message(viewModel: makeFakeViewModel(isExpanded: false, location: .trash)),
            .message(viewModel: makeFakeViewModel(isExpanded: true, location: .inbox))
        ]

        XCTAssertEqual(sut.headerCellVisibility(at: 0), .partial)

        XCTAssertEqual(sut.messageCellVisibility(at: 0), .hidden)
        XCTAssertEqual(sut.messageCellVisibility(at: 1), .hidden)
        XCTAssertEqual(sut.messageCellVisibility(at: 2), .full)
    }

    func testFocusedMode_ifTheLastMessageIsTrashed_partiallyShowsTrashedHint() {
        makeSUT(labelID: Message.Location.inbox.labelID)

        sut.headerSectionDataSource = [
            .trashedHint
        ]

        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(isExpanded: false, location: .inbox)),
            .message(viewModel: makeFakeViewModel(isExpanded: true, location: .trash))
        ]

        XCTAssertEqual(sut.headerCellVisibility(at: 0), .partial)

        XCTAssertEqual(sut.messageCellVisibility(at: 0), .full)
        XCTAssertEqual(sut.messageCellVisibility(at: 1), .hidden)
    }

    func testFocusedMode_handlesExpandedMessageInTheMiddle() {
        makeSUT(labelID: Message.Location.inbox.labelID)

        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(isExpanded: false)),
            .message(viewModel: makeFakeViewModel(isExpanded: true)),
            .message(viewModel: makeFakeViewModel(isExpanded: false))
        ]

        XCTAssertEqual(sut.messageCellVisibility(at: 0), .partial)
        XCTAssertEqual(sut.messageCellVisibility(at: 1), .full)
        XCTAssertEqual(sut.messageCellVisibility(at: 2), .full)	
	}

    func testFindLatestMessageForAction_getTheLatestMessageNotInTrashOrDraft() throws {
        makeSUT(labelID: Message.Location.inbox.labelID)
        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(location: .spam)),
            .message(viewModel: makeFakeViewModel(location: .trash)),
            .message(viewModel: makeFakeViewModel(location: .inbox)),
            .message(viewModel: makeFakeViewModel(location: .draft))
        ]

        let result = try XCTUnwrap(sut.findLatestMessageForAction())

        XCTAssertTrue(result.contains(location: .inbox))
        XCTAssertFalse(result.isTrash)
        XCTAssertFalse(result.isDraft)
    }

    func testFindLatestMessageForAction_MessagesInTrashWithOneDraftAsTheLatestMessage_returnTheLatestTrashMessage() throws {
        makeSUT(labelID: Message.Location.trash.labelID)
        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(location: .trash)),
            .message(viewModel: makeFakeViewModel(location: .trash)),
            .message(viewModel: makeFakeViewModel(location: .trash)),
            .message(viewModel: makeFakeViewModel(location: .trash)),
            .message(viewModel: makeFakeViewModel(location: .draft))
        ]

        let result = try XCTUnwrap(sut.findLatestMessageForAction())

        XCTAssertTrue(result.contains(location: .trash))
        XCTAssertEqual(
            result.messageID,
            sut.messagesDataSource
                .last(where: { !$0.message!.isDraft })?.message?.messageID
        )
    }

    func testFindLatestMessageForAction_allMessageInDraft_returnNil() {
        makeSUT(labelID: Message.Location.trash.labelID)
        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(location: .draft)),
            .message(viewModel: makeFakeViewModel(location: .draft)),
            .message(viewModel: makeFakeViewModel(location: .draft)),
            .message(viewModel: makeFakeViewModel(location: .draft)),
            .message(viewModel: makeFakeViewModel(location: .draft))
        ]

        XCTAssertNil(sut.findLatestMessageForAction())
    }

    func testFocusedMode_inTrashFolder_lastNonExpandedMessage_isPartiallyVisible() {
        makeSUT(labelID: Message.Location.trash.labelID)

        sut.headerSectionDataSource = [
            .trashedHint
        ]

        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(isExpanded: false, location: .trash)),
            .message(viewModel: makeFakeViewModel(isExpanded: false, location: .trash)),
            .message(viewModel: makeFakeViewModel(isExpanded: false, location: .trash)),
            .message(viewModel: makeFakeViewModel(isExpanded: true, location: .trash))
        ]

        XCTAssertEqual(sut.headerCellVisibility(at: 0), .hidden)

        XCTAssertEqual(sut.messageCellVisibility(at: 0), .hidden)
        XCTAssertEqual(sut.messageCellVisibility(at: 1), .hidden)
        XCTAssertEqual(sut.messageCellVisibility(at: 2), .partial)
        XCTAssertEqual(sut.messageCellVisibility(at: 3), .full)
    }

    func testFocusedMode_inTrashFolder_partiallyShowsTrashedHint() {
        makeSUT(labelID: Message.Location.trash.labelID)

        sut.headerSectionDataSource = [
            .trashedHint
        ]

        sut.messagesDataSource = [
            .message(viewModel: makeFakeViewModel(isExpanded: true, location: .trash)),
            .message(viewModel: makeFakeViewModel(isExpanded: false))
        ]

        XCTAssertEqual(sut.headerCellVisibility(at: 0), .partial)

        XCTAssertEqual(sut.messageCellVisibility(at: 0), .full)
        XCTAssertEqual(sut.messageCellVisibility(at: 1), .full)
    }

    func testFetchSenderImageIfNeeded_featureFlagIsOff_getNil() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        userManagerStub.mailSettings = .init(hideSenderImages: false)
        let e = expectation(description: "Closure is called")

        sut.fetchSenderImageIfNeeded(message: MessageEntity.make(),
                                     isDarkMode: Bool.random(),
                                     scale: 1.0) { result in
            XCTAssertNil(result)
            e.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(apiServiceMock.requestJSONStub.wasNotCalled)
    }

    func testFetchSenderImageIfNeeded_hideSenderImageInMailSettingTrue_getNil() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        userManagerStub.mailSettings = .init(hideSenderImages: true)
        featureFlagCache.featureFlagsStub.bodyIs { _, _ in
            SupportedFeatureFlags(rawValues: [FeatureFlagKey.senderImage.rawValue: true])
        }
        let e = expectation(description: "Closure is called")

        sut.fetchSenderImageIfNeeded(message: MessageEntity.make(),
                                     isDarkMode: Bool.random(),
                                     scale: 1.0) { result in
            XCTAssertNil(result)
            e.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(apiServiceMock.requestJSONStub.wasNotCalled)
    }

    func testFetchSenderImageIfNeeded_msgHasNoSenderThatIsEligible_getNil() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        userManagerStub.mailSettings = .init(hideSenderImages: false)
        featureFlagCache.featureFlagsStub.bodyIs { _, _ in
            SupportedFeatureFlags(rawValues: [FeatureFlagKey.senderImage.rawValue: true])
        }
        let e = expectation(description: "Closure is called")

        sut.fetchSenderImageIfNeeded(message: MessageEntity.make(),
                                     isDarkMode: Bool.random(),
                                     scale: 1.0) { result in
            XCTAssertNil(result)
            e.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(apiServiceMock.requestJSONStub.wasNotCalled)
    }

    func testFetchSenderImageIfNeeded_msgHasEligibleSender_getImageData() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        internetStatusProviderMock.statusStub.fixture = .connectedViaWiFi
        userManagerStub.mailSettings = .init(hideSenderImages: false)
        featureFlagCache.featureFlagsStub.bodyIs { _, _ in
            SupportedFeatureFlags(rawValues: [FeatureFlagKey.senderImage.rawValue: true])
        }
        let e = expectation(description: "Closure is called")
        let msg = MessageEntity.createSenderImageEligibleMessage()
        let imageData = UIImage(named: "ic-file-type-audio")?.pngData()
        apiServiceMock.downloadStub.bodyIs { _, _, fileUrl, _, _, _, _, _, _, completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                try? imageData?.write(to: fileUrl)
                let response = HTTPURLResponse(statusCode: 200)
                completion(response, nil, nil)
            }
        }

        sut.fetchSenderImageIfNeeded(message: msg,
                                     isDarkMode: Bool.random(),
                                     scale: 1.0) { result in
            XCTAssertNotNil(result)
            e.fulfill()
        }

        waitForExpectations(timeout: 2)

        XCTAssertTrue(apiServiceMock.downloadStub.wasCalledExactlyOnce)
    }

    private func makeConversationWithUnread(of labelID: LabelID, unreadCount: Int) -> Conversation {
        let fakeConversation = Conversation(context: contextProviderMock.mainContext)
        let fakeContextLabel = ContextLabel(context: contextProviderMock.mainContext)
        fakeContextLabel.labelID = labelID.rawValue
        fakeContextLabel.unreadCount = NSNumber(value: unreadCount)
        fakeContextLabel.conversation = fakeConversation
        return fakeConversation
    }

    private func makeSUT(labelID: LabelID, conversation: Conversation? = nil) {
        let conversation = conversation ?? Conversation(context: contextProviderMock.mainContext)
        let fakeConversation = ConversationEntity(conversation)
        let fakeUser = UserManager(api: apiServiceMock)
        userManagerStub = fakeUser

        let globalContainer = GlobalContainer()
        globalContainer.contextProviderFactory.register { self.contextProviderMock }
        globalContainer.featureFlagCacheFactory.register { self.featureFlagCache }
        globalContainer.internetConnectionStatusProviderFactory.register { self.internetStatusProviderMock }
        globalContainer.notificationCenterFactory.register { self.notificationCenterMock }
        globalContainer.userIntroductionProgressProviderFactory.register { self.userIntroductionProgressProviderMock }

        let userContainer = UserContainer(userManager: fakeUser, globalContainer: globalContainer)
        userContainer.nextMessageAfterMoveStatusProviderFactory.register { self.nextMessageAfterMoveStatusProviderMock }

        sut = ConversationViewModel(labelId: labelID,
                                    conversation: fakeConversation,
                                    coordinator: coordinatorMock,
                                    conversationStateProvider: MockConversationStateProviderProtocol(),
                                    labelProvider: MockLabelProviderProtocol(),
                                    targetID: nil,
                                    toolbarActionProvider: toolbarActionProviderMock,
                                    saveToolbarActionUseCase: saveToolbarActionUseCaseMock,
                                    highlightedKeywords: [],
                                    goToDraft: { _, _ in },
                                    dependencies: userContainer)
    }

    private func makeFakeViewModel(
        isExpanded: Bool = true,
        location: Message.Location = .inbox,
        multipleRecipients: Bool = false
    ) -> ConversationMessageViewModel {
        let fakeUserManager = UserManager(api: APIServiceMock())
        userManagerStub = fakeUserManager

        let globalContainer = GlobalContainer()
        let userContainer = UserContainer(userManager: fakeUserManager, globalContainer: globalContainer)

        let fakeMessageEntity = makeMessageMock(location: location, multipleRecipients: multipleRecipients)
        messageMock = fakeMessageEntity
        let viewModel = ConversationMessageViewModel(
            labelId: "",
            message: fakeMessageEntity,
            replacingEmailsMap: [:],
            contactGroups: [],
            dependencies: userContainer,
            highlightedKeywords: [],
            goToDraft: { _, _ in })
        if isExpanded {
            viewModel.toggleState()
        }
        return viewModel
    }

    private func makeMessageMock(location: Message.Location, multipleRecipients: Bool = false) -> MessageEntity {
        let mockMessage = Message(context: contextProviderMock.viewContext)
        if multipleRecipients {
            mockMessage.toList = """
[{"Address": "test@pm.me", "Name": "test", "Group": ""},{"Address": "test2@pm.me", "Name": "test2", "Group": ""}]
"""
        }
        let label = Label(context: contextProviderMock.viewContext)
        mockMessage.labels = NSSet(array: [label])
        mockMessage.messageID = MessageID.generateLocalID().rawValue
        label.labelID = location.rawValue
        if location == .scheduled {
            mockMessage.flag.insert(.scheduledSend)
        }
        return MessageEntity(mockMessage)
    }
}
