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

import ProtonCore_Keymaker
import ProtonCore_LoginUI
import ProtonCore_TestingToolkit
@testable import ProtonMail
import XCTest

final class WindowsCoordinatorTests: XCTestCase {
    private var sut: WindowsCoordinator!
    private var notificationCenter: NotificationCenter!
    private var serviceFactory: ServiceFactory!
    private var usersManager: UsersManager!
    private var unlockManagerDelegateMock: MockUnlockManagerDelegate!
    private var keyMaker: Keymaker!
    private var keyChain: KeychainWrapper!
    private var randomSuiteName = String.randomString(10)
    private var userDefaultMock: UserDefaults!
    private var cacheStatusStub: CacheStatusStub!

    override func setUp() async throws {
        keyChain = KeychainWrapper(
            service: "ch.protonmail.test",
            accessGroup: "2SB5Z68H26.ch.protonmail.protonmail"
        )
        keyMaker = Keymaker(
            autolocker: Autolocker(lockTimeProvider: userCachedStatus),
            keychain: keyChain
        )
        serviceFactory = .init()
        notificationCenter = NotificationCenter()
        unlockManagerDelegateMock = .init()
        cacheStatusStub = .init()
        await setupServiceFactory()
        await MainActor.run(body: {
            sut = .init(factory: serviceFactory)
        })
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        serviceFactory = nil
        notificationCenter = nil
        unlockManagerDelegateMock = nil
        keyMaker = nil
        keyChain.removeEverything()
        keyChain = nil
        userDefaultMock.removePersistentDomain(forName: randomSuiteName)
        userDefaultMock = nil
        cacheStatusStub = nil
    }

    func testInit_defaultWindowIsPlaceHolder() {
        XCTAssertTrue(sut.appWindow.rootViewController is PlaceholderViewController)
    }

    func testStart_isRunningUnitTest_noUserStored_didNotReceiveSignOutNotification() {
        let e = expectation(
            forNotification: .didSignOut,
            object: nil,
            notificationCenter: notificationCenter
        )
        e.isInverted = true
        unlockManagerDelegateMock.cleanAllStub.bodyIs { _, completion in
            completion()
        }
        setupSUT(showPlaceHolderViewOnly: true)

        sut.start()

        waitForExpectations(timeout: 1)
    }

    func testStart_withNoUserStored_receiveDidSignOutNotification() {
        expectation(
            forNotification: .didSignOut,
            object: nil,
            notificationCenter: notificationCenter
        )
        unlockManagerDelegateMock.cleanAllStub.bodyIs { _, completion in
            completion()
        }
        setupSUT(showPlaceHolderViewOnly: false)

        sut.start()

        waitForExpectations(timeout: 1)
    }

    func testStart_withPinProtection_goToLockWindowAndShowPinCodeView() {
        let e = expectation(description: "Closure is called")
        usersManager.add(newUser: UserManager(api: APIServiceMock(), role: .none))
        keyMaker.activate(PinProtection(pin: String.randomString(10), keychain: keyChain)) { activated in
            XCTAssertTrue(activated)
            e.fulfill()
        }
        waitForExpectations(timeout: 1)
        cacheStatusStub.isPinCodeEnabledStub = true
        setupSUT(showPlaceHolderViewOnly: false)

        sut.start()

        wait(self.sut.lockWindow != nil)
        wait(self.sut.lockWindow?.topmostViewController() is PinCodeViewController)
    }

    func testStart_withUserStored_noMailboxPWDStored_goToLockWindow() {
        unlockManagerDelegateMock.isUserStoredStub.bodyIs { _ in
            true
        }
        unlockManagerDelegateMock.isMailboxPasswordStoredStub.bodyIs { _, _ in
            false
        }
        usersManager.add(newUser: UserManager(api: APIServiceMock(), role: .none))
        setupSUT(showPlaceHolderViewOnly: false)

        sut.start()

        // Sign in View is not stored in the WindowsCoordinator.
        wait(self.sut.lockWindow == nil)
        wait(self.sut.appWindow == nil)
    }

    func testStart_withUserStored_receivedDidUnlockNotification() {
        expectation(
            forNotification: .didUnlock,
            object: nil,
            notificationCenter: notificationCenter
        )
        unlockManagerDelegateMock.isUserStoredStub.bodyIs { _ in
            true
        }
        unlockManagerDelegateMock.isMailboxPasswordStoredStub.bodyIs { _, _ in
            true
        }
        usersManager.add(newUser: UserManager(api: APIServiceMock(), role: .none))
        setupSUT(showPlaceHolderViewOnly: false)

        sut.start()

        waitForExpectations(timeout: 1)

        wait(self.sut.appWindow != nil)
        XCTAssertNil(sut.lockWindow)
        XCTAssertTrue(sut.appWindow.topmostViewController() is SkeletonViewController)
    }
}

private extension WindowsCoordinatorTests {
    func setupSUT(showPlaceHolderViewOnly: Bool) {
        sut = .init(factory: serviceFactory, showPlaceHolderViewOnly: showPlaceHolderViewOnly)
    }

    func setupServiceFactory() async {
        let unlockManager = UnlockManager(
            cacheStatus: cacheStatusStub,
            delegate: unlockManagerDelegateMock,
            keyMaker: keyMaker, pinFailedCountCache: MockPinFailedCountCache(),
            notificationCenter: notificationCenter
        )
        usersManager = UsersManager(
            doh: DohInterfaceMock(),
            userDataCache: UserDataCache(keyMaker: keyMaker, keychain: keyChain),
            coreKeyMaker: keyMaker
        )
        let pushService = PushNotificationService(
            notificationCenter: notificationCenter,
            dependencies: .init(lockCacheStatus: keyMaker, registerDevice: MockRegisterDeviceUseCase())
        )
        let queueManager = QueueManager(messageQueue: MockPMPersistentQueueProtocol(), miscQueue: MockPMPersistentQueueProtocol())
        userDefaultMock = .init(suiteName: randomSuiteName)!
        let darkModeCache = UserCachedStatus(userDefaults: userDefaultMock)
        let coreDataService = MockCoreDataContextProvider()
        let lastUpdatedStore = LastUpdatedStore(contextProvider: coreDataService)

        serviceFactory.add(UsersManager.self, for: usersManager)
        serviceFactory.add(PushNotificationService.self, for: pushService)
        serviceFactory.add(QueueManager.self, for: queueManager)
        serviceFactory.add(UserCachedStatus.self, for: darkModeCache)
        serviceFactory.add(MockCoreDataContextProvider.self, for: coreDataService)
        serviceFactory.add(CoreDataContextProviderProtocol.self, for: coreDataService)
        serviceFactory.add(LastUpdatedStore.self, for: lastUpdatedStore)
        serviceFactory.add(LastUpdatedStoreProtocol.self, for: lastUpdatedStore)
        serviceFactory.add(UnlockManager.self, for: unlockManager)
        serviceFactory.add(NotificationCenter.self, for: notificationCenter)
        serviceFactory.add(KeyMakerProtocol.self, for: keyMaker)
        return await withCheckedContinuation { continuation in
            keyMaker.activate(RandomPinProtection(pin: String.randomString(32), keychain: keyChain)) { success in
                continuation.resume()
            }
        }
    }
}

extension MockCoreDataContextProvider: Service {}
