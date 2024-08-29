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
import XCTest

class MessageDetailsDateFormatterTests: BaseTestCase {

    struct TestCase {
        let given: Date
        let expected: String
    }

    func testString_ForGivenDate_ReturnsCorrectlyFormattedDate() {
        let testCases: [TestCase] = [
            .init(given: .fixture("2022-05-09 14:17:22"), expected: "May 9, 2022 at 4:17:22 PM"),
            .init(given: .fixture("2024-01-30 08:11:45"), expected: "Jan 30, 2024 at 9:11:45 AM"),
            .init(given: .fixture("2017-10-30 22:49:33"), expected: "Oct 30, 2017 at 11:49:33 PM"),
            .init(given: .fixture("2024-12-31 03:59:59"), expected: "Dec 31, 2024 at 4:59:59 AM")
        ]

        testCases.forEach { testCase in
            XCTAssertEqual(MessageDetailsDateFormatter.string(from: testCase.given), testCase.expected)
        }
    }

}

private extension Date {

    static func fixture(_ stringDate: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = .gmt

        guard let date = formatter.date(from: stringDate) else {
            fatalError("\(self) is not a date in test format (\(String(describing: formatter.dateFormat)))")
        }

        return date
    }

}
