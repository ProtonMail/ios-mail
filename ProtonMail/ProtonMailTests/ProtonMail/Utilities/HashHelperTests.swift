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
import ProtonMailAnalytics

final class HashHelperTests: XCTestCase {
    var sut: HashHelper!

    override func setUp() {
        super.setUp()
        sut = HashHelper()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testGenerateRandomBytes_itShouldReturnDiffernetValues() {
        let iterations = 10
        var results = [Data]()
        for _ in 1...iterations {
            results.append(try! sut.generateRandomBytes(count: 2))
        }
        XCTAssertTrue(results.uniqued.count == iterations)
    }

    func testSaltAndHash_whenSameSalt_itReturnsSameValues() {
        let value = "mySaltedAndHashInitialValue"
        let salt = Data("mySalt".utf8)
        XCTAssertEqual(
            try! sut.saltAndHash(value: value, with: salt),
            try! sut.saltAndHash(value: value, with: salt)
        )
    }

    func testSaltAndHash_whenDifferentSalts_itReturnsDifferentValues() {
        let value = "mySaltedAndHashInitialValue"
        let salt1 = Data("mySalt_1".utf8)
        let salt2 = Data("mySalt_2".utf8)
        XCTAssertNotEqual(
            try! sut.saltAndHash(value: value, with: salt1),
            try! sut.saltAndHash(value: value, with: salt2)
        )
    }

    func testSaltAndHash_whenDifferentValueLengths_itReturnsSameHashLenght() {
        let salt = Data("mySalt".utf8)
        let shortValue = "euwpo"
        let longValue = "xycuiv6ob7pnmc67vbyinm"
        XCTAssertEqual(
            try! sut.saltAndHash(value: shortValue, with: salt).count,
            try! sut.saltAndHash(value: longValue, with: salt).count
        )
    }
}
