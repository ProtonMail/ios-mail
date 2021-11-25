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

import XCTest
@testable import ProtonMail

class MessageEventTest: XCTestCase {

    func testIsDraft_labelID_true() {
        let message: [String: Any] = [
            "LabelIDs": ["1", "8"]
        ]
        let response: [String: Any] = [
            "Action": 2,
            "Message": message,
            "ID": "aaa"
        ]
        let event = MessageEvent(event: response)
        XCTAssertTrue(event.isDraft)
    }

    func testIsDraft_labelID_false() {
        let message: [String: Any] = [
            "LabelIDs": ["3"]
        ]
        let response: [String: Any] = [
            "Action": 2,
            "Message": message,
            "ID": "aaa"
        ]
        let event = MessageEvent(event: response)
        XCTAssertFalse(event.isDraft)
    }

    func testIsDraft_location_true() {
        let message: [String: Any] = [
            "Location": 1
        ]
        let response: [String: Any] = [
            "Action": 2,
            "Message": message,
            "ID": "aaa"
        ]
        let event = MessageEvent(event: response)
        XCTAssertTrue(event.isDraft)
    }

    func testIsDraft_location_false() {
        let message: [String: Any] = [
            "Location": [3]
        ]
        let response: [String: Any] = [
            "Action": 2,
            "Message": message,
            "ID": "aaa"
        ]
        let event = MessageEvent(event: response)
        XCTAssertFalse(event.isDraft)
    }

    func testParsedTime_stringValue() {
        let interval: Double = 1637550543
        let message: [String: Any] = [
            "Time": "\(interval)"
        ]
        let response: [String: Any] = [
            "Action": 2,
            "Message": message,
            "ID": "aaa"
        ]
        let event = MessageEvent(event: response)
        XCTAssertEqual(interval.asDate(), event.parsedTime)
    }

    func testParsedTime_numberValue() {
        let interval: Double = 1637550543
        let message: [String: Any] = [
            "Time": interval
        ]
        let response: [String: Any] = [
            "Action": 2,
            "Message": message,
            "ID": "aaa"
        ]
        let event = MessageEvent(event: response)
        XCTAssertEqual(interval.asDate(), event.parsedTime)
    }

    func testParsedTime_noTimeValue() {
        let message: [String: Any] = [:]
        let response: [String: Any] = [
            "Action": 2,
            "Message": message,
            "ID": "aaa"
        ]
        let event = MessageEvent(event: response)
        XCTAssertNil(event.parsedTime)
    }
}
