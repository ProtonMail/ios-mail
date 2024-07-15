// Copyright (c) 2023 Proton Technologies AG
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

import CoreData
import ProtonCoreDataModel
import ProtonCoreNetworking
import ProtonCoreTestingToolkitUnitTestsDoh
import ProtonCoreTestingToolkitUnitTestsServices
import ProtonCoreUIFoundations
@testable import ProtonMail
import protocol ProtonCoreServices.APIService
import XCTest
import SnapshotTesting

final class MailBoxViewControllerSnapshotTests: XCTestCase {
    let perceptualPrecision: Float = 0.98
    let traits: UITraitCollection = .iPhoneSe(.portrait)

    var sut: MailboxViewController!
    var viewModel: MailboxViewModel!
    var coordinator: MailboxCoordinator!

    var userContainer: UserContainer!
    var userID: UserID!
    var apiServiceMock: APIServiceMock!
    var userManagerMock: UserManager!
    var conversationStateProviderMock: MockConversationStateProviderProtocol!
    var contactGroupProviderMock: MockContactGroupsProviderProtocol!
    var labelProviderMock: MockLabelProviderProtocol!
    var contactProviderMock: MockContactProvider!
    var conversationProviderMock: MockConversationProvider!
    var eventsServiceMock: EventsServiceMock!
    var mockFetchLatestEventId: MockFetchLatestEventId!
    var toolbarActionProviderMock: MockToolbarActionProvider!
    var saveToolbarActionUseCaseMock: MockSaveToolbarActionSettingsForUsersUseCase!
    var fakeCoordinator: MockMailboxCoordinatorProtocol!

    private var testContainer: TestContainer!

    override func setUpWithError() throws {
        try super.setUpWithError()

        userID = .init(String.randomString(20))

        testContainer = .init()

        apiServiceMock = APIServiceMock()
        apiServiceMock.sessionUIDStub.fixture = String.randomString(10)
        apiServiceMock.dohInterfaceStub.fixture = DohMock()
        userManagerMock = try UserManager.prepareUser(
            apiMock: apiServiceMock,
            userID: userID,
            globalContainer: testContainer
        )
        testContainer.usersManager.add(newUser: userManagerMock)
        userManagerMock.conversationStateService.userInfoHasChanged(viewMode: .singleMessage)
        conversationStateProviderMock = MockConversationStateProviderProtocol()
        contactGroupProviderMock = MockContactGroupsProviderProtocol()
        labelProviderMock = MockLabelProviderProtocol()
        contactProviderMock = MockContactProvider(coreDataContextProvider: testContainer.contextProvider)
        conversationProviderMock = MockConversationProvider()
        eventsServiceMock = EventsServiceMock()
        mockFetchLatestEventId = MockFetchLatestEventId()
        toolbarActionProviderMock = MockToolbarActionProvider()
        saveToolbarActionUseCaseMock = MockSaveToolbarActionSettingsForUsersUseCase()

        userContainer = UserContainer(userManager: userManagerMock, globalContainer: testContainer)

        conversationProviderMock.fetchConversationStub.bodyIs { [unowned self] _, _, _, _, completion in
            self.testContainer.contextProvider.performAndWaitOnRootSavingContext { context in
                completion(.success(Conversation(context: context)))
            }
        }

        conversationProviderMock.fetchConversationCountsStub.bodyIs { _, _, completion in
            completion?(.success(()))
        }

        conversationProviderMock.fetchConversationsStub.bodyIs { _, _, _, _, _, completion in
            completion?(.success(()))
        }

        conversationProviderMock.labelStub.bodyIs { _, _, _, completion in
            completion?(.success(()))
        }

        conversationProviderMock.markAsReadStub.bodyIs { _, _, _, completion in
            completion?(.success(()))
        }

        conversationProviderMock.markAsUnreadStub.bodyIs { _, _, _, completion in
            completion?(.success(()))
        }

        conversationProviderMock.moveStub.bodyIs { _, _, _, _, _, completion in
            completion?(.success(()))
        }

        conversationProviderMock.unlabelStub.bodyIs { _, _, _, completion in
            completion?(.success(()))
        }
        fakeCoordinator = .init()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        sut = nil
        viewModel = nil
        contactGroupProviderMock = nil
        contactProviderMock = nil
        eventsServiceMock = nil
        userManagerMock = nil
        mockFetchLatestEventId = nil
        toolbarActionProviderMock = nil
        saveToolbarActionUseCaseMock = nil
        apiServiceMock = nil
        testContainer = nil
    }

    func testStorageProgressView_whenMailStorage80_free_noBanner() {
        withFeatureFlags([.splitStorage]) {
            userManagerMock.userInfo.usedBaseSpace = 80
            userManagerMock.userInfo.maxBaseSpace = 100
            userManagerMock.userInfo.subscribed = .init(rawValue: 0)

            viewModel = makeViewModel()

            sut = .init(viewModel: viewModel, dependencies: userContainer)
            sut.set(coordinator: fakeCoordinator)
            snapshot(viewController: sut)
        }
    }

    func testStorageProgressView_whenDriveStorage80_free_noBanner() {
        withFeatureFlags([.splitStorage]) {
            userManagerMock.userInfo.usedDriveSpace = 80
            userManagerMock.userInfo.maxDriveSpace = 100
            userManagerMock.userInfo.subscribed = .init(rawValue: 0)

            viewModel = makeViewModel()

            sut = .init(viewModel: viewModel, dependencies: userContainer)
            sut.set(coordinator: fakeCoordinator)
            snapshot(viewController: sut)
        }
    }

    func testStorageProgressView_whenMailStorage90_free_showBanner() {
        withFeatureFlags([.splitStorage]) {
            userManagerMock.userInfo.usedBaseSpace = 90
            userManagerMock.userInfo.maxBaseSpace = 100
            userManagerMock.userInfo.subscribed = .init(rawValue: 0)

            viewModel = makeViewModel()

            sut = .init(viewModel: viewModel, dependencies: userContainer)
            sut.set(coordinator: fakeCoordinator)
            snapshot(viewController: sut)
        }
    }

    func testStorageProgressView_whenDriveStorage90_free_showBanner() {
        withFeatureFlags([.splitStorage]) {
            userManagerMock.userInfo.usedDriveSpace = 90
            userManagerMock.userInfo.maxDriveSpace = 100
            userManagerMock.userInfo.subscribed = .init(rawValue: 0)

            viewModel = makeViewModel()

            sut = .init(viewModel: viewModel, dependencies: userContainer)
            sut.set(coordinator: fakeCoordinator)
            snapshot(viewController: sut)
        }
    }

    func testStorageProgressView_whenMailStorage98_free_showBanner() {
        withFeatureFlags([.splitStorage]) {
            userManagerMock.userInfo.usedBaseSpace = 98
            userManagerMock.userInfo.maxBaseSpace = 100
            userManagerMock.userInfo.subscribed = .init(rawValue: 0)

            viewModel = makeViewModel()

            sut = .init(viewModel: viewModel, dependencies: userContainer)
            sut.set(coordinator: fakeCoordinator)
            snapshot(viewController: sut)
        }
    }

    func testStorageProgressView_whenDriveStorage98_free_showBanner() {
        withFeatureFlags([.splitStorage]) {
            userManagerMock.userInfo.usedDriveSpace = 98
            userManagerMock.userInfo.maxDriveSpace = 100
            userManagerMock.userInfo.subscribed = .init(rawValue: 0)

            viewModel = makeViewModel()

            sut = .init(viewModel: viewModel, dependencies: userContainer)
            sut.set(coordinator: fakeCoordinator)
            snapshot(viewController: sut)
        }
    }

    func testStorageProgressView_whenMailAndDriveStorage100_free_showMailBanner() {
        withFeatureFlags([.splitStorage]) {
            userManagerMock.userInfo.usedBaseSpace = 1
            userManagerMock.userInfo.maxBaseSpace = 1
            userManagerMock.userInfo.usedDriveSpace = 1
            userManagerMock.userInfo.maxDriveSpace = 1
            userManagerMock.userInfo.subscribed = .init(rawValue: 0)

            viewModel = makeViewModel()

            sut = .init(viewModel: viewModel, dependencies: userContainer)
            sut.set(coordinator: fakeCoordinator)
            snapshot(viewController: sut)
        }
    }

    func testStorageProgressView_noError_ff_disabled() {
        withFeatureFlags([]) {
            userManagerMock.userInfo.usedBaseSpace = 1
            userManagerMock.userInfo.maxBaseSpace = 1

            viewModel = makeViewModel()

            sut = .init(viewModel: viewModel, dependencies: userContainer)
            sut.set(coordinator: fakeCoordinator)
            snapshot(viewController: sut)
        }
    }

    func testStorageProgressView_whenMailStorage100_paid_noBanner() {
        withFeatureFlags([.splitStorage]) {
            userManagerMock.userInfo.usedBaseSpace = 1
            userManagerMock.userInfo.maxBaseSpace = 1
            userManagerMock.userInfo.subscribed = .mail

            viewModel = makeViewModel()

            sut = .init(viewModel: viewModel, dependencies: userContainer)
            sut.set(coordinator: fakeCoordinator)
            snapshot(viewController: sut)
        }
    }

    func testStorageProgressView_whenDriveStorage100_paid_noBanner() {
        withFeatureFlags([.splitStorage]) {
            userManagerMock.userInfo.usedDriveSpace = 1
            userManagerMock.userInfo.maxDriveSpace = 1
            userManagerMock.userInfo.subscribed = .mail

            viewModel = makeViewModel()

            sut = .init(viewModel: viewModel, dependencies: userContainer)
            sut.set(coordinator: fakeCoordinator)
            snapshot(viewController: sut)
        }
    }

    func testStorageProgressView_whenMailBannerDismissed_free_noBanner() {
        withFeatureFlags([.splitStorage]) {
            var usersWhoHaveSeenStorageBanner = testContainer.userDefaults[.usersWhoHaveSeenStorageBanner]
            usersWhoHaveSeenStorageBanner[userID.rawValue] = true
            testContainer.userDefaults[.usersWhoHaveSeenStorageBanner] = usersWhoHaveSeenStorageBanner
            userManagerMock.userInfo.usedBaseSpace = 1
            userManagerMock.userInfo.maxBaseSpace = 1
            userManagerMock.userInfo.subscribed = .init(rawValue: 0)

            viewModel = makeViewModel()

            sut = .init(viewModel: viewModel, dependencies: userContainer)
            sut.set(coordinator: fakeCoordinator)
            snapshot(viewController: sut)
        }
    }

    func testStorageProgressView_whenDriveBannerDismissed_free_noBanner() {
        withFeatureFlags([.splitStorage]) {
            var usersWhoHaveSeenStorageBanner = testContainer.userDefaults[.usersWhoHaveSeenStorageBanner]
            usersWhoHaveSeenStorageBanner[userID.rawValue] = true
            testContainer.userDefaults[.usersWhoHaveSeenStorageBanner] = usersWhoHaveSeenStorageBanner
            userManagerMock.userInfo.usedDriveSpace = 1
            userManagerMock.userInfo.maxDriveSpace = 1
            userManagerMock.userInfo.subscribed = .init(rawValue: 0)

            viewModel = makeViewModel()

            sut = .init(viewModel: viewModel, dependencies: userContainer)
            sut.set(coordinator: fakeCoordinator)
            snapshot(viewController: sut)
        }
    }
    
    func testLockedStateBannersView_noLockedFlags_noBanner() {
        userManagerMock.userInfo.lockedFlags = nil

        viewModel = makeViewModel()

        sut = .init(viewModel: viewModel, dependencies: userContainer)
        sut.set(coordinator: fakeCoordinator)
        snapshot(viewController: sut)
    }
    
    func testLockedStateBannersView_lockedFlagsMailExceeded_showBanner() {
        userManagerMock.userInfo.lockedFlags = .mailStorageExceeded

        viewModel = makeViewModel()

        sut = .init(viewModel: viewModel, dependencies: userContainer)
        sut.set(coordinator: fakeCoordinator)
        snapshot(viewController: sut)
    }
    
    func testLockedStateBannersView_lockedFlagsDriveExceeded_showBanner() {
        userManagerMock.userInfo.lockedFlags = .driveStorageExceeded

        viewModel = makeViewModel()

        sut = .init(viewModel: viewModel, dependencies: userContainer)
        sut.set(coordinator: fakeCoordinator)
        snapshot(viewController: sut)
    }
    
    func testLockedStateBannersView_lockedFlagStorageExceeded_showBanner() {
        userManagerMock.userInfo.lockedFlags = .storageExceeded

        viewModel = makeViewModel()

        sut = .init(viewModel: viewModel, dependencies: userContainer)
        sut.set(coordinator: fakeCoordinator)
        snapshot(viewController: sut)
    }
    
    func testLockedStateBannersView_lockedFlagForOrgPrimaryAdmin_showBanner() {
        userManagerMock.userInfo.lockedFlags = .orgIssueForPrimaryAdmin

        viewModel = makeViewModel()

        sut = .init(viewModel: viewModel, dependencies: userContainer)
        sut.set(coordinator: fakeCoordinator)
        snapshot(viewController: sut)
    }
    
    func testLockedStateBannersView_lockedFlagForOrgMember_showBanner() {
        userManagerMock.userInfo.lockedFlags = .orgIssueForMember

        viewModel = makeViewModel()

        sut = .init(viewModel: viewModel, dependencies: userContainer)
        sut.set(coordinator: fakeCoordinator)
        snapshot(viewController: sut)
    }

    private func makeViewModel() -> MailboxViewModel {
        return .init(
            labelID: "labelID",
            label: nil,
            userManager: userManagerMock,
            coreDataContextProvider: testContainer.contextProvider,
            lastUpdatedStore: MockLastUpdatedStoreProtocol(),
            conversationStateProvider: conversationStateProviderMock,
            contactGroupProvider: contactGroupProviderMock,
            labelProvider: labelProviderMock,
            contactProvider: contactProviderMock,
            conversationProvider: conversationProviderMock,
            eventsService: eventsServiceMock,
            dependencies: userContainer,
            toolbarActionProvider: toolbarActionProviderMock,
            saveToolbarActionUseCase: saveToolbarActionUseCaseMock,
            totalUserCountClosure: { 0 }
        )
    }

    private func snapshot(viewController: UIViewController) {
        guard let snapshotDirectory = protonMailSnapshotDirectory(file: #file) else {
            // Add [PROJECT_ROOT: ${SRCROOT}] to target env variables]
            XCTFail()
            return
        }

        let imageSize = CGSize(width: 414, height: 750)
        protonMailAssertSnapshot(matching: viewController,
                             as: .image(on: ViewImageConfig(safeArea: .zero, size: imageSize, traits: traits.updated(to: .light)),
                                        perceptualPrecision: perceptualPrecision,
                                        size: imageSize),
                             record: false,
                             snapshotDirectory: snapshotDirectory.path,
                             testName: "\(name)-Light",
                             line: #line)

        protonMailAssertSnapshot(matching: viewController,
                             as: .image(on: ViewImageConfig(safeArea: .zero, size: imageSize, traits: traits.updated(to: .dark)),
                                        perceptualPrecision: perceptualPrecision,
                                        size: imageSize),
                             record: false,
                             snapshotDirectory: snapshotDirectory.path,
                             testName: "\(name)-dark",
                             line: #line)
    }
}

extension UITraitCollection {
    func updated(to style: UIUserInterfaceStyle) -> UITraitCollection {
        UITraitCollection(traitsFrom: [self, UITraitCollection.init(userInterfaceStyle: style)])
    }
}
