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

import Combine
@testable import ProtonMail
import ProtonCoreDataModel
import ProtonCoreKeymaker
import ProtonCoreTestingToolkitUnitTestsServices
import XCTest

final class AppAccessResolverTests: XCTestCase {
    private var sut: AppAccessResolver!
    private var apiMock: APIServiceMock!
    private var mockKeyMaker: MockKeyMakerProtocol!
    private var lockPreventor: LockPreventor!
    private var testContainer: TestContainer!
    private var cancellables: Set<AnyCancellable>!

    private let userID = String.randomString(10)

    override func setUp() {
        super.setUp()

        testContainer = .init()

        mockKeyMaker = .init()
        lockPreventor = .init()
        apiMock = .init()

        testContainer.keyMakerFactory.register { self.mockKeyMaker }
        testContainer.lockPreventorFactory.register { self.lockPreventor }

        mockKeyMaker.mainKeyStub.bodyIs { _, _ in
            RandomPinProtection.generateRandomValue(length: 32)
        }

        sut = AppAccessResolver(dependencies: testContainer)
        cancellables = []
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        apiMock = nil
        mockKeyMaker = nil
        lockPreventor = nil
        testContainer = nil
        cancellables = nil
    }

    // MARK: evaluateAppAccessAtLaunch

    func testEvaluateAppAccessAtLaunch_whenThereAreUsersAndAppIsUnlocked_returnsAccessGranted() {
        testContainer.usersManager.add(newUser: .init(api: apiMock, userID: userID))
        mockKeyMaker.isMainKeyInMemory = true

        let result = sut.evaluateAppAccessAtLaunch()
        XCTAssertEqual(result, .accessGranted)
    }

    func testEvaluateAppAccessAtLaunch_whenThereAreUsersAndAppIsLocked_returnsAccessDeniedLock() {
        testContainer.usersManager.add(newUser: .init(api: apiMock, userID: userID))
        mockKeyMaker.isMainKeyInMemory = false

        let result = sut.evaluateAppAccessAtLaunch()
        XCTAssertEqual(result, .accessDenied(reason: .lockProtectionRequired))
    }

    func testEvaluateAppAccessAtLaunch_whenThereAreNoUsers_andNoMainKey_returnsAccessDeniedNoAccounts() {
        mockKeyMaker.isMainKeyInMemory = false
        let result = sut.evaluateAppAccessAtLaunch()
        XCTAssertEqual(result, .accessDenied(reason: .noAuthenticatedAccountFound))
    }

    func testEvaluateAppAccessAtLaunch_whenThereAreNoUsers_butThereIsMainKey_returnsAccessDeniedNoAccounts() {
        mockKeyMaker.isMainKeyInMemory = true
        let result = sut.evaluateAppAccessAtLaunch()
        XCTAssertEqual(result, .accessDenied(reason: .noAuthenticatedAccountFound))
    }

    // MARK: deniedAccessPublisher

    func testDeniedAccessPublisher_whenReceivedOneMainKeyNotification_sendsOneEvent() {
        let expectation = expectation(description: "Event is received")
        sut.deniedAccessPublisher.sink { _ in
            expectation.fulfill()
        }.store(in: &cancellables)

        testContainer.notificationCenter.post(name: Keymaker.Const.removedMainKeyFromMemory, object: nil)
        wait(for: [expectation], timeout: 2.0)
    }

    func testDeniedAccessPublisher_whenReceivedMultipleMainKeyNotificationInShortInterval_sendsTwoEvents() {
        let expectation1 = expectation(description: "2 events received")
        sut.deniedAccessPublisher.collect(2).sink { _ in
            expectation1.fulfill()
        }.store(in: &cancellables)

        let expectation2 = expectation(description: "4 events received (inverted)")
        expectation2.isInverted = true
        sut.deniedAccessPublisher.collect(4).sink { _ in
            expectation2.fulfill()
        }.store(in: &cancellables)

        testContainer.notificationCenter.post(name: Keymaker.Const.removedMainKeyFromMemory, object: nil)
        testContainer.notificationCenter.post(name: Keymaker.Const.removedMainKeyFromMemory, object: nil)
        testContainer.notificationCenter.post(name: Keymaker.Const.removedMainKeyFromMemory, object: nil)
        testContainer.notificationCenter.post(name: Keymaker.Const.removedMainKeyFromMemory, object: nil)
        wait(for: [expectation1, expectation2], timeout: 2.0)
    }

    func testDeniedAccessPublisher_whenMainKeyNotification_andThereAreUsers_sendsDeniedAccess() {
        testContainer.usersManager.add(newUser: .init(api: apiMock, userID: userID))

        let expectation = expectation(description: "Receives denied access event")

        sut.deniedAccessPublisher.sink { deniedAccess in
            if case .lockProtectionRequired = deniedAccess {
                XCTAssert(true)
                expectation.fulfill()
            } else {
                XCTFail()
            }
        }.store(in: &cancellables)

        testContainer.notificationCenter.post(name: Keymaker.Const.removedMainKeyFromMemory, object: nil)
        wait(for: [expectation], timeout: 2.0)
    }

    func testDeniedAccessPublisher_whenMainKeyNotificationUsingLockPreventor_andThereAreUsers_doesNotSendAnEvent() {
        testContainer.usersManager.add(newUser: .init(api: apiMock, userID: userID))

        let expectation = expectation(description: "Receives an event (inverted)")
        expectation.isInverted = true

        sut.deniedAccessPublisher.sink { deniedAccess in
            expectation.fulfill()
        }.store(in: &cancellables)

        lockPreventor.performWhileSuppressingLock {
            testContainer.notificationCenter.post(name: Keymaker.Const.removedMainKeyFromMemory, object: nil)
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testDeniedAccessPublisher_whenMainKeyNotification_butThereAreNoUsers_sendsNoUsers() {
        let expectation = expectation(description: "Receives no user event")

        sut.deniedAccessPublisher.sink { deniedAccess in
            if case .noAuthenticatedAccountFound = deniedAccess {
                XCTAssert(true)
                expectation.fulfill()
            } else {
                XCTFail()
            }
        }.store(in: &cancellables)

        testContainer.notificationCenter.post(name: Keymaker.Const.removedMainKeyFromMemory, object: nil)
        wait(for: [expectation], timeout: 2.0)
    }
}
