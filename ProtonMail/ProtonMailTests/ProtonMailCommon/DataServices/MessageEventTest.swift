//
//  MessageEventTest.swift
//  ProtonMailTests
//
//  Created on 2021/11/22.
//  Copyright © 2021 ProtonMail. All rights reserved.
//

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
