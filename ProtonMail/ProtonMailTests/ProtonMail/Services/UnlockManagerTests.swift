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
@testable import ProtonMail
import XCTest

final class UnlockManagerTests: XCTestCase {
    var sut: UnlockManager!
    var delegateMock: MockUnlockManagerDelegate!
    var cacheMock: MockLockCacheStatus!
    var keyMakerMock: MockKeyMakerProtocol!
    var LAContextMock: MockLAContextProtocol!
    var notificationCenter: NotificationCenter!
    var pinFailedCountCacheMock: MockPinFailedCountCache!

    override func setUp() {
        super.setUp()
        delegateMock = .init()
        cacheMock = .init()
        keyMakerMock = .init()
        LAContextMock = .init()
        notificationCenter = .init()
        pinFailedCountCacheMock = .init()
        sut = .init(
            cacheStatus: cacheMock,
            keyMaker: keyMakerMock,
            pinFailedCountCache: pinFailedCountCacheMock,
            localAuthenticationContext: LAContextMock,
            notificationCenter: notificationCenter
        )
        sut.delegate = delegateMock
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        delegateMock = nil
        cacheMock = nil
        keyMakerMock = nil
        LAContextMock = nil
        notificationCenter = nil
        pinFailedCountCacheMock = nil
    }

    func testIsUnlocked_mainKeyIsNil_returnFalse() {
        keyMakerMock.mainKeyStub.bodyIs { _, _ in
            nil
        }

        XCTAssertFalse(sut.isUnlocked())
        XCTAssertTrue(keyMakerMock.lockTheAppStub.wasCalledExactlyOnce)
    }

    func testIsUnlocked_mainKeyIsNotNil_returnTrue() {
        keyMakerMock.mainKeyStub.bodyIs { _, _ in
            []
        }

        XCTAssertTrue(sut.isUnlocked())
        XCTAssertFalse(keyMakerMock.lockTheAppStub.wasCalled)
    }

    func testGetUnlockFlow_PinEnableInCache_returnRequirePin() {
        cacheMock.isPinCodeEnabledStub.fixture = true

        XCTAssertEqual(sut.getUnlockFlow(), .requirePin)
    }

    func testGetUnlockFlow_TouchIDEnableInCache_returnRequirePin() {
        cacheMock.isTouchIDEnabledStub.fixture = true

        XCTAssertEqual(sut.getUnlockFlow(), .requireTouchID)
    }

    func testGetUnlockFlow_PinAndTouchIDAreDisableInCache_returnRestore() {
        cacheMock.isPinCodeEnabledStub.fixture = false
        cacheMock.isTouchIDEnabledStub.fixture = false

        XCTAssertEqual(sut.getUnlockFlow(), .restore)
    }

    func testGetUnlockFlow_PinAndTouchIDAreEnableInCache_returnTouchID() {
        cacheMock.isPinCodeEnabledStub.fixture = true
        cacheMock.isTouchIDEnabledStub.fixture = true
        keyMakerMock.deactivateStub.bodyIs { _, strategy in
            self.cacheMock.isPinCodeEnabledStub.fixture = false
            XCTAssertTrue(strategy is PinProtection)
            return false
        }

        XCTAssertEqual(sut.getUnlockFlow(), .requireTouchID)
    }

    func testMatch_pinIsEmpty_returnFalse() {
        let e = expectation(description: "Closure is called")
        pinFailedCountCacheMock.pinFailedCountStub.fixture = 0

        sut.match(userInputPin: .empty) { result in
            XCTAssertFalse(result)
            e.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertEqual(pinFailedCountCacheMock.pinFailedCountStub.setLastArguments?.value, 1)
    }

    func testMatch_pinIsMatch_returnTrue() {
        let e = expectation(description: "Closure is called")
        pinFailedCountCacheMock.pinFailedCountStub.fixture = 0
        keyMakerMock.obtainMainKeyStub.bodyIs { _, strategy, _, completion in
            XCTAssertTrue(strategy is PinProtection)
            completion([])
        }

        sut.match(userInputPin: String.randomString(10)) { result in
            XCTAssertTrue(result)
            e.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertEqual(pinFailedCountCacheMock.pinFailedCountStub.setLastArguments?.value, 0)
    }

    func testMatch_pinIsNotMatch_returnFalse() {
        let e = expectation(description: "Closure is called")
        pinFailedCountCacheMock.pinFailedCountStub.fixture = 0
        keyMakerMock.obtainMainKeyStub.bodyIs { _, strategy, _, completion in
            XCTAssertTrue(strategy is PinProtection)
            completion(nil)
        }

        sut.match(userInputPin: String.randomString(10)) { result in
            XCTAssertFalse(result)
            e.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertTrue(keyMakerMock.lockTheAppStub.wasCalledExactlyOnce)
    }

    func testBiometricAuthentication_CanEvaluatePolicy_AndMainKeyReturn_closureIsCalled() {
        let e = expectation(description: "Closure is called")
        LAContextMock.canEvaluatePolicyStub.bodyIs { _, _, _ in
            return true
        }
        keyMakerMock.obtainMainKeyStub.bodyIs { _, strategy, _, completion in
            XCTAssertTrue(strategy is BioProtection)
            completion([])
        }

        sut.biometricAuthentication(afterBioAuthPassed: {
            e.fulfill()
        })

        waitForExpectations(timeout: 1)
    }

    func testBiometricAuthentication_CanEvaluatePolicy_AndMainKeyIsNill_closureIsNotCalled() {
        let e = expectation(description: "Closure is called")
        e.isInverted = true
        LAContextMock.canEvaluatePolicyStub.bodyIs { _, _, _ in
            return true
        }
        keyMakerMock.obtainMainKeyStub.bodyIs { _, strategy, _, completion in
            XCTAssertTrue(strategy is BioProtection)
            completion(nil)
        }

        sut.biometricAuthentication(afterBioAuthPassed: {
            e.fulfill()
        })

        waitForExpectations(timeout: 1)
    }

    func testUnlockIfRememberedCredentials_MainKeyNotExisted_UnlockFailedIsCalled() {
        let e = expectation(description: "Closure is called")
        keyMakerMock.mainKeyExistsStub.bodyIs { _ in
            return false
        }
        delegateMock.cleanAllStub.bodyIs { _, completion in
            completion()
        }

        sut.unlockIfRememberedCredentials(
            requestMailboxPassword: { XCTFail("Should not reach here") },
            unlockFailed: {
                e.fulfill()
            },
            unlocked: { XCTFail("Should not reach here") }
        )

        waitForExpectations(timeout: 1)

        XCTAssertTrue(delegateMock.setupCoreDataStub.wasCalledExactlyOnce)
        XCTAssertTrue(delegateMock.cleanAllStub.wasCalledExactlyOnce)
    }

    func testUnlockIfRemberedCredentials_MainKeyExist_UserNotStored_UnlockFailedIsCalled() {
        let e = expectation(description: "Closure is called")
        keyMakerMock.mainKeyExistsStub.bodyIs { _ in
            return true
        }
        delegateMock.cleanAllStub.bodyIs { _, completion in
            completion()
        }
        delegateMock.isUserStoredStub.bodyIs { _ in
            return false
        }

        sut.unlockIfRememberedCredentials(
            requestMailboxPassword: { XCTFail("Should not reach here") },
            unlockFailed: {
                e.fulfill()
            },
            unlocked: { XCTFail("Should not reach here") }
        )

        waitForExpectations(timeout: 1)

        XCTAssertTrue(delegateMock.setupCoreDataStub.wasCalledExactlyOnce)
        XCTAssertTrue(delegateMock.cleanAllStub.wasCalledExactlyOnce)
    }

    func testUnlockIfRemberedCredentials_MainKeyExist_UserIsStored_mailboxPWDNotStored_requestMailboxPWDIsCalled() {
        let e = expectation(description: "Closure is called")
        keyMakerMock.mainKeyExistsStub.bodyIs { _ in
            return true
        }
        delegateMock.isUserStoredStub.bodyIs { _ in
            return true
        }
        delegateMock.isMailboxPasswordStoredStub.bodyIs { _, _ in
            return false
        }

        sut.unlockIfRememberedCredentials(
            requestMailboxPassword: { e.fulfill() },
            unlockFailed: { XCTFail("Should not reach here") },
            unlocked: { XCTFail("Should not reach here") }
        )

        waitForExpectations(timeout: 1)

        XCTAssertTrue(delegateMock.setupCoreDataStub.wasCalledExactlyOnce)
    }

    func testUnlockIfRemberedCredentials_MainKeyExist_UserIsStored_mailboxPWDStored_unlockIsCalled() {
        let e = expectation(description: "Closure is called")
        expectation(
            forNotification: .didUnlock,
            object: nil,
            notificationCenter: notificationCenter
        )
        keyMakerMock.mainKeyExistsStub.bodyIs { _ in
            return true
        }
        delegateMock.isUserStoredStub.bodyIs { _ in
            return true
        }
        delegateMock.isMailboxPasswordStoredStub.bodyIs { _, _ in
            return true
        }

        sut.unlockIfRememberedCredentials(
            requestMailboxPassword: { XCTFail("Should not reach here") },
            unlockFailed: { XCTFail("Should not reach here") },
            unlocked: { e.fulfill() }
        )

        waitForExpectations(timeout: 1)

        XCTAssertTrue(delegateMock.setupCoreDataStub.wasCalledExactlyOnce)
        XCTAssertEqual(pinFailedCountCacheMock.pinFailedCountStub.setLastArguments?.value, 0)
        XCTAssertTrue(delegateMock.loadUserDataAfterUnlockStub.wasCalledExactlyOnce)
    }

    func testUnlockIfRemberedCredentials_MainKeyExist_UserIsStored_mailboxPWDStored_TouchIDEnabled_unlockIsCalled() {
        let e = expectation(description: "Closure is called")
        let notiExpectation = expectation(
            forNotification: .didUnlock,
            object: nil,
            notificationCenter: notificationCenter
        )
        keyMakerMock.mainKeyExistsStub.bodyIs { _ in
            return true
        }
        delegateMock.isUserStoredStub.bodyIs { _ in
            return true
        }
        delegateMock.isMailboxPasswordStoredStub.bodyIs { _, _ in
            return true
        }
        cacheMock.isTouchIDEnabledStub.fixture = true

        sut.unlockIfRememberedCredentials(
            requestMailboxPassword: { XCTFail("Should not reach here") },
            unlockFailed: { XCTFail("Should not reach here") },
            unlocked: { e.fulfill() }
        )

        waitForExpectations(timeout: 1)

        XCTAssertTrue(delegateMock.setupCoreDataStub.wasCalledExactlyOnce)
        XCTAssertEqual(pinFailedCountCacheMock.pinFailedCountStub.setLastArguments?.value, 0)
        XCTAssertTrue(delegateMock.loadUserDataAfterUnlockStub.wasCalledExactlyOnce)
    }

    func testUnlockIfRemberedCredentials_MainKeyExist_UserIsStored_mailboxPWDStored_PinEnabled_unlockIsCalled() {
        let e = expectation(description: "Closure is called")
        let notiExpectation = expectation(
            forNotification: .didUnlock,
            object: nil,
            notificationCenter: notificationCenter
        )
        keyMakerMock.mainKeyExistsStub.bodyIs { _ in
            return true
        }
        delegateMock.isUserStoredStub.bodyIs { _ in
            return true
        }
        delegateMock.isMailboxPasswordStoredStub.bodyIs { _, _ in
            return true
        }
        cacheMock.isPinCodeEnabledStub.fixture = true

        sut.unlockIfRememberedCredentials(
            requestMailboxPassword: { XCTFail("Should not reach here") },
            unlockFailed: { XCTFail("Should not reach here") },
            unlocked: { e.fulfill() }
        )

        waitForExpectations(timeout: 1)

        XCTAssertTrue(delegateMock.setupCoreDataStub.wasCalledExactlyOnce)
        XCTAssertEqual(pinFailedCountCacheMock.pinFailedCountStub.setLastArguments?.value, 0)
        XCTAssertTrue(delegateMock.loadUserDataAfterUnlockStub.wasCalledExactlyOnce)
    }

    func testInitiateUnlock_isAppLockedAndAppKeyDisabledIsTrue_mailboxPWDIsNotStored_requirePinProtection_requestMailboxPWDIsCalled() {
        let e = expectation(description: "Closure is called")
        keyMakerMock.mainKeyExistsStub.bodyIs { _ in
            return true
        }
        delegateMock.isUserStoredStub.bodyIs { _ in
            return true
        }
        delegateMock.isMailboxPasswordStoredStub.bodyIs { _, _ in
            return false
        }
        cacheMock.isAppLockedAndAppKeyDisabledStub.fixture = true

        sut.initiateUnlock(
            flow: .requireTouchID,
            requestPin: { XCTFail("Should not reach here") },
            requestMailboxPassword: {
                e.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
        XCTAssertTrue(delegateMock.setupCoreDataStub.wasCalledExactlyOnce)
    }

    func testInitiateUnlock_requirePin_requestPinClosureIsCalled() {
        let e = expectation(description: "Closure is called")

        sut.initiateUnlock(
            flow: .requirePin,
            requestPin: { e.fulfill() },
            requestMailboxPassword: { XCTFail("Should not reach here") })

        waitForExpectations(timeout: 1)
    }

    func testInitiateUnlock_requireTouchID_mailboxPWDIsNotStored_requestMainboxIsCalled() {
        let e = expectation(description: "Closure is called")
        LAContextMock.canEvaluatePolicyStub.bodyIs { _, _, _ in
            return true
        }
        keyMakerMock.obtainMainKeyStub.bodyIs { _, strategy, _, completion in
            XCTAssertTrue(strategy is BioProtection)
            completion([])
        }
        keyMakerMock.mainKeyExistsStub.bodyIs { _ in
            return true
        }
        delegateMock.isUserStoredStub.bodyIs { _ in
            return true
        }
        delegateMock.isMailboxPasswordStoredStub.bodyIs { _, _ in
            return false
        }

        sut.initiateUnlock(
            flow: .requireTouchID,
            requestPin: { XCTFail("Should not reach here") },
            requestMailboxPassword: { e.fulfill() }
        )

        waitForExpectations(timeout: 1)

        XCTAssertTrue(delegateMock.setupCoreDataStub.wasCalledExactlyOnce)
    }

    func testInitiateUnlock_requireTouchID_mailboxPWDIsStored_unlockNotificationIsSent() {
        LAContextMock.canEvaluatePolicyStub.bodyIs { _, _, _ in
            return true
        }
        keyMakerMock.obtainMainKeyStub.bodyIs { _, strategy, _, completion in
            XCTAssertTrue(strategy is BioProtection)
            completion([])
        }
        keyMakerMock.mainKeyExistsStub.bodyIs { _ in
            return true
        }
        delegateMock.isUserStoredStub.bodyIs { _ in
            return true
        }
        delegateMock.isMailboxPasswordStoredStub.bodyIs { _, _ in
            return true
        }
        expectation(
            forNotification: .didUnlock,
            object: nil,
            notificationCenter: notificationCenter
        )

        sut.initiateUnlock(
            flow: .requireTouchID,
            requestPin: { XCTFail("Should not reach here") },
            requestMailboxPassword: { XCTFail("Should not reach here") }
        )

        waitForExpectations(timeout: 1)
        XCTAssertTrue(delegateMock.setupCoreDataStub.wasCalledExactlyOnce)
        XCTAssertTrue(delegateMock.loadUserDataAfterUnlockStub.wasCalledExactlyOnce)
    }

    func testInitiateUnlock_restore_mailboxPWDIsNotStored_requestMailboxIsCalled() {
        let e = expectation(description: "Closure is called")
        keyMakerMock.mainKeyExistsStub.bodyIs { _ in
            return true
        }
        delegateMock.isUserStoredStub.bodyIs { _ in
            return true
        }
        delegateMock.isMailboxPasswordStoredStub.bodyIs { _, _ in
            return false
        }

        sut.initiateUnlock(
            flow: .restore,
            requestPin: { XCTFail("Should not reach here") },
            requestMailboxPassword: { e.fulfill() }
        )

        waitForExpectations(timeout: 1)
        XCTAssertTrue(delegateMock.setupCoreDataStub.wasCalledExactlyOnce)
    }

    func testInitiateUnlock_restore_mainKeyNotExist_signOutNotificationIsSent() {
        keyMakerMock.mainKeyExistsStub.bodyIs { _ in
            return false
        }
        delegateMock.isUserStoredStub.bodyIs { _ in
            return true
        }
        delegateMock.cleanAllStub.bodyIs { _, completion in
            completion()
        }
        expectation(
            forNotification: .didSignOutLastAccount,
            object: nil,
            notificationCenter: notificationCenter
        )

        sut.initiateUnlock(
            flow: .restore,
            requestPin: { XCTFail("Should not reach here") },
            requestMailboxPassword: { XCTFail("Should not reach here") }
        )

        waitForExpectations(timeout: 1)
        XCTAssertTrue(delegateMock.setupCoreDataStub.wasCalledExactlyOnce)
    }
}
