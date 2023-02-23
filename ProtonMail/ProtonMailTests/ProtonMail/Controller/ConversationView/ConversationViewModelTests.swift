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
import ProtonCore_DataModel
import ProtonCore_TestingToolkit

class ConversationViewModelTests: XCTestCase {

    private var sut: ConversationViewModel!
    var contextProviderMock: MockCoreDataContextProvider!
    var labelProviderMock: MockLabelProvider!
    var messageMock: MessageEntity!
    var toolbarCustomizeSpotlightStatusProviderMock: MockToolbarCustomizeSpotlightStatusProvider!
    var toolbarActionProviderMock: MockToolbarActionProvider!
    var saveToolbarActionUseCaseMock: MockSaveToolbarActionSettingsForUsersUseCase!
    var userManagerStub: UserManager!
    var userIntroductionProgressProviderMock: MockUserIntroductionProgressProvider!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.contextProviderMock = MockCoreDataContextProvider()
        let fakeConversation = ConversationEntity(Conversation(context: contextProviderMock.viewContext))
        let apiMock = APIServiceMock()
        let fakeUser = UserManager(api: apiMock, role: .none)
        let reachabilityStub = ReachabilityStub()
        let internetStatusProviderMock = InternetConnectionStatusProvider(notificationCenter: NotificationCenter(), reachability: reachabilityStub)
        labelProviderMock = MockLabelProvider()
        toolbarCustomizeSpotlightStatusProviderMock = MockToolbarCustomizeSpotlightStatusProvider()
        toolbarActionProviderMock = MockToolbarActionProvider()
        saveToolbarActionUseCaseMock = MockSaveToolbarActionSettingsForUsersUseCase()
        userIntroductionProgressProviderMock = MockUserIntroductionProgressProvider()

        let dependencies = ConversationViewModel.Dependencies(
            fetchMessageDetail: MockFetchMessageDetail(stubbedResult: .failure(NSError.badResponse()))
        )

        sut = ConversationViewModel(labelId: "",
                                    conversation: fakeConversation,
                                    user: fakeUser,
                                    contextProvider: contextProviderMock,
                                    internetStatusProvider: internetStatusProviderMock,
                                    conversationStateProvider: MockConversationStateProvider(),
                                    labelProvider: labelProviderMock,
                                    userIntroductionProgressProvider: userIntroductionProgressProviderMock,
                                    targetID: nil,
                                    toolbarActionProvider: toolbarActionProviderMock,
                                    saveToolbarActionUseCase: saveToolbarActionUseCaseMock,
                                    toolbarCustomizeSpotlightStatusProvider: toolbarCustomizeSpotlightStatusProviderMock,
                                    goToDraft: { _, _ in },
                                    dependencies: dependencies)
    }

    override func tearDownWithError() throws {
        sut = nil
        labelProviderMock = nil
        messageMock = nil
        toolbarCustomizeSpotlightStatusProviderMock = nil
        toolbarActionProviderMock = nil
        userManagerStub = nil

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
            .header(subject: "whatever"),
            .message(viewModel: makeFakeViewModel(location: .trash)),
            .message(viewModel: makeFakeViewModel(location: .trash))
        ]
        XCTAssertTrue(sut.areAllMessagesInThreadInTheTrash)
    }

    func testAreAllMessagesInThreadInTheTrash_whenNotAllAreInTrash_ReturnsFalse() {
        sut.messagesDataSource = [
            .header(subject: "whatever"),
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
            .header(subject: "whatever"),
            .message(viewModel: makeFakeViewModel(location: .spam)),
            .message(viewModel: makeFakeViewModel(location: .spam))
        ]
        XCTAssertTrue(sut.areAllMessagesInThreadInSpam)
    }

    func testAreAllMessagesInThreadInSpam_whenNotAllAreInSpam_ReturnsFalse() {
        sut.messagesDataSource = [
            .header(subject: "whatever"),
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
            .header(subject: "whatever"),
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
            .header(subject: "whatever"),
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
        userManagerStub.conversationToolbarActions = [.markUnread]

        XCTAssertTrue(sut.actionsForToolbarCustomizeView().contains(.markRead))
        XCTAssertFalse(sut.actionsForToolbarCustomizeView().contains(.markUnread))
    }

    func testToolbarCustomizationCurrentTypes_setStarAction_withStarredConversation_hasUnStarAction() {
        let fakeConversation = makeConversationWithUnread(of: Message.Location.starred.labelID, unreadCount: 1)
        makeSUT(labelID: "1", conversation: fakeConversation)
        toolbarActionProviderMock.conversationToolbarActions = [.star]

        XCTAssertTrue(sut.actionsForToolbarCustomizeView().contains(.unstar))
        XCTAssertFalse(sut.actionsForToolbarCustomizeView().contains(.star))
    }

    func testToolbarCustomizationCurrentTypes_setUnstarAction_withUnstarredConversation_hasStarAction() {
        let fakeConversation = makeConversationWithUnread(of: "1", unreadCount: 1)
        makeSUT(labelID: "1", conversation: fakeConversation)
        toolbarActionProviderMock.conversationToolbarActions = [.star]

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
        XCTAssertEqual(saveToolbarActionUseCaseMock.callExecute.lastArguments?.first.preference.conversationActions, [.unstar, .markRead])
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
        XCTAssertEqual(saveToolbarActionUseCaseMock.callExecute.lastArguments?.first.preference.conversationActions, [.unstar, .markRead])

        let e2 = expectation(description: "Closure is called")
        sut.updateToolbarActions(actions: [.more, .unstar, .markRead]) { _ in
            e2.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(saveToolbarActionUseCaseMock.callExecute.wasCalled)
        XCTAssertEqual(saveToolbarActionUseCaseMock.callExecute.lastArguments?.first.preference.conversationActions, [.unstar, .markRead])
    }

    func testHandleActionSheetAction_starAction_completionNotCalled() {
        makeSUT(labelID: Message.Location.inbox.labelID)
        sut.messagesDataSource = [
            .header(subject: "whatever"),
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
            .header(subject: "whatever"),
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
            .header(subject: "whatever"),
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
            .header(subject: "whatever"),
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
        let apiMock = APIServiceMock()
        let fakeUser = UserManager(api: apiMock, role: .none)
        userManagerStub = fakeUser
        let reachabilityStub = ReachabilityStub()
        let internetStatusProviderMock = InternetConnectionStatusProvider(notificationCenter: NotificationCenter(), reachability: reachabilityStub)

        let dependencies = ConversationViewModel.Dependencies(
            fetchMessageDetail: MockFetchMessageDetail(stubbedResult: .failure(NSError.badResponse()))
        )

        sut = ConversationViewModel(labelId: labelID,
                                    conversation: fakeConversation,
                                    user: fakeUser,
                                    contextProvider: contextProviderMock,
                                    internetStatusProvider: internetStatusProviderMock,
                                    conversationStateProvider: MockConversationStateProvider(),
                                    labelProvider: labelProviderMock,
                                    userIntroductionProgressProvider: userIntroductionProgressProviderMock,
                                    targetID: nil,
                                    toolbarActionProvider: toolbarActionProviderMock,
                                    saveToolbarActionUseCase: saveToolbarActionUseCaseMock,
                                    toolbarCustomizeSpotlightStatusProvider: toolbarCustomizeSpotlightStatusProviderMock,
                                    goToDraft: { _, _ in },
                                    dependencies: dependencies)
    }

    private func makeFakeViewModel(
        isExpanded: Bool = true,
        location: Message.Location = .inbox
    ) -> ConversationMessageViewModel {
        let fakeInternetProvider = InternetConnectionStatusProvider(notificationCenter: .default,
                                                                    reachability: ReachabilityStub(),
                                                                    connectionMonitor: nil)
        let fakeUserManager = UserManager(api: APIServiceMock(), role: .none)
        userManagerStub = fakeUserManager

        let fakeMessageEntity = makeMessageMock(location: location)
        messageMock = fakeMessageEntity
        let viewModel = ConversationMessageViewModel(
            labelId: "",
            message: fakeMessageEntity,
            user: fakeUserManager,
            replacingEmailsMap: [:],
            contactGroups: [],
            internetStatusProvider: fakeInternetProvider,
            goToDraft: { _, _ in })
        if isExpanded {
            viewModel.toggleState()
        }
        return viewModel
    }

    private func makeMessageMock(location: Message.Location) -> MessageEntity {
        let mockMessage = Message(context: contextProviderMock.viewContext)
        let label = Label(context: contextProviderMock.viewContext)
        mockMessage.labels = NSSet(array: [label])
        mockMessage.messageID = MessageID.generateLocalID().rawValue
        label.labelID = location.rawValue
        return MessageEntity(mockMessage)
    }
}
