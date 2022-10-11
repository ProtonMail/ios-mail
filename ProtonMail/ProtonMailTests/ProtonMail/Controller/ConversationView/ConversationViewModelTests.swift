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
import ProtonCore_TestingToolkit

class ConversationViewModelTests: XCTestCase {

    private var sut: ConversationViewModel!
    var conversationNoticeViewStatusMock: MockConversationNoticeViewStatusProvider!
    var contextProviderMock: MockCoreDataContextProvider!
    var labelProviderMock: MockLabelProvider!
    var messageMock: MessageEntity!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.contextProviderMock = MockCoreDataContextProvider()
        let fakeConversation = ConversationEntity(Conversation(context: contextProviderMock.mainContext))
        let apiMock = APIServiceMock()
        let fakeUser = UserManager(api: apiMock, role: .none)
        let reachabilityStub = ReachabilityStub()
        let internetStatusProviderMock = InternetConnectionStatusProvider(notificationCenter: NotificationCenter(), reachability: reachabilityStub)
        conversationNoticeViewStatusMock = MockConversationNoticeViewStatusProvider()
        labelProviderMock = MockLabelProvider()

        let dependencies = ConversationViewModel.Dependencies(
             fetchMessageDetail: MockFetchMessageDetail(stubbedResult: .failure(NSError.badResponse()))
        )

        sut = ConversationViewModel(labelId: "",
                                    conversation: fakeConversation,
                                    user: fakeUser,
                                    contextProvider: contextProviderMock,
                                    internetStatusProvider: internetStatusProviderMock,
                                    conversationNoticeViewStatusProvider: conversationNoticeViewStatusMock,
                                    conversationStateProvider: MockConversationStateProvider(),
                                    labelProvider: labelProviderMock,
                                    goToDraft: { _ in },
                                    dependencies: dependencies)
    }

    override func tearDownWithError() throws {
        sut = nil
        labelProviderMock = nil
        messageMock = nil

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

    func testConversationNoticeViewIsOpened() {
        conversationNoticeViewStatusMock.conversationNoticeIsOpened = false
        sut.conversationNoticeViewIsOpened()
        XCTAssertTrue(conversationNoticeViewStatusMock.conversationNoticeIsOpened)
    }

    func testShouldDisplayConversationNoticeView_withNoticeIsNotOpened_withAppVersionIsNil_andMoreThanOneMessage_returnTrue() {
        conversationNoticeViewStatusMock.conversationNoticeIsOpened = false
        conversationNoticeViewStatusMock.initialUserLoggedInVersion = nil
        sut.messagesDataSource = [.message(viewModel: makeFakeViewModel(isExpanded: true)),
                                  .message(viewModel: makeFakeViewModel(isExpanded: true))]

        XCTAssertTrue(sut.shouldDisplayConversationNoticeView)
    }

    func testShouldDisplayConversationNoticeView_withNoticeIsOpened_withAppVersionIsNil_andMoreThanOneMessage_returnFalse() {
        conversationNoticeViewStatusMock.conversationNoticeIsOpened = true
        conversationNoticeViewStatusMock.initialUserLoggedInVersion = nil
        sut.messagesDataSource = [.message(viewModel: makeFakeViewModel(isExpanded: true)),
                                  .message(viewModel: makeFakeViewModel(isExpanded: true))]

        XCTAssertFalse(sut.shouldDisplayConversationNoticeView)
    }

    func testShouldDisplayConversationNoticeView_withNoticeIsNotOpened_withAppVersionIsNil_andEmptyMessage_returnFalse() {
        conversationNoticeViewStatusMock.conversationNoticeIsOpened = false
        conversationNoticeViewStatusMock.initialUserLoggedInVersion = nil
        sut.messagesDataSource = []

        XCTAssertFalse(sut.shouldDisplayConversationNoticeView)
    }

    func testShouldDisplayConversationNoticeView_withNoticeIsOpened_withAppVersionIsNil_andEmptyMessage_returnFalse() {
        conversationNoticeViewStatusMock.conversationNoticeIsOpened = true
        conversationNoticeViewStatusMock.initialUserLoggedInVersion = nil
        sut.messagesDataSource = []

        XCTAssertFalse(sut.shouldDisplayConversationNoticeView)
    }

    func testShouldDisplayConversationNoticeView_withNoticeIsOpened_withAppVersionIsNil_andOneMessage_returnFalse() {
        conversationNoticeViewStatusMock.conversationNoticeIsOpened = true
        conversationNoticeViewStatusMock.initialUserLoggedInVersion = nil
        sut.messagesDataSource = [.message(viewModel: makeFakeViewModel(isExpanded: false))]

        XCTAssertFalse(sut.shouldDisplayConversationNoticeView)
    }

    func testShouldDisplayConversationNoticeView_withNoticeIsNotOpened_withAppVersionNotNil_andMoreThanOneMessage_returnFalse() {
        conversationNoticeViewStatusMock.conversationNoticeIsOpened = false
        conversationNoticeViewStatusMock.initialUserLoggedInVersion = "3.1.6"
        sut.messagesDataSource = [.message(viewModel: makeFakeViewModel(isExpanded: true)),
                                  .message(viewModel: makeFakeViewModel(isExpanded: true))]

        XCTAssertFalse(sut.shouldDisplayConversationNoticeView)
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
        XCTAssertEqual(result, [.markAsUnread,
                                .delete,
                                .moveTo,
                                .labelAs,
                                .more])
    }

    func testToolbarActionTypes_inTrash_typesContainsDelete() {
        makeSUT(labelID: Message.Location.trash.labelID)

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markAsUnread,
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
        XCTAssertEqual(result, [.markAsUnread,
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
        XCTAssertEqual(result, [.markAsUnread,
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
            XCTAssertEqual(result, [.markAsUnread,
                                    .trash,
                                    .moveTo,
                                    .labelAs,
                                    .more])
        }
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

    private func makeSUT(labelID: LabelID) {
        let fakeConversation = ConversationEntity(Conversation(context: contextProviderMock.mainContext))
        let apiMock = APIServiceMock()
        let fakeUser = UserManager(api: apiMock, role: .none)
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
                                    conversationNoticeViewStatusProvider: conversationNoticeViewStatusMock,
                                    conversationStateProvider: MockConversationStateProvider(),
                                    labelProvider: labelProviderMock,
                                    goToDraft: { _ in },
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

        let fakeMessageEntity = makeMessageMock(location: location)
        messageMock = fakeMessageEntity
        let viewModel = ConversationMessageViewModel(
            labelId: "",
            message: fakeMessageEntity,
            user: fakeUserManager,
            replacingEmailsMap: [:],
            contactGroups: [],
            internetStatusProvider: fakeInternetProvider,
            goToDraft: { _ in })
        if isExpanded {
            viewModel.toggleState()
        }
        return viewModel
    }

    private func makeMessageMock(location: Message.Location) -> MessageEntity {
        let mockMessage = Message(context: contextProviderMock.mainContext)
        let label = Label(context: contextProviderMock.mainContext)
        mockMessage.labels = NSSet(array: [label])
        mockMessage.messageID = UUID().uuidString
        label.labelID = location.rawValue
        return MessageEntity(mockMessage)
    }
}
