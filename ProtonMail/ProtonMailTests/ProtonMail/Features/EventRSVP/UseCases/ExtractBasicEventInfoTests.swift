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

final class ExtractBasicEventInfoTests: XCTestCase {
    private var sut: ExtractBasicEventInfoImpl!

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        sut = .init()
    }

    override func tearDownWithError() throws {
        sut = nil
        
        try super.tearDownWithError()
    }

    func testBasicInfoExtraction_withRecurrenceID() throws {
        let basicICS = #"""
BEGIN:VCALENDAR
METHOD:REQUEST
BEGIN:VEVENT
UID:FOO
RECURRENCE-ID;VALUE=DATE:19960401
END:VEVENT
END:VCALENDAR
"""#

        let icsData = Data(basicICS.utf8)
        let basicEventInfo = try sut.execute(icsData: icsData)
        XCTAssertEqual(basicEventInfo, .inviteDataFromICS(eventUID: "FOO", recurrenceID: 828316800))
    }

    func testBasicInfoExtraction_withoutRecurrenceID() throws {
        let basicICS = #"""
BEGIN:VCALENDAR
METHOD:REQUEST
BEGIN:VEVENT
UID:FOO
END:VEVENT
END:VCALENDAR
"""#

        let icsData = Data(basicICS.utf8)
        let basicEventInfo = try sut.execute(icsData: icsData)
        XCTAssertEqual(basicEventInfo, .inviteDataFromICS(eventUID: "FOO", recurrenceID: nil))
    }

    func testBasicInfoExtraction_withRecurrenceID_inSpecificTimezone() throws {
        let basicICS = #"""
BEGIN:VCALENDAR
METHOD:CANCEL
BEGIN:VEVENT
UID:FOO
RECURRENCE-ID;TZID=Europe/Warsaw:20240508T120000
END:VEVENT
END:VCALENDAR
"""#

        let icsData = Data(basicICS.utf8)
        let basicEventInfo = try sut.execute(icsData: icsData)
        XCTAssertEqual(basicEventInfo, .inviteDataFromICS(eventUID: "FOO", recurrenceID: 1715162400))
    }

    func testWhenMethodIsMissing_thenThrowsError() {
        let basicICS = #"""
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:FOO
RECURRENCE-ID;TZID=Europe/Warsaw:20240508T120000
END:VEVENT
END:VCALENDAR
"""#

        attemptExtraction(from: basicICS, expecting: .icsDoesNotContainSupportedMethod)
    }

    func testWhenMethodIsPublish_thenThrowsError() {
        let basicICS = #"""
BEGIN:VCALENDAR
METHOD:PUBLISH
BEGIN:VEVENT
UID:FOO
RECURRENCE-ID;TZID=Europe/Warsaw:20240508T120000
END:VEVENT
END:VCALENDAR
"""#

        attemptExtraction(from: basicICS, expecting: .icsDoesNotContainSupportedMethod)
    }

    private func attemptExtraction(from ics: String, expecting expectedError: EventRSVPError) {
        let icsData = Data(ics.utf8)

        XCTAssertThrowsError(try sut.execute(icsData: icsData)) { error in
            guard let receivedError = error as? EventRSVPError, receivedError == expectedError else {
                XCTFail("Unexpected error: \(error)")
                return
            }
        }
    }
}
