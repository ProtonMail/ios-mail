// Copyright (c) 2024 Proton Technologies AG
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

final class MemoryCacheTests: XCTestCase {
    private var sut: MemoryCache<String, Int>!

    // MARK: setObject(:for:)

    func testSetObject_whenThereIsAnObjectForThatKey_itShouldReplaceTheObject() async {
        sut = MemoryCache<String, Int>(maxElements: 3)
        await sut.setObject(1, for: "A")
        await sut.setObject(2, for: "B")
        await sut.setObject(3, for: "A")

        let result = await sut.object(for: "A")
        XCTAssertEqual(result, 3)
    }

    func testSetObject_whenTheCacheLimitIsReqched_itShouldEvictTheOldestObject() async {
        sut = MemoryCache<String, Int>(maxElements: 2)
        await sut.setObject(1, for: "A")
        await sut.setObject(2, for: "B")
        await sut.setObject(3, for: "C")

        let result = await sut.object(for: "A")
        XCTAssertNil(result)
    }

    // MARK: object(for:)

    func testObjectFor_whenItExists_itShouldReturnTheObject() async {
        sut = MemoryCache<String, Int>(maxElements: 3)
        await sut.setObject(1, for: "A")
        await sut.setObject(2, for: "B")
        await sut.setObject(3, for: "C")

        let result = await sut.object(for: "A")
        XCTAssertEqual(result, 1)
    }

    func testObjectFor_whenItDoesNotExist_itShouldReturnNil() async {
        sut = MemoryCache<String, Int>(maxElements: 3)
        await sut.setObject(1, for: "A")
        await sut.setObject(2, for: "B")
        await sut.setObject(3, for: "C")

        let result = await sut.object(for: "D")
        XCTAssertNil(result)
    }
}
