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

import ProtonCoreKeymaker
import ProtonCoreLoginUI
import ProtonCoreTestingToolkit
@testable import ProtonMail
import XCTest

final class WindowsCoordinatorTests: XCTestCase {
    private var sut: WindowsCoordinator!
    private var testContainer: TestContainer!
    private var unlockManagerDelegateMock: MockUnlockManagerDelegate!
    private var cacheStatusStub: CacheStatusStub!

    override func setUp() async throws {
        try await super.setUp()

        testContainer = .init()
        unlockManagerDelegateMock = .init()
        cacheStatusStub = .init()

        testContainer.lockCacheStatusFactory.register { self.cacheStatusStub }

        await setupDependencies()
    }

    override func tearDown() {
        super.tearDown()

        testContainer.keychain.removeEverything()

        sut = nil
        testContainer = nil
        unlockManagerDelegateMock = nil
        cacheStatusStub = nil
    }

    func testInit_defaultWindowIsPlaceHolder() {
        sut = .init(dependencies: testContainer)
        XCTAssertTrue(sut.appWindow.rootViewController is PlaceholderViewController)
    }

    func testStart_isRunningUnitTest_noUserStored_didNotReceiveSignOutNotification() {
        let e = expectation(
            forNotification: .didSignOutLastAccount,
            object: nil,
            notificationCenter: testContainer.notificationCenter
        )
        e.isInverted = true
        unlockManagerDelegateMock.cleanAllStub.bodyIs { _, completion in
            completion()
        }
        instantiateNewSUT(showPlaceHolderViewOnly: true, isAppAccessResolverEnabled: false)

        sut.start()

        waitForExpectations(timeout: 1)
    }

    func testStart_withNoUserStored_receiveDidSignOutNotification() {
        expectation(
            forNotification: .didSignOutLastAccount,
            object: nil,
            notificationCenter: testContainer.notificationCenter
        )
        unlockManagerDelegateMock.cleanAllStub.bodyIs { _, completion in
            completion()
        }
        instantiateNewSUT(showPlaceHolderViewOnly: false, isAppAccessResolverEnabled: false)

        sut.start()

        waitForExpectations(timeout: 1)
    }

    func testStart_withPinProtection_goToLockWindowAndShowPinCodeView() {
        testContainer.usersManager.add(newUser: UserManager(api: APIServiceMock()))

        cacheStatusStub.isPinCodeEnabledStub = true
        instantiateNewSUT(showPlaceHolderViewOnly: false, isAppAccessResolverEnabled: false)

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
        testContainer.usersManager.add(newUser: UserManager(api: APIServiceMock()))
        instantiateNewSUT(showPlaceHolderViewOnly: false, isAppAccessResolverEnabled: false)

        sut.start()

        // Sign in View is not stored in the WindowsCoordinator.
        wait(self.sut.lockWindow == nil)
        wait(self.sut.appWindow == nil)
    }

    func testStart_withUserStored_receivedDidUnlockNotification() {
        expectation(
            forNotification: .didUnlock,
            object: nil,
            notificationCenter: testContainer.notificationCenter
        )
        unlockManagerDelegateMock.isUserStoredStub.bodyIs { _ in
            true
        }
        unlockManagerDelegateMock.isMailboxPasswordStoredStub.bodyIs { _, _ in
            true
        }
        testContainer.usersManager.add(newUser: UserManager(api: APIServiceMock()))
        instantiateNewSUT(showPlaceHolderViewOnly: false, isAppAccessResolverEnabled: false)

        sut.start()

        waitForExpectations(timeout: 1)

        wait(self.sut.appWindow != nil)
        XCTAssertNil(sut.lockWindow)
        wait(self.sut.appWindow.topmostViewController() is SkeletonViewController)
    }
}

private extension WindowsCoordinatorTests {
    func instantiateNewSUT(showPlaceHolderViewOnly: Bool, isAppAccessResolverEnabled: Bool) {
        sut = .init(
            dependencies: testContainer,
            showPlaceHolderViewOnly: showPlaceHolderViewOnly,
            isAppAccessResolverEnabled: isAppAccessResolverEnabled
        )
    }

    func setupDependencies() async {
        testContainer.unlockManager.delegate = unlockManagerDelegateMock

        return await withCheckedContinuation { continuation in
            testContainer.keyMaker.activate(RandomPinProtection(pin: String.randomString(32), keychain: testContainer.keychain)) { success in
                continuation.resume()
            }
        }
    }
}

extension MockCoreDataContextProvider: Service {}
