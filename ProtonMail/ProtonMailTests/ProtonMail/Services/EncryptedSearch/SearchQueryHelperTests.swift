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

class SearchQueryHelperTests: XCTestCase {
    var sut: SearchQueryHelper!

    override func setUp() {
        super.setUp()
        sut = .init()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testProcessSearchKeywords() {
        let query = "test@pm.me"

        let result = sut.sanitizeAndExtractKeywords(query: query)

        XCTAssertEqual(result, [query])
    }

    func testProcessSearchKeywords_queryWithSpace() {
        let query = "test query"

        let result = sut.sanitizeAndExtractKeywords(query: query)

        XCTAssertEqual(result, ["test", "query"])
    }

    func testProcessSearchKeywords_queryWithApostrophes() {
        let query = "\u{2018} \u{2019} \u{201B}"

        let result = sut.sanitizeAndExtractKeywords(query: query)

        XCTAssertEqual(result, ["'", "'", "'"])
    }

    func testProcessSearchKeywords_queryWithDoubleQuotes() {
        let query = "\u{201C} \u{201D}"

        let result = sut.sanitizeAndExtractKeywords(query: query)

        XCTAssertEqual(result, [" "])
    }
}
