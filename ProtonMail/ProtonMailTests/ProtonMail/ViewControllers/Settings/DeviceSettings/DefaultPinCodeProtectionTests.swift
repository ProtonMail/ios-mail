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
@testable import ProtonMail
import XCTest

final class DefaultPinCodeProtectionTests: XCTestCase {
    private var sut: DefaultPinCodeProtection!
    private var keyMaker: Keymaker!
    private var keyChain: KeychainWrapper!
    private var notificationCenter: NotificationCenter!
    private var globalContainer: GlobalContainer!

    override func setUpWithError() throws {
        let userCachedStatus = UserCachedStatus(userDefaults: UserDefaults(suiteName: "ch.protonmail.test")!)
        keyChain = KeychainWrapper(
            service: "ch.protonmail.test.\(String.randomString(7))",
            accessGroup: "2SB5Z68H26.ch.protonmail.protonmail"
        )
        keyMaker = Keymaker(
            autolocker: Autolocker(lockTimeProvider: userCachedStatus),
            keychain: keyChain
        )
        notificationCenter = NotificationCenter()

        globalContainer = .init()
        globalContainer.keyMakerFactory.register { self.keyMaker }
        globalContainer.keychainFactory.register { self.keyChain }
        globalContainer.notificationCenterFactory.register { self.notificationCenter }
        globalContainer.userCachedStatusFactory.register { userCachedStatus }

        sut = DefaultPinCodeProtection(dependencies: globalContainer)
    }

    override func tearDownWithError() throws {
        keyChain = nil
        keyMaker = nil
        notificationCenter = nil
        globalContainer = nil
        sut = nil
    }

    func testActivate_itShouldStoreTheMainKey() async throws {
        let newPinCode = "89124"
        let lockNotificationExpectation = XCTNSNotificationExpectation(
            name: .appLockProtectionEnabled,
            object: nil,
            notificationCenter: notificationCenter
        )
        let appKeyNotificationExpectation = XCTNSNotificationExpectation(
            name: .appKeyDisabled,
            object: nil,
            notificationCenter: notificationCenter
        )

        let isActivated = await sut.activate(with: newPinCode)
        XCTAssertTrue(isActivated)
        wait(for: [lockNotificationExpectation, appKeyNotificationExpectation], timeout: 5)

        let wrongPingExpectation = expectation(description: "Wrong pin")
        keyMaker.obtainMainKey(with: PinProtection(pin: "1111"), returnExistingKey: false) { key in
            XCTAssertNil(key)
            wrongPingExpectation.fulfill()
        }
        let rightPinExpectation = expectation(description: "Right pin")
        let protection = PinProtection(pin: newPinCode, keychain: keyChain)
        keyMaker.obtainMainKey(with: protection, returnExistingKey: false) { key in
            XCTAssertNotNil(key)
            rightPinExpectation.fulfill()
        }
        wait(for: [wrongPingExpectation, rightPinExpectation], timeout: 5)
    }

    func testDeactivate_itShouldDeleteRandomPinProtectionKeyAndDisablePinCode() async {
        let newPinCode = "2345"
        let isActivated = await sut.activate(with: newPinCode)
        XCTAssertTrue(isActivated)
        XCTAssertTrue(keyMaker.isPinCodeEnabled)

        let appKeyDisabledExpectation = XCTNSNotificationExpectation(
            name: .appLockProtectionDisabled,
            object: nil,
            notificationCenter: notificationCenter
        )
        sut.deactivate()
        wait(for: [appKeyDisabledExpectation], timeout: 5)
        XCTAssertNil(userCachedStatus.keymakerRandomkey)
        XCTAssertFalse(keyMaker.isPinCodeEnabled)
    }
}
