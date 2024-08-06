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

import ProtonCoreTestingToolkitUnitTestsServices
import ProtonCoreUIFoundations
@testable import ProtonMail
import XCTest

class ConversationViewControllerTests: XCTestCase {

    var sut: ConversationViewController!
    var viewModelMock: MockConversationViewModel!
    var applicationStateMock: MockApplicationStateProvider!
    var internetStatusProviderMock: InternetConnectionStatusProvider!
    var nextMessageAfterMoveStatusProviderMock: MockNextMessageAfterMoveStatusProvider!
    var notificationCenterMock: NotificationCenter!
    var contextProvider: MockCoreDataContextProvider!

    override func setUp() {
        super.setUp()
        contextProvider = MockCoreDataContextProvider()
        let fakeConversation = ConversationEntity(Conversation(context: contextProvider.viewContext))
        let coordinatorMock = MockConversationCoordinator(conversation: fakeConversation)
        let apiMock = APIServiceMock()
        let fakeUser = UserManager(api: apiMock)
        let connectionMonitor = MockConnectionMonitor()
        notificationCenterMock = NotificationCenter()
        internetStatusProviderMock = InternetConnectionStatusProvider(connectionMonitor: connectionMonitor)
        nextMessageAfterMoveStatusProviderMock = .init()
        notificationCenterMock = .init()

        let globalContainer = GlobalContainer()
        globalContainer.internetConnectionStatusProviderFactory.register { self.internetStatusProviderMock }
        globalContainer.notificationCenterFactory.register { self.notificationCenterMock }

        let userContainer = UserContainer(userManager: fakeUser, globalContainer: globalContainer)
        userContainer.nextMessageAfterMoveStatusProviderFactory.register { self.nextMessageAfterMoveStatusProviderMock }

        viewModelMock = MockConversationViewModel(labelId: "",
                                                  conversation: fakeConversation,
                                                  coordinator: coordinatorMock,
                                                  conversationStateProvider: MockConversationStateProviderProtocol(),
                                                  labelProvider: MockLabelProviderProtocol(),
                                                  targetID: nil,
                                                  toolbarActionProvider: MockToolbarActionProvider(),
                                                  saveToolbarActionUseCase: MockSaveToolbarActionSettingsForUsersUseCase(),
                                                  highlightedKeywords: [],
                                                  goToDraft: { _, _  in },
                                                  dependencies: userContainer)
        applicationStateMock = MockApplicationStateProvider(state: .background)
        sut = ConversationViewController(dependencies: userContainer,
                                         viewModel: viewModelMock,
                                         applicationStateProvider: applicationStateMock)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        viewModelMock = nil
        applicationStateMock = nil
        internetStatusProviderMock = nil
        notificationCenterMock = nil
    }

    func testConnectionStatusChangedInBackground_thenBringTheAppToForeground() {
        applicationStateMock.applicationState = .background
        viewModelMock.callFetchConversationDetail.bodyIs { _, callback in
            callback?()
        }

        sut.loadViewIfNeeded()
        XCTAssertTrue(viewModelMock.isInitialDataFetchCalled)

        // ViewDidLoad will fetchConversationDetail once
        XCTAssertEqual(viewModelMock.callFetchConversationDetail.callCounter, 1)

        // Connection status changed
        internetStatusProviderMock.updateNewStatusToAll(.connectedViaCellular)
        XCTAssertTrue(sut.shouldReloadWhenAppIsActive)

        // Simulate app brings to foreground
        NotificationCenter.default.post(Notification(name: UIScene.willEnterForegroundNotification,
                                                     object: nil,
                                                     userInfo: nil))

        XCTAssertFalse(sut.shouldReloadWhenAppIsActive)
        XCTAssertEqual(viewModelMock.callFetchConversationDetail.callCounter, 2)
    }

    func testConnectionStatusChangedInForeground() {
        applicationStateMock.applicationState = .active
        viewModelMock.callFetchConversationDetail.bodyIs { _, callback in
            callback?()
        }

        sut.loadViewIfNeeded()
        XCTAssertTrue(viewModelMock.isInitialDataFetchCalled)

        XCTAssertEqual(viewModelMock.callFetchConversationDetail.callCounter, 1)
        // Connection status changed
        internetStatusProviderMock.updateNewStatusToAll(.connectedViaCellular)
        XCTAssertFalse(sut.shouldReloadWhenAppIsActive)
        XCTAssertEqual(viewModelMock.callFetchConversationDetail.callCounter, 2)

        internetStatusProviderMock.updateNewStatusToAll(.connectedViaWiFi)
        XCTAssertFalse(sut.shouldReloadWhenAppIsActive)
        XCTAssertEqual(viewModelMock.callFetchConversationDetail.callCounter, 3)

        internetStatusProviderMock.updateNewStatusToAll(.notConnected)
        XCTAssertFalse(sut.shouldReloadWhenAppIsActive)
        // No call api when there is no connection
        XCTAssertEqual(viewModelMock.callFetchConversationDetail.callCounter, 3)
    }

    func testHandleAction_delete_showDeleteAlert() throws {
        setupSUTWithWindow()
        let e = expectation(description: "Closure is called")

        sut.handleActionSheetAction(.delete) {
            e.fulfill()
        }

        waitForExpectations(timeout: 5)
        let alert = sut.presentedViewController as? UIAlertController
        XCTAssertNotNil(alert)

        let actions = try XCTUnwrap(alert?.actions)
        XCTAssertEqual(actions.count, 2)
        XCTAssertTrue(
            actions.contains(where: { $0.title == LocalString._general_delete_action })
        )
        XCTAssertTrue(
            actions.contains(where: { $0.title == LocalString._general_cancel_button })
        )
    }

//    func testHandleAction_trash_showMovedBanner_andNavigateToNextMessage() throws {
//        setupSUTWithWindow()
//        nextMessageAfterMoveStatusProviderMock.shouldMoveToNextMessageAfterMoveStub.fixture = true
//        let e = XCTNSNotificationExpectation(name: .pagesSwipeExpectation, object: nil, notificationCenter: notificationCenterMock)
//        viewModelMock.callSearchForScheduled.bodyIs { _, _, _, continueAction in
//            continueAction()
//        }
//        viewModelMock.callHandleActionSheetAction.bodyIs { _, action, completion in
//            XCTAssertEqual(action, .trash)
//            completion()
//        }
//
//        sut.handleActionSheetAction(.trash)
//
//        wait(for: [e], timeout: 2)
//        let banner = try XCTUnwrap(sut.view.subviews.compactMap { $0 as? PMBanner }.first)
//        XCTAssertEqual(banner.message, LocalString._messages_has_been_moved)
//        XCTAssertTrue(viewModelMock.callSearchForScheduled.wasCalledExactlyOnce)
//        XCTAssertTrue(viewModelMock.callHandleActionSheetAction.wasCalledExactlyOnce)
//    }

    func testHandleAction_archive_navigateToNextMessage() {
        setupSUTWithWindow()
        nextMessageAfterMoveStatusProviderMock.shouldMoveToNextMessageAfterMoveStub.fixture = true
        let e = XCTNSNotificationExpectation(name: .pagesSwipeExpectation, object: nil, notificationCenter: notificationCenterMock)
        viewModelMock.callHandleActionSheetAction.bodyIs { _, action, completion in
            XCTAssertEqual(action, .archive)
            completion()
        }

        sut.handleActionSheetAction(.archive)

        wait(for: [e], timeout: 2)
        XCTAssertTrue(viewModelMock.callHandleActionSheetAction.wasCalledExactlyOnce)
    }

    func testHandleAction_spam_navigateToNextMessage() {
        setupSUTWithWindow()
        nextMessageAfterMoveStatusProviderMock.shouldMoveToNextMessageAfterMoveStub.fixture = true
        let e = XCTNSNotificationExpectation(name: .pagesSwipeExpectation, object: nil, notificationCenter: notificationCenterMock)
        viewModelMock.callHandleActionSheetAction.bodyIs { _, action, completion in
            XCTAssertEqual(action, .spam)
            completion()
        }

        sut.handleActionSheetAction(.spam)

        wait(for: [e], timeout: 2)
        XCTAssertTrue(viewModelMock.callHandleActionSheetAction.wasCalledExactlyOnce)
    }

    func testHandleAction_inbox_navigateToNextMessage() {
        setupSUTWithWindow()
        nextMessageAfterMoveStatusProviderMock.shouldMoveToNextMessageAfterMoveStub.fixture = true
        let e = XCTNSNotificationExpectation(name: .pagesSwipeExpectation, object: nil, notificationCenter: notificationCenterMock)
        viewModelMock.callHandleActionSheetAction.bodyIs { _, action, completion in
            XCTAssertEqual(action, .inbox)
            completion()
        }

        sut.handleActionSheetAction(.inbox)

        wait(for: [e], timeout: 2)
        XCTAssertTrue(viewModelMock.callHandleActionSheetAction.wasCalledExactlyOnce)
    }

    private func makeMessageMock(location: Message.Location) -> MessageEntity {
        let mockMessage = Message(context: contextProvider.viewContext)
        let label = Label(context: contextProvider.viewContext)
        mockMessage.labels = NSSet(array: [label])
        mockMessage.messageID = UUID().uuidString
        label.labelID = location.rawValue
        return MessageEntity(mockMessage)
    }

    private func setupSUTWithWindow() {
        sut.loadViewIfNeeded()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
        window.rootViewController = sut
    }
}
