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

        sut = ConversationViewModel(labelId: "",
                                    conversation: fakeConversation,
                                    user: fakeUser,
                                    contextProvider: contextProviderMock,
                                    internetStatusProvider: internetStatusProviderMock,
                                    isDarkModeEnableClosure: {
            return false
        },
                                    conversationNoticeViewStatusProvider: conversationNoticeViewStatusMock,
                                    conversationStateProvider: MockConversationStateProvider(),
                                    labelProvider: labelProviderMock)
    }

    override func tearDownWithError() throws {
        sut = nil
        labelProviderMock = nil

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

    private func makeFakeViewModel(
        isExpanded: Bool = true,
        location: Message.Location = .inbox
    ) -> ConversationMessageViewModel {
        let fakeInternetProvider = InternetConnectionStatusProvider(notificationCenter: .default,
                                                                    reachability: ReachabilityStub(),
                                                                    connectionMonitor: nil)
        let fakeUserManager = UserManager(api: APIServiceMock(), role: .none)

        let fakeMessage = Message(context: contextProviderMock.mainContext)
        let fakeLabel = Label(context: contextProviderMock.mainContext)
        fakeMessage.labels = NSSet(array: [fakeLabel])
        fakeLabel.labelID = location.rawValue
        let fakeMessageEntity = MessageEntity(fakeMessage)
        let viewModel = ConversationMessageViewModel(
            labelId: "",
            message: fakeMessageEntity,
            user: fakeUserManager,
            replacingEmails: [],
            internetStatusProvider: fakeInternetProvider
        ) {
            return false
        }
        if isExpanded {
            viewModel.toggleState()
        }
        return viewModel
    }
}
