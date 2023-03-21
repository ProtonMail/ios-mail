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

import XCTest
@testable import ProtonMail

final class EncryptedSearchIndexStateTests: XCTestCase {
    private typealias SUT = EncryptedSearchIndexState

    func testEqual() {
        XCTAssertEqual(SUT.disabled, SUT.disabled)
        XCTAssertNotEqual(SUT.disabled, SUT.background)
        XCTAssertEqual(SUT.undetermined, SUT.undetermined)
        XCTAssertNotEqual(SUT.undetermined, SUT.background)
        XCTAssertEqual(SUT.paused(nil), SUT.paused(nil))
        XCTAssertEqual(SUT.paused(.lowBattery), SUT.paused(.lowBattery))
        XCTAssertEqual(SUT.paused(.noWiFi), SUT.paused(.noWiFi))
        XCTAssertNotEqual(SUT.paused(.noWiFi), SUT.paused(.noConnection))
        XCTAssertNotEqual(SUT.paused(.lowStorage), SUT.paused(.lowBattery))
    }

    func testContainCase() {
        let states: [SUT] = [.background, .paused(nil), .disabled]
        XCTAssertTrue(states.containsCase(.paused(.lowStorage)))
        XCTAssertTrue(states.containsCase(.background))
        XCTAssertFalse(states.containsCase(.backgroundStopped))
    }
}
