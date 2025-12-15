// Copyright (c) 2025 Proton Technologies AG
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
import InboxCoreUI
import Testing

struct DatePickerViewConfigurationTests {
    struct MockConfig: DatePickerViewConfiguration {
        var title: LocalizedStringResource = "Title"
        var selectTitle: LocalizedStringResource = "Select"
        var minuteInterval: TimeInterval = 60
        var range: ClosedRange<Date>
        var initialSelectedDate: Date?

        func formatDate(_ date: Date) -> String {
            "\(date)"
        }
    }

    @Test
    func resolvedInitialDate_whenInRange_returnsInitialDate() {
        let now = Date()
        let range = now.addingTimeInterval(-3600)...now.addingTimeInterval(3600)
        let config = MockConfig(range: range, initialSelectedDate: now)

        #expect(config.resolvedInitialDate == now)
    }

    @Test
    func resolvedInitialDate_whenInitialDateIsNil_returnsLowerBound() {
        let lowerBound = Date()
        let range = lowerBound...lowerBound.addingTimeInterval(3600)
        let config = MockConfig(range: range, initialSelectedDate: nil)

        #expect(config.resolvedInitialDate == lowerBound)
    }

    @Test
    func resolvedInitialDate_whenInitialDateIsOutOfRange_returnsLowerBound() {
        let lowerBound = Date()
        let range = lowerBound...lowerBound.addingTimeInterval(3600)
        let outOfRange = lowerBound.addingTimeInterval(-7200)
        let config = MockConfig(range: range, initialSelectedDate: outOfRange)

        #expect(config.resolvedInitialDate == lowerBound)
    }
}
