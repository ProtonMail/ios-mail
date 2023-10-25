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

/// These tests are meant to cover WindowsCoordinator when AppAccessResolver is used.
final class WindowsCoordinatorAppAccessResolverTests: XCTestCase {
    private var sut: WindowsCoordinator!
    private var testContainer: TestContainer!
    private var mockKeyMaker: MockKeyMakerProtocol!
    private var windowsCoordinatorDelegate: MockWindowsCoordinatorDelegate!

    override func setUp() {
        super.setUp()

        testContainer = .init()
        mockKeyMaker = .init()

        testContainer.keyMakerFactory.register { self.mockKeyMaker }

        windowsCoordinatorDelegate = .init()
        sut = .init(dependencies: testContainer, showPlaceHolderViewOnly: false, isAppAccessResolverEnabled: true)
        sut.delegate = windowsCoordinatorDelegate
    }

    override func tearDown() {
        super.tearDown()

        testContainer = nil
        mockKeyMaker = nil
        sut = nil
    }

    // MARK: start method

    //  main key is loaded

    func testStart_whenAppAccessIsGranted_itShouldTryToLoadTheMainKey() {
        setUpAppAccessGranted()

        executeStartAndWaitCompletion()

        XCTAssertTrue(mockKeyMaker.mainKeyExistsStub.wasCalledExactlyOnce)
    }

    func testStart_whenAppAccessIsDenied_itShouldTryToLoadTheMainKey() {
        setUpAppAccessDeniedReasonAppLock()

        executeStartAndWaitCompletion()

        XCTAssertTrue(mockKeyMaker.mainKeyExistsStub.wasCalledExactlyOnce)
    }

    //  delegate is called

    func testStart_whenAppAccessIsGranted_itShouldSetUpCoreDataAndLoadUsers() {
        setUpAppAccessGranted()

        executeStartAndWaitCompletion()

        XCTAssertTrue(windowsCoordinatorDelegate.setupCoreDataStub.wasCalledExactlyOnce)
        XCTAssertTrue(windowsCoordinatorDelegate.loadUserDataAfterUnlockStub.wasCalledExactlyOnce)
    }

    func testStart_whenAppAccessIsDenied_itShouldSetUpCoreDataButNotLoadUsers() {
        setUpAppAccessDeniedReasonAppLock()

        executeStartAndWaitCompletion()

        XCTAssertTrue(windowsCoordinatorDelegate.setupCoreDataStub.wasCalledExactlyOnce)
        XCTAssertFalse(windowsCoordinatorDelegate.loadUserDataAfterUnlockStub.wasCalledExactlyOnce)
    }

    //  windows are set

    func testStart_whenAppAccessIsGranted_itShouldSetAppWindow() {
        setUpAppAccessGranted()

        executeStartAndWaitCompletion()

        XCTAssert(sut.appWindow != nil)
    }

    func testStart_whenAppAccessIsDeniedBecauseThereAreUsersButThereIsNoMainKey_itShouldSetLockWindow() {
        setUpAppAccessDeniedReasonAppLock()

        executeStartAndWaitCompletion()

        let expectation = expectation(description: "assertion in main thread")
        DispatchQueue.main.async {
            XCTAssert(self.sut.lockWindow != nil)
            expectation.fulfill()
        }
        wait(for: [expectation])
    }

    func testStart_whenAppAccessIsDeniedBecauseThereAreNoUsers_itCurrentWindowChangesToShowSignIn() {
        executeStartAndWaitCompletion()

        let expectation = expectation(description: "assertion in main thread")
        DispatchQueue.main.async {
            XCTAssert(self.sut.lockWindow == nil)
            XCTAssert(self.sut.appWindow == nil)
            expectation.fulfill()
        }
        wait(for: [expectation])
    }

    // access denied subscription

    func testStart_whenAccessGranted_andAccessDeniedReceived_itShouldSetLockWindow() {
        setUpAppAccessGranted()
        executeStartAndWaitCompletion()

        simulateAppLockedByUserAction()

        wait(self.sut.lockWindow != nil, timeout: 5.0)
    }
}

extension WindowsCoordinatorAppAccessResolverTests {

    private func executeStartAndWaitCompletion() {
        let expectation = expectation(description: "start has completed")
        sut.start() {
            expectation.fulfill()
        }
        wait(for: [expectation])
    }

    private func setUpAppAccessGranted() {
        addNewUser()
        mockKeyMaker.isMainKeyInMemory = true
    }

    private func setUpAppAccessDeniedReasonAppLock() {
        addNewUser()
        mockKeyMaker.isMainKeyInMemory = false
    }

    private func simulateAppLockedByUserAction() {
        mockKeyMaker.isMainKeyInMemory = false
        testContainer.notificationCenter.post(name: Keymaker.Const.removedMainKeyFromMemory, object: nil)
    }

    private func addNewUser() {
        mockKeyMaker.mainKeyStub.bodyIs { _, _ in
            NoneProtection.generateRandomValue(length: 32)
        }
        testContainer.usersManager.add(newUser: UserManager(api: APIServiceMock()))
    }
}
