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

final class UnlockPinCodeModelImplTests: XCTestCase {
    var sut: UnlockPinCodeModelImpl!
    private var testContainer: TestContainer!

    override func setUp() {
        super.setUp()
        testContainer = .init()

        sut = .init(dependencies: testContainer)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        testContainer =  nil
    }

    func testGetPinFailedRemainingCount_failedCountLessThan10_returnPositiveValue() {
        for count in 0..<10 {
            testContainer.userDefaults[.pinFailedCount] = count

            XCTAssertTrue(sut.getPinFailedRemainingCount() > 0)
        }
    }

    func testGetPinFailedRemainingCount_failedCountMoreThan10_return0() {
        testContainer.userDefaults[.pinFailedCount] = Int.random(in: 10...Int.max)

        XCTAssertEqual(sut.getPinFailedRemainingCount(), 0)
    }

    func testGetPinFailedError_remainingFailedCountIsMoreThan4_returnIncorrectPinError() {
        testContainer.userDefaults[.pinFailedCount] = Int.random(in: 0...6)

        XCTAssertTrue(sut.getPinFailedError().contains(check: LocalString._incorrect_pin))
    }

    func testGetPinFailedError_remaingingFailedCountIsLessThan4_returnIncorrectPinError() {
        let failedCount = Int.random(in: 7...10)
        testContainer.userDefaults[.pinFailedCount] = failedCount

        let expected = String.localizedStringWithFormat(
            LocalString._attempt_remaining_until_secure_data_wipe,
            10 - failedCount
        )
        XCTAssertEqual(sut.getPinFailedError(), expected)
    }
}
