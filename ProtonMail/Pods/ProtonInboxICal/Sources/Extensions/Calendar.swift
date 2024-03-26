// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Technologies AG and Proton Calendar.
//
// Proton Calendar is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Calendar is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Calendar. If not, see https://www.gnu.org/licenses/.

import Foundation

extension Calendar {
    static let calendarUTC0: Calendar = {
        var calendar = Calendar(identifier: .gregorian)

        calendar.locale = .current // UTC0 is used to display all day event
        calendar.timeZone = .GMT

        return calendar
    }()

    func overlap(candidateStartingDate: Date, candidateEndingDate: Date, rangeStartingDate: Date, rangeEndingDate: Date) -> Bool {
        if candidateStartingDate.compare(candidateEndingDate) == .orderedSame {
            // special case
            // when start time == end time

            return rangeStartingDate <= candidateStartingDate && candidateStartingDate <= rangeEndingDate
        } else {
            return rangeStartingDate < candidateEndingDate && candidateStartingDate < rangeEndingDate
        }
    }

    func onSameDay(lhs: Date, rhs: Date) -> Bool {
        let components: Set<Component> = [.year, .month, .day]
        return self.dateComponents(components, from: lhs) == self.dateComponents(components, from: rhs)
    }

    func isLastInWeekdayOrdinal(date: Date) -> Bool {
        var dateComponents = self.dateComponents([.year, .month, .weekday], from: date)
        dateComponents.weekdayOrdinal = -1
        let lastWeekInSameMonth = self.date(from: dateComponents)!
        return self.onSameDay(lhs: lastWeekInSameMonth, rhs: date)
    }
}
