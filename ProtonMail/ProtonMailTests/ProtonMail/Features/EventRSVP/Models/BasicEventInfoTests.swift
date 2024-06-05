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

import XCTest

@testable import ProtonMail

final class BasicEventInfoTests: XCTestCase {
    private var calendarID, eventID, eventUID: String!
    private var occurrence, recurrenceID: Int!

    override func setUp() {
        super.setUp()

        calendarID = UUID().uuidString
        eventID = UUID().uuidString
        eventUID = UUID().uuidString
        occurrence = .random(in: 0...Int(Date.distantFuture.timeIntervalSince1970))
        recurrenceID = .random(in: 0...Int(Date.distantFuture.timeIntervalSince1970))
    }

    override func tearDown() {
        eventUID = nil
        occurrence = nil
        recurrenceID = nil

        super.tearDown()
    }

    func testInviteForMainOccurrences() throws {
        let headers: [String: String] = [
            "X-Pm-Calendar-Eventuid": eventUID
        ].compactMapValues { $0 }

        let parsedInfo = try XCTUnwrap(BasicEventInfo(messageHeaders: headers))
        XCTAssertEqual(parsedInfo, .inviteDataFromHeaders(eventUID: eventUID, recurrenceID: nil))
    }

    func testInviteForSingleEdits() throws {
        let headers: [String: String] = [
            "X-Pm-Calendar-Eventuid": eventUID,
            // not a mistake, recurrenceID is in the occurrence header for invites
            "X-Pm-Calendar-Occurrence": "\(recurrenceID!)"
        ]

        let parsedInfo = try XCTUnwrap(BasicEventInfo(messageHeaders: headers))
        XCTAssertEqual(parsedInfo, .inviteDataFromHeaders(eventUID: eventUID, recurrenceID: recurrenceID))
    }

    func testReminderForNonRecurringEvents() throws {
        let headers: [String: String] = [
            "X-Pm-Calendar-Calendarid": calendarID,
            "X-Pm-Calendar-Eventid": eventID,
            "X-Pm-Calendar-Eventisrecurring": "0",
            "X-Pm-Calendar-Eventuid": eventUID,
            "X-Pm-Calendar-Occurrence": "\(occurrence!)",
            "X-Pm-Calendar-Sequence": "1"
        ]

        let parsedInfo = try XCTUnwrap(BasicEventInfo(messageHeaders: headers))
        XCTAssertEqual(parsedInfo, .reminderDataFromHeaders(eventUID: eventUID, occurrence: occurrence, recurrenceID: nil))
    }

    func testReminderForRecurringMainOccurrences() throws {
        let headers: [String: String] = [
            "X-Pm-Calendar-Calendarid": calendarID,
            "X-Pm-Calendar-Eventid": eventID,
            "X-Pm-Calendar-Eventisrecurring": "1",
            "X-Pm-Calendar-Eventuid": eventUID,
            "X-Pm-Calendar-Occurrence": "\(occurrence!)",
            "X-Pm-Calendar-Sequence": "1"
        ]

        let parsedInfo = try XCTUnwrap(BasicEventInfo(messageHeaders: headers))
        XCTAssertEqual(parsedInfo, .reminderDataFromHeaders(eventUID: eventUID, occurrence: occurrence, recurrenceID: nil))
    }

    func testReminderForSingleEdits() throws {
        let headers: [String: String] = [
            "X-Pm-Calendar-Calendarid": calendarID,
            "X-Pm-Calendar-Eventid": eventID,
            "X-Pm-Calendar-Eventisrecurring": "0",
            "X-Pm-Calendar-Eventuid": eventUID,
            "X-Pm-Calendar-Occurrence": "\(occurrence!)",
            "X-Pm-Calendar-Recurrenceid": "\(recurrenceID!)",
            "X-Pm-Calendar-Sequence": "1"
        ]

        let parsedInfo = try XCTUnwrap(BasicEventInfo(messageHeaders: headers))
        XCTAssertEqual(parsedInfo, .reminderDataFromHeaders(eventUID: eventUID, occurrence: occurrence, recurrenceID: recurrenceID))
    }
}
