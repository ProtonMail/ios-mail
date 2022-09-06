// Copyright (c) 2022 Proton AG
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

@testable import ProtonMailAnalytics

class ProtonMailAnalyticsTests: XCTestCase {
    private var sut: ProtonMailAnalytics!

    override func setUpWithError() throws {
        try super.setUpWithError()

        sut = ProtonMailAnalytics(endPoint: "")
    }

    override func tearDownWithError() throws {
        sut = nil

        try super.tearDownWithError()
    }

    func testCombinesTraceInformationWithExtraInfoPrioritizingTheFormer() throws {
        let trace = "foo"
        let extraInfo = [
            "Action": "some action",
            "Custom Trace": "bar"   // unrealistic key name but just to emphasize
        ]

        let output = sut.combinedExtra(extraInfo: extraInfo, trace: trace)

        let stringOutput = try XCTUnwrap(output as? [String: String])
        let expectedOutput: [String: String] = [
            "Action": "some action",
            "Custom Trace": "foo"
        ]
        XCTAssertEqual(stringOutput, expectedOutput)
    }

    func testDoesNotSetEmptyExtraDictionaries() throws {
        XCTAssertNil(sut.combinedExtra(extraInfo: nil, trace: nil))
        XCTAssertNil(sut.combinedExtra(extraInfo: [:], trace: nil))
    }
}
