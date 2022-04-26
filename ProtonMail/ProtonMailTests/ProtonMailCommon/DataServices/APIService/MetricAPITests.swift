// Copyright (c) 2022 Proton Technologies AG
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

import XCTest
@testable import ProtonMail

final class MetricAPITests: XCTestCase {

    func testApplyDarkStyle() {
        let api = MetricDarkMode(applyDarkStyle: true)
        guard let dict = api.parameters else {
            XCTFail("Shouldn't be nil")
            return
        }
        XCTAssertEqual(dict["Log"] as? String, "dark_styles")
        XCTAssertEqual(dict["Title"] as? String, "update_dark_styles")
        XCTAssertEqual(dict["Data"] as? [String: String], ["action": "apply_dark_styles"])
    }

    func testRemoveDarkStyle() {
        let api = MetricDarkMode(applyDarkStyle: false)
        guard let dict = api.parameters else {
            XCTFail("Shouldn't be nil")
            return
        }
        XCTAssertEqual(dict["Log"] as? String, "dark_styles")
        XCTAssertEqual(dict["Title"] as? String, "update_dark_styles")
        XCTAssertEqual(dict["Data"] as? [String: String], ["action": "remove_dark_styles"])
    }
}
