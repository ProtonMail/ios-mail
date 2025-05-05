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
import ProtonCoreDataModel
@testable import ProtonCorePayments
@testable import ProtonMail
import ProtonCoreTestingToolkitUnitTestsCore
import ProtonCoreTestingToolkitUnitTestsPayments
import ProtonCoreTestingToolkitUnitTestsServices
import ProtonMailUI

class MailboxCoordinatorTests: XCTestCase {

    var sut: MailboxCoordinator!
    var viewModelMock: MockMailBoxViewModel!
    var connectionStatusProviderMock: MockInternetConnectionStatusProviderProtocol!
    var applicationStateStub: UIApplication.State = .active

    private var testContainer: TestContainer!
    private var conversationStateProviderMock: MockConversationStateProviderProtocol!
    private var dummyAPIService: APIServiceMock!
    private var uiNavigationControllerMock: NavigationControllerSpy!

    override func setUp() {
        super.setUp()
        dummyAPIService = APIServiceMock()
        testContainer = TestContainer()
        testContainer.internetConnectionStatusProviderFactory.register { self.connectionStatusProviderMock }
        let dummyUser = UserManager(api: dummyAPIService, globalContainer: testContainer)
        testContainer.usersManager.add(newUser: dummyUser)

        conversationStateProviderMock = .init()
        let lastUpdatedStoreMock = MockLastUpdatedStoreProtocol()
        let contextProviderMock = MockCoreDataContextProvider()
        let contactGroupProviderMock = MockContactGroupsProviderProtocol()
        let labelProviderMock = MockLabelProviderProtocol()
        let contactProviderMock = MockContactProvider(coreDataContextProvider: contextProviderMock)
        let conversationProviderMock = MockConversationProvider()
        let eventServiceMock = EventsServiceMock()
        let toolbarActionProviderMock = MockToolbarActionProvider()
        let saveToolbarActionUseCaseMock = MockSaveToolbarActionSettingsForUsersUseCase()
        connectionStatusProviderMock = MockInternetConnectionStatusProviderProtocol()

        viewModelMock = MockMailBoxViewModel(labelID: "",
                                             label: nil,
                                             userManager: dummyUser,
                                             coreDataContextProvider: contextProviderMock,
                                             lastUpdatedStore: lastUpdatedStoreMock,
                                             conversationStateProvider: conversationStateProviderMock,
                                             contactGroupProvider: contactGroupProviderMock,
                                             labelProvider: labelProviderMock,
                                             contactProvider: contactProviderMock,
                                             conversationProvider: conversationProviderMock,
                                             eventsService: eventServiceMock,
                                             dependencies: dummyUser.container,
                                             toolbarActionProvider: toolbarActionProviderMock,
                                             saveToolbarActionUseCase: saveToolbarActionUseCaseMock,
                                             totalUserCountClosure: {
                                                 0
                                             })

        let userContainer = dummyUser.container

        let planService = PlansDataSourceMock()
        let upsellOfferProvider = MockUpsellOfferProvider()

        userContainer.planServiceFactory.register {
            .right(planService)
        }

        userContainer.upsellOfferProviderFactory.register {
            upsellOfferProvider
        }

        let mailboxViewControllerMock = MailboxViewController(viewModel: viewModelMock, dependencies: userContainer)
        uiNavigationControllerMock = .init(rootViewController: mailboxViewControllerMock)

        sut = MailboxCoordinator(sideMenu: nil,
                                 nav: uiNavigationControllerMock,
                                 viewController: mailboxViewControllerMock,
                                 viewModel: viewModelMock,
                                 dependencies: userContainer)
        sut.start()
        mailboxViewControllerMock.loadViewIfNeeded()

        viewModelMock.callFetchConversationDetail.bodyIs { _, _, callback in
            callback()
        }

        planService.availablePlansStub.fixture = AvailablePlans(
            plans: [
                .init(ID: nil, type: nil, name: "", title: "", instances: [], entitlements: [], decorations: [])
            ],
            defaultCycle: nil
        )

        upsellOfferProvider.availablePlan = .init(
            ID: nil,
            type: nil,
            name: nil,
            title: "",
            instances: [],
            entitlements: [],
            decorations: []
        )
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        testContainer = nil
        conversationStateProviderMock = nil
        dummyAPIService = nil
        uiNavigationControllerMock = nil
        connectionStatusProviderMock = nil
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

        dummyAPIService.requestJSONStub.bodyIs { _, _, _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .success(["Message": messageJSON]))
        }

        conversationStateProviderMock.viewModeStub.fixture = .singleMessage

        let ex = expectation(description: "follow deep link")
        ex.expectedFulfillmentCount = 3
        for offset in stride(from: 0, through: 0.3, by: 0.1) {
            DispatchQueue.main.asyncAfter(deadline: .now() + offset) {
                let deepLink = DeepLink(MailboxCoordinator.Destination.details.rawValue, sender: messageID)
                self.sut.follow(deepLink)
                ex.fulfill()
            }
        }

        wait(for: [ex], timeout: 5)

        await MainActor.run {
            // 1st call by UINavigationController.init(rootViewController:)
            // 2nd call for showing the placeholder VC
            XCTAssertEqual(uiNavigationControllerMock.pushViewControllerStub.callCounter, 2)

            // one call for showing the actual message details
            XCTAssertEqual(uiNavigationControllerMock.setViewControllersStub.callCounter, 1)
        }
    }

    @MainActor
    func testFollowDeepLinkWithComposerAndUpsell() async throws {
        let messageID = "someMessageID"

        try await testContainer.contextProvider.writeAsync { context in
            let message = Message(context: context)
            message.messageID = messageID
        }

        let deepLink = DeepLink("toComposeMailto", sender: messageID)
        deepLink.append(DeepLink.Node(name: "toUpsellPage", value: "scheduleSend"))

        let window = UIWindow(root: uiNavigationControllerMock, scene: nil)
        window.makeKeyAndVisible()

        sut.follow(deepLink)

        try await Task.sleep(for: .milliseconds(500))

        let presentedViewController = try XCTUnwrap(
            uiNavigationControllerMock.presentedViewController as? UINavigationController
        )

        let composer = try XCTUnwrap(presentedViewController.viewControllers.first as? ComposeContainerViewController)
        let viewPresentedByComposer = try XCTUnwrap(composer.presentedViewController)

        XCTAssertNotNil(viewPresentedByComposer as? SheetLikeSpotlightViewController<UpsellPage>)
    }

    @MainActor
    func testGivenUserIsFreeAndSignedUpOnAnotherDevice_whenOnboardingIsFinished_thenDoesShowUpsellPage() async throws {
        try await assertThatOnboardingUpsellPageIsShown()
    }

    @MainActor
    func testGivenUserIsPaidUser_whenOnboardingIsFinished_thenDoesntShowUpsellPage() async throws {
        viewModelMock.user.userInfo.role = UserInfo.OrganizationRole.owner.rawValue
        viewModelMock.user.userInfo.subscribed.insert(.mail)

        try await assertThatOnboardingUpsellPageIsNotShown()
    }

    @MainActor
    func testGivenUserSignedUpOnThisDevice_whenOnboardingIsFinished_thenDoesntShowUpsellPage() async throws {
        testContainer.userDefaults[.didSignUpOnThisDevice] = true

        try await assertThatOnboardingUpsellPageIsNotShown()
    }

    @MainActor
    private func assertThatOnboardingUpsellPageIsShown() async throws {
        try await triggerAndDismissOnboardingCarousel()

        let presentedViewController = try XCTUnwrap(uiNavigationControllerMock.presentedViewController)
        XCTAssertNotNil(presentedViewController as? SheetLikeSpotlightViewController<OnboardingUpsellPage>)
    }

    @MainActor
    private func assertThatOnboardingUpsellPageIsNotShown() async throws {
        try await triggerAndDismissOnboardingCarousel()

        XCTAssertNil(uiNavigationControllerMock.presentedViewController)
    }

    @MainActor
    private func triggerAndDismissOnboardingCarousel() async throws {
        let window = UIWindow(root: uiNavigationControllerMock, scene: nil)
        window.makeKeyAndVisible()

        sut.go(to: .onboardingForNew)

        let presentedViewController = try XCTUnwrap(uiNavigationControllerMock.presentedViewController)
        let onboardingViewController = try XCTUnwrap(presentedViewController as? OnboardViewController)

        await onboardingViewController.dismiss(animated: false)
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
