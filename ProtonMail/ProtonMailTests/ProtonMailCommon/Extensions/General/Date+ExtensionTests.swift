// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Crypto
import XCTest
@testable import ProtonMail

class Date_ExtensionTests: XCTestCase {

    override func setUp() {
        super.setUp()

        Environment.locale = { .enUS }
    }

    override func tearDown() {
        super.tearDown()

        Environment.restore()
    }

    func testUnixTime() {
        let interval: Int64 = 1635745851
        CryptoUpdateTime(interval)
        let date = Date.unixDate
        XCTAssertEqual(date.timeIntervalSince1970, Double(interval))
    }

    func testCountExpirationTimeMinuteLevel() {
        let interval: Int64 = 1635745851
        CryptoUpdateTime(interval)
        let time = Date(timeIntervalSince1970: Double(interval) + 120.0)
        let result = time.countExpirationTime
        XCTAssertEqual(result, "3 mins")
    }

    func testCountExpirationTimeHourLevel() {
        let interval: Int64 = 1635745851
        CryptoUpdateTime(interval)
        let time = Date(timeIntervalSince1970: Double(interval) + 7200.0)
        let result = time.countExpirationTime
        XCTAssertEqual(result, "2 hours")
    }

    func testCountExpirationTimeDayLevel() {
        let interval: Int64 = 1635745851
        CryptoUpdateTime(interval)
        let time = Date(timeIntervalSince1970: Double(interval) + 86500.0)
        let result = time.countExpirationTime
        XCTAssertEqual(result, "1 day")
    }
}
