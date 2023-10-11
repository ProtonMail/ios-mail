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
import ProtonCoreTestingToolkit
import XCTest

final class AppAccessResolverTests: XCTestCase {
    private var sut: AppAccessResolver!
    private var notificationCenter: NotificationCenter!
    private var mockUsersManager: MockUsersManagerProtocol!
    private var mockKeyMaker: MockKeyMakerProtocol!
    private var lockPreventor: LockPreventor!
    private var globalContainer: GlobalContainer!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        notificationCenter = .init()
        mockKeyMaker = .init()
        lockPreventor = .init()
        mockUsersManager = .init()

        globalContainer = .init()
        globalContainer.notificationCenterFactory.register { self.notificationCenter }
        globalContainer.keyMakerFactory.register { self.mockKeyMaker }
        globalContainer.usersManagerProtocolFactory.register { self.mockUsersManager }
        globalContainer.lockCacheStatusFactory.register { CacheStatusStub() }
        globalContainer.lockPreventorFactory.register { self.lockPreventor }

        sut = AppAccessResolver(dependencies: globalContainer)
        cancellables = []
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        notificationCenter = nil
        mockUsersManager = nil
        mockKeyMaker = nil
        lockPreventor = nil
        globalContainer = nil
        cancellables = nil
    }

    // MARK: evaluateAppAccessAtLaunch

    func testEvaluateAppAccessAtLaunch_whenThereAreUsersAndAppIsUnlocked_returnsAccessGranted() {
        mockUsersManager.hasUsersStub.bodyIs { _ in true }
        mockKeyMaker.isMainKeyInMemory = true

        let result = sut.evaluateAppAccessAtLaunch()
        XCTAssertTrue(result.isAccessGranted)
    }

    func testEvaluateAppAccessAtLaunch_whenThereAreUsersAndAppIsLocked_returnsAccessDeniedLock() {
        mockUsersManager.hasUsersStub.bodyIs { _ in true }
        mockKeyMaker.isMainKeyInMemory = false

        let result = sut.evaluateAppAccessAtLaunch()
        XCTAssertFalse(result.isAccessGranted)
        XCTAssertTrue(result.iDeniedAccessReasonLock)
    }

    func testEvaluateAppAccessAtLaunch_whenThereAreNoUsers_andNoMainKey_returnsAccessDeniedNoAccounts() {
        mockUsersManager.hasUsersStub.bodyIs { _ in false }
        mockKeyMaker.isMainKeyInMemory = false
        let result = sut.evaluateAppAccessAtLaunch()
        XCTAssertFalse(result.isAccessGranted)
        XCTAssertTrue(result.isDeniedAccessReasonNoAccounts)
    }

    func testEvaluateAppAccessAtLaunch_whenThereAreNoUsers_butThereIsMainKey_returnsAccessDeniedNoAccounts() {
        mockUsersManager.hasUsersStub.bodyIs { _ in false }
        mockKeyMaker.isMainKeyInMemory = true
        let result = sut.evaluateAppAccessAtLaunch()
        XCTAssertFalse(result.isAccessGranted)
        XCTAssertTrue(result.isDeniedAccessReasonNoAccounts)
    }

    // MARK: deniedAccessPublisher

    func testDeniedAccessPublisher_whenReceivedOneMainKeyNotification_sendsOneEvent() {
        let expectation = expectation(description: "Event is received")
        sut.deniedAccessPublisher.sink { _ in
            expectation.fulfill()
        }.store(in: &cancellables)

        notificationCenter.post(name: Keymaker.Const.removedMainKeyFromMemory, object: nil)
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

        notificationCenter.post(name: Keymaker.Const.removedMainKeyFromMemory, object: nil)
        notificationCenter.post(name: Keymaker.Const.removedMainKeyFromMemory, object: nil)
        notificationCenter.post(name: Keymaker.Const.removedMainKeyFromMemory, object: nil)
        notificationCenter.post(name: Keymaker.Const.removedMainKeyFromMemory, object: nil)
        wait(for: [expectation1, expectation2], timeout: 2.0)
    }

    func testDeniedAccessPublisher_whenMainKeyNotification_andThereAreUsers_sendsDeniedAccess() {
        mockUsersManager.hasUsersStub.bodyIs { _ in true }

        let expectation = expectation(description: "Receives denied access event")

        sut.deniedAccessPublisher.sink { deniedAccess in
            if case .lockProtectionRequired = deniedAccess {
                XCTAssert(true)
                expectation.fulfill()
            } else {
                XCTFail()
            }
        }.store(in: &cancellables)

        notificationCenter.post(name: Keymaker.Const.removedMainKeyFromMemory, object: nil)
        wait(for: [expectation], timeout: 2.0)
    }

    func testDeniedAccessPublisher_whenMainKeyNotificationUsingLockPreventor_andThereAreUsers_doesNotSendAnEvent() {
        mockUsersManager.hasUsersStub.bodyIs { _ in true }

        let expectation = expectation(description: "Receives an event (inverted)")
        expectation.isInverted = true

        sut.deniedAccessPublisher.sink { deniedAccess in
            expectation.fulfill()
        }.store(in: &cancellables)

        lockPreventor.performWhileSuppressingLock {
            notificationCenter.post(name: Keymaker.Const.removedMainKeyFromMemory, object: nil)
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testDeniedAccessPublisher_whenMainKeyNotification_butThereAreNoUsers_sendsNoUsers() {
        mockUsersManager.hasUsersStub.bodyIs { _ in false }

        let expectation = expectation(description: "Receives no user event")

        sut.deniedAccessPublisher.sink { deniedAccess in
            if case .noAuthenticatedAccountFound = deniedAccess {
                XCTAssert(true)
                expectation.fulfill()
            } else {
                XCTFail()
            }
        }.store(in: &cancellables)

        notificationCenter.post(name: Keymaker.Const.removedMainKeyFromMemory, object: nil)
        wait(for: [expectation], timeout: 2.0)
    }
}

private extension AppAccess {

    var iDeniedAccessReasonLock: Bool {
        if case .accessDenied(let reason) = self {
            return reason == .lockProtectionRequired
        }
        return false
    }

    var isDeniedAccessReasonNoAccounts: Bool {
        if case .accessDenied(let reason) = self {
            return reason == .noAuthenticatedAccountFound
        }
        return false
    }
}
