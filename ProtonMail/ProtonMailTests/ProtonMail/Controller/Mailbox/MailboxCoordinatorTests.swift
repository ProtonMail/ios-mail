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
    var viewModelMock: MockMailBoxViewModel!
    var connectionStatusProviderMock: MockInternetConnectionStatusProviderProtocol!
    var applicationStateStub: UIApplication.State = .active

    private var conversationStateProviderMock: MockConversationStateProviderProtocol!
    private var dummyAPIService: APIServiceMock!
    private var uiNavigationControllerMock: NavigationControllerSpy!

    override func setUp() {
        super.setUp()
        let dummyServices = ServiceFactory()
        dummyAPIService = APIServiceMock()
        let dummyUser = UserManager(api: dummyAPIService, role: .none)

        conversationStateProviderMock = .init()
        let lastUpdatedStoreMock = MockLastUpdatedStoreProtocol()
        let pushServiceMock = MockPushNotificationService()
        let contextProviderMock = MockCoreDataContextProvider()
        let mailboxViewControllerMock = MailboxViewController()
        uiNavigationControllerMock = .init(rootViewController: mailboxViewControllerMock)
        let contactGroupProviderMock = MockContactGroupsProviderProtocol()
        let labelProviderMock = MockLabelProviderProtocol()
        let contactProviderMock = MockContactProvider(coreDataContextProvider: contextProviderMock)
        let conversationProviderMock = MockConversationProvider()
        let eventServiceMock = EventsServiceMock()
        let infoBubbleViewStatusProviderMock = MockToolbarCustomizationInfoBubbleViewStatusProvider()
        let toolbarActionProviderMock = MockToolbarActionProvider()
        let saveToolbarActionUseCaseMock = MockSaveToolbarActionSettingsForUsersUseCase()
        connectionStatusProviderMock = MockInternetConnectionStatusProviderProtocol()

        let dependencies = MailboxViewModel.Dependencies(
            fetchMessages: MockFetchMessages(),
            updateMailbox: MockUpdateMailbox(),
            fetchMessageDetail: MockFetchMessageDetail(stubbedResult: .failure(NSError.badResponse())),
            fetchSenderImage: FetchSenderImage(
                dependencies: .init(
                    featureFlagCache: MockFeatureFlagCache(),
                    senderImageService: .init(
                        dependencies: .init(
                            apiService: dummyAPIService,
                            internetStatusProvider: MockInternetConnectionStatusProviderProtocol())),
                    mailSettings: dummyUser.mailSettings)
            ),
            encryptedSearchService: MockEncryptedSearchServiceProtocol()
        )
        viewModelMock = MockMailBoxViewModel(labelID: "",
                                             label: nil,
                                             labelType: .unknown,
                                             userManager: dummyUser,
                                             pushService: pushServiceMock,
                                             coreDataContextProvider: contextProviderMock,
                                             lastUpdatedStore: lastUpdatedStoreMock,
                                             conversationStateProvider: conversationStateProviderMock,
                                             contactGroupProvider: contactGroupProviderMock,
                                             labelProvider: labelProviderMock,
                                             contactProvider: contactProviderMock,
                                             conversationProvider: conversationProviderMock,
                                             eventsService: eventServiceMock,
                                             dependencies: dependencies,
                                             welcomeCarrouselCache: WelcomeCarrouselCacheMock(),
                                             toolbarActionProvider: toolbarActionProviderMock,
                                             saveToolbarActionUseCase: saveToolbarActionUseCaseMock,
                                             totalUserCountClosure: {
                                                 0
                                             })

        sut = MailboxCoordinator(sideMenu: nil,
                                 nav: uiNavigationControllerMock,
                                 viewController: mailboxViewControllerMock,
                                 viewModel: viewModelMock,
                                 services: dummyServices,
                                 contextProvider: contextProviderMock,
                                 infoBubbleViewStatusProvider: infoBubbleViewStatusProviderMock,
                                 internetStatusProvider: connectionStatusProviderMock,
                                 getApplicationState: {
            return self.applicationStateStub
        })
        sut.start()
        mailboxViewControllerMock.loadViewIfNeeded()

        viewModelMock.callFetchConversationDetail.bodyIs { _, _, callback in
            callback()
        }
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        conversationStateProviderMock = nil
        dummyAPIService = nil
        uiNavigationControllerMock = nil
        connectionStatusProviderMock = nil
        conversationStateProviderMock = nil
        dummyAPIService = nil
        uiNavigationControllerMock = nil
        viewModelMock = nil
    }

    func testFetchConversationFromBEIfNeeded_withNoConnection() {
        connectionStatusProviderMock.statusStub.fixture = .notConnected
        let expectation1 = expectation(description: "closure is called")

        sut.fetchConversationFromBEIfNeeded(conversationID: "") {
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(viewModelMock.callFetchConversationDetail.wasNotCalled)
    }

    func testFetchConversationFromBEIfNeeded_withConnectionAndAppIsActive() throws {
        applicationStateStub = .active
        connectionStatusProviderMock.statusStub.fixture = .connectedViaWiFi
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
        connectionStatusProviderMock.statusStub.fixture = .connectedViaWiFi
        let conversationID: ConversationID = "testID"
        let expectation1 = expectation(description: "closure is called")

        sut.fetchConversationFromBEIfNeeded(conversationID: conversationID) {
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 0.5, handler: nil)
        XCTAssertTrue(viewModelMock.callFetchConversationDetail.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(viewModelMock.callFetchConversationDetail.lastArguments?.a1)
        XCTAssertEqual(argument, conversationID)
    }

    func testFollowDeepLink_whenReceivesMultipleCallsForDetails_doesNotStackMultipleViewControllers() async throws {
        let messageID = "someMessageID"

        let messageData = Data(
            MessageTestData.messageMetaData(sender: "foo", recipient: "bar", messageID: messageID).utf8
        )

        let messageJSON = try JSONSerialization.jsonObject(with: messageData)

        dummyAPIService.requestJSONStub.bodyIs { _, _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .success(["Message": messageJSON]))
        }

        conversationStateProviderMock.viewModeStub.fixture = .singleMessage

        for offset in stride(from: 0, through: 0.3, by: 0.1) {
            DispatchQueue.main.asyncAfter(deadline: .now() + offset) {
                let deepLink = DeepLink(MailboxCoordinator.Destination.details.rawValue, sender: messageID)
                self.sut.follow(deepLink)
            }
        }

        try await Task.sleep(for: .milliseconds(500))

        await MainActor.run {
            // 1st call by UINavigationController.init(rootViewController:)
            // 2nd call for showing the placeholder VC
            XCTAssertEqual(uiNavigationControllerMock.pushViewControllerStub.callCounter, 2)

            // one call for showing the actual message details
            XCTAssertEqual(uiNavigationControllerMock.setViewControllersStub.callCounter, 1)
        }
    }
}

private class NavigationControllerSpy: UINavigationController {
    @FuncStub(NavigationControllerSpy.setViewControllers) var setViewControllersStub
    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        setViewControllersStub(viewControllers, animated)
        super.setViewControllers(viewControllers, animated: animated)
    }

    @FuncStub(NavigationControllerSpy.pushViewController) var pushViewControllerStub
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        pushViewControllerStub(viewController, animated)
        super.pushViewController(viewController, animated: animated)
    }
}
