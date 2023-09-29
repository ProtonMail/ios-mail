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

final class PinCodeSetupVMTests: XCTestCase {
    private var sut: PinCodeSetupViewModel!
    private var keyMaker: Keymaker!
    private var keyChain: KeychainWrapper!
    private var notificationCenter: NotificationCenter!
    private var userCachedStatus: UserCachedStatus!
    private var globalContainer: GlobalContainer!
    private var router: MockPinCodeSetupRouterProtocol!

    override func setUpWithError() throws {
        router = MockPinCodeSetupRouterProtocol()
        userCachedStatus = UserCachedStatus(userDefaults: UserDefaults(suiteName: "ch.protonmail.test")!)
        keyChain = KeychainWrapper(
            service: "ch.protonmail.test",
            accessGroup: "2SB5Z68H26.ch.protonmail.protonmail"
        )
        keyMaker = Keymaker(
            autolocker: Autolocker(lockTimeProvider: userCachedStatus),
            keychain: keyChain
        )
        notificationCenter = NotificationCenter()

        globalContainer = .init()
        globalContainer.keyMakerFactory.register { self.keyMaker }
        globalContainer.notificationCenterFactory.register { self.notificationCenter }
        globalContainer.userCachedStatusFactory.register { self.userCachedStatus }
        sut = PinCodeSetupViewModel(
            dependencies: globalContainer,
            router: router
        )
    }

    override func tearDownWithError() throws {
        router = nil
        userCachedStatus = nil
        keyChain = nil
        keyMaker = nil
        notificationCenter = nil
        globalContainer = nil
        sut = nil
    }

    func testActivatePinCodeProtection() async throws {
        sut.set(newPinCode: "1234")
        let lockEnabledEX = XCTNSNotificationExpectation(
            name: .appLockProtectionEnabled,
            object: nil,
            notificationCenter: notificationCenter
        )
        let appKeyDisabled = XCTNSNotificationExpectation(
            name: .appKeyDisabled,
            object: nil,
            notificationCenter: notificationCenter
        )
        let isActivated = await sut.activatePinCodeProtection()
        XCTAssertTrue(isActivated)
        wait(for: [lockEnabledEX, appKeyDisabled], timeout: 5)

        do {
            try await keyMaker.verify(protector: PinProtection(pin: "1111"))
            XCTFail("Wrong pin shouldn't success")
        } catch { }
        try await keyMaker.verify(protector: PinProtection(pin: "1234"))
    }

    func testGoTo() {
        let steps: [PinCodeSetupRouter.PinCodeSetUpStep] = [.confirmBeforeChanging, .enterNewPinCode, .repeatPinCode]
        let ex = expectation(description: "function is called")
        ex.expectedFulfillmentCount = 3
        router.goStub.bodyIs { time, step, _ in
            XCTAssertEqual(steps[Int(time - 1)], step)
            ex.fulfill()
        }

        for step in steps {
            sut.go(to: step)
        }
        wait(for: [ex], timeout: 5)
    }

    func testIsCorrectCurrentPinCode() async {
        let activateEX = expectation(description: "Activate pin")
        keyMaker.activate(PinProtection(pin: "1234")) { _ in
            activateEX.fulfill()
        }

        wait(for: [activateEX], timeout: 5)

        do {
            try await sut.isCorrectCurrentPinCode("5555")
        } catch {
            XCTAssertEqual(error as? PinCodeSetupViewModel.Error, .wrongPinCode)
        }

        do {
            try await sut.isCorrectCurrentPinCode("1234")
        } catch {
            XCTFail("Shouldn't fail")
        }
    }

    func testIsNewPinCodeMatch() {
        sut.set(newPinCode: "1234")
        do {
            try sut.isNewPinCodeMatch(repeatPinCode: "4444")
        } catch {
            XCTAssertEqual(error as? PinCodeSetupViewModel.Error, .pinDoesNotMatch)
        }

        do {
            try sut.isNewPinCodeMatch(repeatPinCode: "1234")
        } catch {
            XCTFail("Shouldn't fail")
        }
    }

    func testIsValidPinCode() {
        do {
            try sut.isValid(pinCode: "12")
            XCTFail("Shouldn't valid")
        } catch {
            XCTAssertEqual(error as? PinCodeSetupViewModel.Error, .pinTooShort)
        }

        do {
            try sut.isValid(pinCode: "1234")
            try sut.isValid(pinCode: "123456789012345678902")
        } catch {
            XCTFail("Shouldn't fail")
        }

        do {
            try sut.isValid(pinCode: "1234567890123456789012")
        } catch {
            XCTAssertEqual(error as? PinCodeSetupViewModel.Error, .pinTooLong)
        }
    }

}
