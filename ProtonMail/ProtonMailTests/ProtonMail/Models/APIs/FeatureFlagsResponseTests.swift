// Copyright (c) 2021 Proton AG
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

class FeatureFlagsResponseTests: XCTestCase {

    var sut: FeatureFlagsResponse!
    override func setUp() {
        super.setUp()
        sut = FeatureFlagsResponse()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testParseResponse() throws {
        XCTAssertTrue(sut.ParseResponse(FeatureFlagTestData.data.parseObjectAny()!))

        let threadValue = try XCTUnwrap(sut.result["ThreadingIOS"] as? Bool)
        XCTAssertEqual(threadValue, true)

        let integerValue = try XCTUnwrap(sut.result["TestInteger"] as? Int)
        XCTAssertEqual(integerValue, 1)
    }

    func testEmptyResponse() {
        XCTAssertFalse(sut.ParseResponse([:]))
    }
}
