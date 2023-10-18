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
    private var globalContainer: TestContainer!
    private var unlockManagerDelegateMock: MockUnlockManagerDelegate!
    private var cacheStatusStub: CacheStatusStub!

    override func setUp() async throws {
        try await super.setUp()

        globalContainer = .init()
        unlockManagerDelegateMock = .init()
        cacheStatusStub = .init()
        await setupDependencies()
        await MainActor.run(body: {
            sut = .init(dependencies: globalContainer)
        })
    }

    override func tearDown() {
        super.tearDown()

        globalContainer.keychain.removeEverything()

        sut = nil
        globalContainer = nil
        unlockManagerDelegateMock = nil
        cacheStatusStub = nil
    }

    func testInit_defaultWindowIsPlaceHolder() {
        XCTAssertTrue(sut.appWindow.rootViewController is PlaceholderViewController)
    }

    func testStart_isRunningUnitTest_noUserStored_didNotReceiveSignOutNotification() {
        let e = expectation(
            forNotification: .didSignOutLastAccount,
            object: nil,
            notificationCenter: globalContainer.notificationCenter
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
            forNotification: .didSignOutLastAccount,
            object: nil,
            notificationCenter: globalContainer.notificationCenter
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
        globalContainer.usersManager.add(newUser: UserManager(api: APIServiceMock()))
        globalContainer.keyMaker.activate(PinProtection(pin: String.randomString(10), keychain: globalContainer.keychain)) { activated in
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
        globalContainer.usersManager.add(newUser: UserManager(api: APIServiceMock()))
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
            notificationCenter: globalContainer.notificationCenter
        )
        unlockManagerDelegateMock.isUserStoredStub.bodyIs { _ in
            true
        }
        unlockManagerDelegateMock.isMailboxPasswordStoredStub.bodyIs { _, _ in
            true
        }
        globalContainer.usersManager.add(newUser: UserManager(api: APIServiceMock()))
        setupSUT(showPlaceHolderViewOnly: false)

        sut.start()

        waitForExpectations(timeout: 1)

        wait(self.sut.appWindow != nil)
        XCTAssertNil(sut.lockWindow)
        wait(self.sut.appWindow.topmostViewController() is SkeletonViewController)
    }
}

private extension WindowsCoordinatorTests {
    func setupSUT(showPlaceHolderViewOnly: Bool) {
        sut = .init(dependencies: globalContainer, showPlaceHolderViewOnly: showPlaceHolderViewOnly)
    }

    func setupDependencies() async {
        globalContainer.lockCacheStatusFactory.register { self.cacheStatusStub }
        globalContainer.unlockManager.delegate = unlockManagerDelegateMock

        return await withCheckedContinuation { continuation in
            globalContainer.keyMaker.activate(RandomPinProtection(pin: String.randomString(32), keychain: globalContainer.keychain)) { success in
                continuation.resume()
            }
        }
    }
}

extension MockCoreDataContextProvider: Service {}
