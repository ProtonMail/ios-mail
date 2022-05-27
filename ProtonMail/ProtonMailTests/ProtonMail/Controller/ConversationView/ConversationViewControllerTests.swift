// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
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
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail
import ProtonCore_TestingToolkit

class ConversationViewControllerTests: XCTestCase {

    var sut: ConversationViewController!
    var coordinatorMock: MockConversationCoordinator!
    var fakeConversation: ConversationEntity!
    var contextProvider: MockCoreDataContextProvider!
    var viewModelMock: MockConversationViewModel!
    var apiMock: APIServiceMock!
    var fakeUser: UserManager!
    var applicationStateMock: MockApplicationStateProvider!
    var internetStatusProviderMock: InternetConnectionStatusProvider!
    var reachabilityStub: ReachabilityStub!
    var conversationNoticeViewStatusMock: MockConversationNoticeViewStatusProvider!

    override func setUp() {
        super.setUp()
        contextProvider = MockCoreDataContextProvider()
        fakeConversation = ConversationEntity(Conversation(context: contextProvider.mainContext))
        coordinatorMock = MockConversationCoordinator(conversation: fakeConversation)
        apiMock = APIServiceMock()
        fakeUser = UserManager(api: apiMock, role: .none)
        reachabilityStub = ReachabilityStub()
        internetStatusProviderMock = InternetConnectionStatusProvider(notificationCenter: NotificationCenter(), reachability: reachabilityStub)
        conversationNoticeViewStatusMock = MockConversationNoticeViewStatusProvider()

        viewModelMock = MockConversationViewModel(labelId: "",
                                                  conversation: fakeConversation,
                                                  user: fakeUser,
                                                  contextProvider: contextProvider,
                                                  internetStatusProvider: internetStatusProviderMock,
                                                  isDarkModeEnableClosure: {
            return false
        },
                                                  conversationNoticeViewStatusProvider: conversationNoticeViewStatusMock,
                                                  conversationStateProvider: MockConversationStateProvider())
        applicationStateMock = MockApplicationStateProvider(state: .background)
        sut = ConversationViewController(coordinator: coordinatorMock,
                                         viewModel: viewModelMock,
                                         applicationStateProvider: applicationStateMock)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        viewModelMock = nil
        fakeUser = nil
        coordinatorMock = nil
        fakeConversation = nil
        contextProvider = nil
        apiMock = nil
        applicationStateMock = nil
    }

    @available(iOS 13.0, *)
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
        viewModelMock.connectionStatusProvider.updateNewStatusToAll(.connectedViaCellular)
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
        viewModelMock.connectionStatusProvider.updateNewStatusToAll(.connectedViaCellular)
        XCTAssertFalse(sut.shouldReloadWhenAppIsActive)
        XCTAssertEqual(viewModelMock.callFetchConversationDetail.callCounter, 2)

        viewModelMock.connectionStatusProvider.updateNewStatusToAll(.connectedViaWiFi)
        XCTAssertFalse(sut.shouldReloadWhenAppIsActive)
        XCTAssertEqual(viewModelMock.callFetchConversationDetail.callCounter, 3)

        viewModelMock.connectionStatusProvider.updateNewStatusToAll(.notConnected)
        XCTAssertFalse(sut.shouldReloadWhenAppIsActive)
        // No call api when there is no connection
        XCTAssertEqual(viewModelMock.callFetchConversationDetail.callCounter, 3)
    }
}
