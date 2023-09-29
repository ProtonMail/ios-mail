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
import XCTest

final class BiometricLockTests: XCTestCase {

    private var sut: BiometricLock!
    private var LAContextMock: MockLAContextProtocol!
    private var keyChain: KeychainWrapper!


    override func setUp() {
        super.setUp()
        LAContextMock = .init()
        keyChain = .makeTestingKeychain()
        sut = .init(keyChain: keyChain, localAuthenticationContext: LAContextMock)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        keyChain.removeEverything()
        keyChain = nil
        LAContextMock = nil
    }

    func testIsEnabled_keyChainHasNoValue_returnFalse() {
        keyChain.remove(forKey: BiometricLock.Constants.key)

        XCTAssertFalse(sut.isEnabled)
    }

    func testIsEnabled_keyChainHasValue_returnTrue() {
        keyChain.set(String.randomString(10), forKey: BiometricLock.Constants.key)

        XCTAssertTrue(sut.isEnabled)
    }

    func testEnable_canEvaluatePass_keyChainHasData() {
        LAContextMock.canEvaluatePolicyStub.bodyIs { _, _, _ in
            return true
        }

        XCTAssertNoThrow(try sut.enable())

        XCTAssertNotNil(keyChain.string(forKey: BiometricLock.Constants.key))
        XCTAssertTrue(sut.isEnabled)
    }

    func testEnable_canEvaluateFail_keyChainHasNoData() {
        LAContextMock.canEvaluatePolicyStub.bodyIs { _, _, _ in
            return false
        }

        XCTAssertThrowsError(try sut.enable())

        XCTAssertNil(keyChain.string(forKey: BiometricLock.Constants.key))
        XCTAssertFalse(sut.isEnabled)
    }

    func testDisable_keyChainHasData_keyChainWillBeEmpty() {
        keyChain.set(String.randomString(10), forKey: BiometricLock.Constants.key)

        sut.disable()

        XCTAssertFalse(sut.isEnabled)
        XCTAssertNil(keyChain.string(forKey: BiometricLock.Constants.key))
    }

    func testUnlock_canEvaluateFail_returnFalse() {
        LAContextMock.canEvaluatePolicyStub.bodyIs { _, _, _ in
            return false
        }
        let e = expectation(description: "Closure is called")

        sut.unlock { result, error in

            XCTAssertFalse(result)
            XCTAssertNotNil(error)

            e.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testUnlock_canEvaluateSuccess_andEvaluatePolicyPass_returnTrue() {
        LAContextMock.canEvaluatePolicyStub.bodyIs { _, _, _ in
            return true
        }
        LAContextMock.evaluatePolicyStub.bodyIs { _, _, _, completion in
            completion(true, nil)
        }
        let e = expectation(description: "Closure is called")

        sut.unlock { result, error in
            XCTAssertTrue(result)
            XCTAssertNil(error)

            e.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}
