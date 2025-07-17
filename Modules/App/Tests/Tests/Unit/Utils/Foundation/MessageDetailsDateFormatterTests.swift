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

@testable import ProtonMail
import InboxTesting
import Testing

class MessageDetailsDateFormatterTests {
    @Test(
        .calendarZurichEnUS,
        arguments:
            zip(
                [
                    Date.fixture("2022-05-09 14:17:22"),
                    Date.fixture("2024-01-30 08:11:45"),
                    Date.fixture("2017-10-30 22:49:33"),
                    Date.fixture("2024-12-31 03:59:59"),
                ],
                [
                    "May 9, 2022 at 4:17:22 PM",
                    "Jan 30, 2024 at 9:11:45 AM",
                    "Oct 30, 2017 at 11:49:33 PM",
                    "Dec 31, 2024 at 4:59:59 AM",
                ]
            )
    )
    func testDateFormatter(given: Date, expected: String) async throws {
        #expect(MessageDetailsDateFormatter.string(from: given) == expected)
    }
}
