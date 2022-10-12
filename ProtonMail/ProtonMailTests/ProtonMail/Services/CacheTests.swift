// Copyright (c) 2022 Proton Technologies AG
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

class CacheTests: XCTestCase {
    private var sut: Cache<TestKey, TestValue>!

    private let fooKey = TestKey(label: "foo")
    private let barKey = TestKey(label: "bar")
    private let xyzKey = TestKey(label: "xyz")

    override func setUpWithError() throws {
        try super.setUpWithError()

        sut = Cache(totalCostLimit: 5)
    }

    override func tearDownWithError() throws {
        sut = nil

        try super.tearDownWithError()
    }

    func testHoldsCachedValues() throws {
        let value = TestValue(content: "some data", cost: 0)

        sut[fooKey] = value

        XCTAssertEqual(sut[fooKey]?.content, value.content)

        sut[fooKey] = nil

        XCTAssertNil(sut[fooKey])
    }

    func testEvictsLRUObjectsIfOverLimit() {
        sut[fooKey] = TestValue(content: "foo data", cost: 2)
        sut[barKey] = TestValue(content: "bar data", cost: 2)
        sut[xyzKey] = TestValue(content: "xyz data", cost: 2)

        XCTAssertNil(sut[fooKey])
        XCTAssertNotNil(sut[barKey])
        XCTAssertNotNil(sut[xyzKey])
    }

    func testPurgingRemovesAllValues() {
        sut[fooKey] = TestValue(content: "foo data", cost: 0)
        sut[barKey] = TestValue(content: "bar data", cost: 0)

        sut.purge()

        XCTAssertNil(sut[fooKey])
        XCTAssertNil(sut[barKey])
    }
}

private struct TestKey: Hashable {
    let label: String
}

private struct TestValue: Cacheable {
    let content: String
    let cost: Int
}
