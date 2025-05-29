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

import Foundation
@testable import InboxComposer
import Testing

struct ScheduleDatePickerConfigurationTests {

    // MARK: range.lowerBound

    @Test
    func rangeLowerBound_returnsExpectedRoundedTime() throws {
        let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)  // Nov 14, 2023, 22:13:20 UTC
        let expected = Date(timeIntervalSince1970: 1_700_000_700)  // Nov 14, 2023, 22:25:00 UTC

        let sut = ScheduleDatePickerConfiguration(dateFormatter: .init(), referenceDate: referenceDate)
        #expect(sut.range.lowerBound == expected)
    }

    @Test
    func rangeLowerBound_roundsUpAndCrossesHour() throws {
        let referenceDate = Date(timeIntervalSince1970: 1_699_998_333)  // Nov 14, 2023, 21:45:33 UTC
        let expected = Date(timeIntervalSince1970: 1_699_999_200)  // Nov 14, 2023, 22:00:00 UTC

        let sut = ScheduleDatePickerConfiguration(dateFormatter: .init(), referenceDate: referenceDate)
        #expect(sut.range.lowerBound == expected)
    }

    @Test
    func rangeLowerBound_itAlwaysRoundsToTheMinuteBlockSize() throws {
        let sut = ScheduleDatePickerConfiguration(dateFormatter: .init())
        let minute = Calendar.current.component(.minute, from: sut.range.lowerBound)
        #expect(minute % Int(sut.minuteInterval) == 0)
    }

    @Test
    func rangeLowerBound_itAlwaysSetsSecondsToZero() throws {
        let sut = ScheduleDatePickerConfiguration(dateFormatter: .init())
        let seconds = Calendar.current.component(.second, from: sut.range.lowerBound)
        #expect(seconds == 0)
    }

    // MARK: range.upperBound

    @Test
    func rangeEnd_itIsSetAt89DaysFromTheRangeStart() throws {
        let sut = ScheduleDatePickerConfiguration(dateFormatter: .init())
        let expectedEnd = Calendar.current.date(byAdding: .day, value: 89, to: sut.range.lowerBound)!
        #expect(sut.range.upperBound == expectedEnd)
    }
}
