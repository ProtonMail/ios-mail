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

class EventsServiceTests: XCTestCase {

    func testRemoveTypeFieldOfLabelEvent_returnCleanedResult() {
        let input: [String: Any] = ["Type": 123, "Name": "Hello", "Order": 1]
        let expected: [String: Any] = ["Name": "Hello"]

        let sut = EventsService.removeConflictV3FieldOfLabelEvent

        let result = sut(input)

        XCTAssertEqual(result.count, expected.count)
        XCTAssertEqual(result["Name"] as? String, expected["Name"] as? String)
        XCTAssertNil(result["Type"])
        XCTAssertNil(result["Order"])
    }

    func testRemoveTypeFieldOfLabelEvent_returnUntouchedResult() {
        let input: [String: Any] = ["ID": 123, "Name": "Hello"]
        let expected: [String: Any] = ["ID": 123, "Name": "Hello"]

        let sut = EventsService.removeConflictV3FieldOfLabelEvent

        let result = sut(input)

        XCTAssertEqual(result.count, expected.count)
        XCTAssertEqual(result["Name"] as? String, expected["Name"] as? String)
        XCTAssertEqual(result["ID"] as? Int, expected["ID"] as? Int)
    }
}
