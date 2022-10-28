// Copyright (c) 2022 Proton AG
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

import XCTest
@testable import ProtonMail
import ProtonCore_TestingToolkit

class MailboxCoordinatorTests: XCTestCase {

    var sut: MailboxCoordinator!
    var mailboxViewControllerMock: MailboxViewController!
    var viewModelMock: MockMailBoxViewModel!
    var reachabilityStub: ReachabilityStub!
    var applicationStateStub: UIApplication.State = .active

    override func setUp() {
        super.setUp()

        let dummyServices = ServiceFactory()
        let dummyAPIService = APIServiceMock()
        let dummyUser = UserManager(api: dummyAPIService, role: .none)

        let conversationStateProviderMock = MockConversationStateProvider()
        let humanCheckStatusProviderMock = MockHumanCheckStatusProvider()
        let lastUpdatedStoreMock = MockLastUpdatedStore()
        let pushServiceMock = MockPushNotificationService()
        let contextProviderMock = MockCoreDataContextProvider()
        mailboxViewControllerMock = MailboxViewController()
        let uiNavigationControllerMock = UINavigationController(rootViewController: mailboxViewControllerMock)
        let contactGroupProviderMock = MockContactGroupsProvider()
        let labelProviderMock = MockLabelProvider()
        let contactProviderMock = MockContactProvider(coreDataContextProvider: contextProviderMock)
        let conversationProviderMock = MockConversationProvider(context: contextProviderMock.viewContext)
        let eventServiceMock = EventsServiceMock()

        let dependencies = MailboxViewModel.Dependencies(
            fetchMessages: MockFetchMessages(),
            updateMailbox: MockUpdateMailbox(),
            fetchMessageDetail: MockFetchMessageDetail(stubbedResult: .failure(NSError.badResponse()))
        )
        viewModelMock = MockMailBoxViewModel(labelID: "",
                                             label: nil,
                                             labelType: .unknown,
                                             userManager: dummyUser,
                                             pushService: pushServiceMock,
                                             coreDataContextProvider: contextProviderMock,
                                             lastUpdatedStore: lastUpdatedStoreMock,
                                             humanCheckStatusProvider: humanCheckStatusProviderMock,
                                             conversationStateProvider: conversationStateProviderMock,
                                             contactGroupProvider: contactGroupProviderMock,
                                             labelProvider: labelProviderMock,
                                             contactProvider: contactProviderMock,
                                             conversationProvider: conversationProviderMock,
                                             eventsService: eventServiceMock,
                                             dependencies: dependencies,
                                             totalUserCountClosure: {
            return 0
        })

        reachabilityStub = ReachabilityStub()
        let connectionStatusProviderMock = InternetConnectionStatusProvider(notificationCenter: .default, reachability: reachabilityStub)

        sut = MailboxCoordinator(sideMenu: nil,
                                 nav: uiNavigationControllerMock,
                                 viewController: mailboxViewControllerMock,
                                 viewModel: viewModelMock,
                                 services: dummyServices,
                                 contextProvider: contextProviderMock,
                                 internetStatusProvider: connectionStatusProviderMock,
                                 getApplicationState: {
            return self.applicationStateStub
        })
        sut.viewController = nil
        mailboxViewControllerMock.set(coordinator: sut)
        mailboxViewControllerMock.set(viewModel: viewModelMock)

        viewModelMock.callFetchConversationDetail.bodyIs { _, _, callback in
            callback()
        }
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        viewModelMock = nil
        mailboxViewControllerMock = nil
    }

    func testFetchConversationFromBEIfNeeded_withNoConnection() {
        reachabilityStub.currentReachabilityStatusStub = .NotReachable
        let expectation1 = expectation(description: "closure is called")
        sut.viewController?.loadViewIfNeeded()

        sut.fetchConversationFromBEIfNeeded(conversationID: "") {
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(viewModelMock.callFetchConversationDetail.wasNotCalled)
    }

    func testFetchConversationFromBEIfNeeded_withConnectionAndAppIsActive() throws {
        applicationStateStub = .active
        reachabilityStub.currentReachabilityStatusStub = .ReachableViaWiFi
        let conversationID: ConversationID = "testID"
        let expectation1 = expectation(description: "closure is called")

        sut.fetchConversationFromBEIfNeeded(conversationID: conversationID) {
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(viewModelMock.callFetchConversationDetail.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(viewModelMock.callFetchConversationDetail.lastArguments?.a1)
        XCTAssertEqual(argument, conversationID)
    }

    func testFetchConversationFromBEIfNeeded_withConnectionAndAppIsInactive() throws {
        applicationStateStub = .inactive
        reachabilityStub.currentReachabilityStatusStub = .ReachableViaWiFi
        let conversationID: ConversationID = "testID"
        let expectation1 = expectation(description: "closure is called")
        expectation1.isInverted = true

        sut.fetchConversationFromBEIfNeeded(conversationID: conversationID) {
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 0.5, handler: nil)
        XCTAssertTrue(viewModelMock.callFetchConversationDetail.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(viewModelMock.callFetchConversationDetail.lastArguments?.a1)
        XCTAssertEqual(argument, conversationID)
    }
}
