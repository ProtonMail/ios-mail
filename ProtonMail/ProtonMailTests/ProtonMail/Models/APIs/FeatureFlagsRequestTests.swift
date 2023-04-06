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

class FeatureFlagsRequestTests: XCTestCase {

    var sut: FetchFeatureFlagsRequest!
    override func setUp() {
        super.setUp()
        sut = FetchFeatureFlagsRequest()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testInitWithoutKeys() {
        XCTAssertEqual(sut.keysToFetch, FeatureFlagKey.allCases)
    }

    func testInitWithKeys() {
        sut = FetchFeatureFlagsRequest(keys: [.inAppFeedback])
        XCTAssertEqual(sut.keysToFetch, [.inAppFeedback])
    }

    func testInitWithEmptyKeys() {
        sut = FetchFeatureFlagsRequest(keys: [])
        XCTAssertEqual(sut.keysToFetch, FeatureFlagKey.allCases)
    }

    func testParameters() throws {
        let queryString = sut.keysToFetch.map{ $0.rawValue }.joined(separator: ",")
        let parameters = try XCTUnwrap(sut.parameters)
        let code = try XCTUnwrap(parameters["Code"] as? String)
        XCTAssertEqual(code, queryString)
    }

    func testPath() {
        XCTAssertEqual(sut.path, "/core/v4/features")
    }

    func testMethod() {
        XCTAssertEqual(sut.method, .get)
    }
}
