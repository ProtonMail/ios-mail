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

@testable import ProtonMail
import ProtonCoreKeymaker
import XCTest

final class UILockPinCodeTests: XCTestCase {
    private var sut: UILockPinCode!
    private var globalContainer: TestContainer!

    private var keychain: Keychain {
        globalContainer.keychain
    }

    private let keychainKeyForPinCode = "UILockPinCode.hashedPinCode"
    private let keychainKeyForSalt = "UILockPinCode.salt"

    override func setUp() {
        globalContainer = .init()
        sut = UILockPinCode(dependencies: globalContainer)
    }

    override func tearDown() {
        globalContainer = nil
        sut = nil
    }

    func testActivate_itPersistsInTheKeychainAndReturnsTrue() async {
        sut.cleanPersistedData()

        let dummyPinValue = "dummy_pin_value"
        let result = await sut.activate(with: dummyPinValue)

        XCTAssertTrue(result)
        XCTAssertNotNil(keychain.data(forKey: keychainKeyForPinCode))
        XCTAssertNotNil(keychain.data(forKey: keychainKeyForSalt))
    }

    func testIsVerified_whenSamePinHasBeenPersisted_itReturnsTrue() async {
        let dummyPin = "dummy_pin"
        sut.cleanPersistedData()
        _ = await sut.activate(with: dummyPin)

        let result = await sut.isVerified(pinCode: dummyPin)
        XCTAssertTrue(result)
    }

    func testIsVerified_whenDifferentPinHasBeenPersisted_itReturnsFalse() async {
        let dummyPin1 = "dummy_pin_1"
        let dummyPin2 = "dummy_pin_2"
        sut.cleanPersistedData()
        _ = await sut.activate(with: dummyPin1)

        let result = await sut.isVerified(pinCode: dummyPin2)
        XCTAssertFalse(result)
    }

    func testCleanPersistedData() {
        keychain.set(Data("x56c7vbyun".utf8), forKey: keychainKeyForPinCode)
        keychain.set(Data("c67v68bgv".utf8), forKey: keychainKeyForSalt)

        sut.cleanPersistedData()
        XCTAssertNil(keychain.data(forKey: keychainKeyForPinCode))
        XCTAssertNil(keychain.data(forKey: keychainKeyForSalt))
    }
}
