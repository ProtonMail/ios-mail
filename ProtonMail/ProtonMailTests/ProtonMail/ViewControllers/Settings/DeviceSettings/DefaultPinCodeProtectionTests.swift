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

final class DefaultPinCodeProtectionTests: XCTestCase {
    private var sut: DefaultPinCodeProtection!
    private var globalContainer: TestContainer!

    private var keyChain: Keychain {
        globalContainer.keychain
    }

    private var keyMaker: KeyMakerProtocol {
        globalContainer.keyMaker
    }

    private var notificationCenter: NotificationCenter {
        globalContainer.notificationCenter
    }

    override func setUpWithError() throws {
        globalContainer = .init()

        sut = DefaultPinCodeProtection(dependencies: globalContainer)
    }

    override func tearDownWithError() throws {
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

        do {
            try await keyMaker.verify(protector: PinProtection(pin: "1111", keychain: keyChain))
            XCTFail("verify wrong PIN should throw an exception")
        } catch {}

        do {
            try await keyMaker.verify(protector: PinProtection(pin: newPinCode, keychain: keyChain))
        } catch {
            XCTFail("verify right PIN should not throw an exception")
        }
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
        XCTAssertNil(globalContainer.keychain[.keymakerRandomKey])
        XCTAssertFalse(keyMaker.isPinCodeEnabled)
    }
}
