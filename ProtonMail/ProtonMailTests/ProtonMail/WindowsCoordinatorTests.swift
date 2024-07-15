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
import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail
import XCTest

final class WindowsCoordinatorTests: XCTestCase {
    private var sut: WindowsCoordinator!
    private var testContainer: TestContainer!
    private var mockKeyMaker: MockKeyMakerProtocol!
    private var mockSetupCoreData: MockSetupCoreDataService!
    private var mockLaunchService: MockLaunchService!

    override func setUp() {
        super.setUp()

        testContainer = .init()
        mockKeyMaker = .init()
        mockSetupCoreData = .init()
        mockLaunchService = .init()

        testContainer.keyMakerFactory.register { self.mockKeyMaker }
        testContainer.setupCoreDataServiceFactory.register { self.mockSetupCoreData }
        testContainer.launchServiceFactory.register { self.mockLaunchService }

        sut = .init(dependencies: testContainer, showPlaceHolderViewOnly: false)
    }

    override func tearDown() {
        super.tearDown()

        testContainer = nil
        mockKeyMaker = nil
        mockSetupCoreData = nil
        mockLaunchService = nil
        sut = nil
    }

    func testInit_defaultWindowIsPlaceHolder() {
        sut = .init(dependencies: testContainer)
        XCTAssertTrue(sut.appWindow.rootViewController is PlaceholderViewController)
    }

    // MARK: start method

    //  launch service is called

    func testStart_whenAppAccessIsGranted_itShouldCallLaunchStart() {
        setUpAppAccessGranted()

        executeStartAndWaitCompletion()

        XCTAssertTrue(mockLaunchService.startStub.wasCalledExactlyOnce)
    }

    func testStart_whenAppAccessIsDenied_itShouldCallLaunchStart() {
        setUpAppAccessDeniedReasonAppLock()

        mockKeyMaker.isTouchIDEnabledStub.fixture = true
        executeStartAndWaitCompletion()

        XCTAssertTrue(mockLaunchService.startStub.wasCalledExactlyOnce)
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

        mockKeyMaker.isTouchIDEnabledStub.fixture = true
        simulateAppLockedByUserAction()

        // To wait navigate(from:...) closure 
        wait(self.sut.currentWindow?.rootViewController?.presentedViewController != nil, timeout: 5)
    }
}

extension WindowsCoordinatorTests {

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
