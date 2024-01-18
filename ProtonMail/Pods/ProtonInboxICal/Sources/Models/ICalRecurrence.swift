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

public struct ICalRecurrence {
    /// Must set true when it repeating
    public let doesRepeat: Bool

    /// Must set - type as day, week, month, and year
    public let repeatEveryType: RepeatEveryType

    /// Once set as true, other `ends*` variables should set as nil
    public let endsNever: Bool

    /// Can't coexist with `endsOnDate`
    public let endsAfterNum: Int?

    /// Must set.  e.g. 2 as every 2 weeks
    public let repeatEvery: Int

    /// Must set when it's repeatOn week.
    /// * Default is based on the startDate.
    /// * Based on DateFormatter().weekdaySymbols.shiftRightOne().
    /// * Sunday = 1, Monday = 2, Tuesday = 3, ...
    public let repeatWeekOn: [Int]?

    /// Must set when it's repeatOn month
    /// * This coexists with `repeatMonthOnWeekDay`
    public let repeatMonthOnIth: RepeatMonthOnIth?

    /// Must set when it's repeatOn month
    /// same format from CalendarComponent's week day
    public let repeatMonthOnWeekDay: Int?

    /// Can't coexist with `endsAfterNum`
    /// This should be inclusive - the last second on that day
    public let endsOnDate: Date?

    public enum RepeatEveryType: String {
        case day, week, month, year
    }

    public enum RepeatMonthOnIth: String, CaseIterable {
        case first, second, third, fourth, last

        /// translate int value into RepeatMonthOnIth based on its order of cases
        /// - parameter value: zero-based
        /// `.last` - if value = - 1
        init(value: Int) {
            guard value >= -1, value < 4 else { fatalError() }
            if value < 0 {
                self = .last
            } else {
                self = RepeatMonthOnIth.allCases[value]
            }
        }

        var integer: Int {
            switch self {
            case .first:
                return 1
            case .second:
                return 2
            case .third:
                return 3
            case .fourth:
                return 4
            case .last:
                return -1
            }
        }
    }

    func formatedEndsOnDate(isAllDay: Bool, calendar: Calendar) -> Date? {
        guard var date = self.endsOnDate else { return nil }
        date = calendar.startOfDay(for: date)
        if !isAllDay {
            date.addTimeInterval(86399)
        }
        return date
    }

    public init(
        doesRepeat: Bool = false,
        repeatEveryType: RepeatEveryType = .week,
        endsNever: Bool = true,
        endsAfterNum: Int? = nil,
        repeatEvery: Int = 1,
        repeatWeekOn: [Int]? = nil,
        repeatMonthOnIth: RepeatMonthOnIth? = nil,
        repeatMonthOnWeekDay: Int? = nil,
        endsOnDate: Date? = nil
    ) {
        self.doesRepeat = doesRepeat
        self.repeatEveryType = repeatEveryType
        self.endsNever = endsNever
        self.endsAfterNum = endsAfterNum
        self.repeatEvery = repeatEvery
        self.repeatWeekOn = repeatWeekOn
        self.repeatMonthOnIth = repeatMonthOnIth
        self.repeatMonthOnWeekDay = repeatMonthOnWeekDay
        self.endsOnDate = endsOnDate
    }
}

extension ICalRecurrence {
    func copy(doesRepeat: Bool) -> ICalRecurrence {
        .init(
            doesRepeat: doesRepeat,
            repeatEveryType: self.repeatEveryType,
            endsNever: self.endsNever,
            endsAfterNum: self.endsAfterNum,
            repeatEvery: self.repeatEvery,
            repeatWeekOn: self.repeatWeekOn,
            repeatMonthOnIth: self.repeatMonthOnIth,
            repeatMonthOnWeekDay: self.repeatMonthOnWeekDay,
            endsOnDate: self.endsOnDate
        )
    }

    func copy(endsNever: Bool) -> ICalRecurrence {
        .init(
            doesRepeat: self.doesRepeat,
            repeatEveryType: self.repeatEveryType,
            endsNever: endsNever,
            endsAfterNum: self.endsAfterNum,
            repeatEvery: self.repeatEvery,
            repeatWeekOn: self.repeatWeekOn,
            repeatMonthOnIth: self.repeatMonthOnIth,
            repeatMonthOnWeekDay: self.repeatMonthOnWeekDay,
            endsOnDate: self.endsOnDate
        )
    }

    func copy(endsAfterNum: Int?) -> ICalRecurrence {
        .init(
            doesRepeat: self.doesRepeat,
            repeatEveryType: self.repeatEveryType,
            endsNever: self.endsNever,
            endsAfterNum: endsAfterNum,
            repeatEvery: self.repeatEvery,
            repeatWeekOn: self.repeatWeekOn,
            repeatMonthOnIth: self.repeatMonthOnIth,
            repeatMonthOnWeekDay: self.repeatMonthOnWeekDay,
            endsOnDate: self.endsOnDate
        )
    }

    func copy(endsOnDate: Date?) -> ICalRecurrence {
        .init(
            doesRepeat: self.doesRepeat,
            repeatEveryType: self.repeatEveryType,
            endsNever: self.endsNever,
            endsAfterNum: self.endsAfterNum,
            repeatEvery: self.repeatEvery,
            repeatWeekOn: self.repeatWeekOn,
            repeatMonthOnIth: self.repeatMonthOnIth,
            repeatMonthOnWeekDay: self.repeatMonthOnWeekDay,
            endsOnDate: endsOnDate
        )
    }

    func copy(repeatEveryType: ICalRecurrence.RepeatEveryType) -> ICalRecurrence {
        .init(
            doesRepeat: self.doesRepeat,
            repeatEveryType: repeatEveryType,
            endsNever: self.endsNever,
            endsAfterNum: self.endsAfterNum,
            repeatEvery: self.repeatEvery,
            repeatWeekOn: self.repeatWeekOn,
            repeatMonthOnIth: self.repeatMonthOnIth,
            repeatMonthOnWeekDay: self.repeatMonthOnWeekDay,
            endsOnDate: self.endsOnDate
        )
    }

    func copy(repeatEvery: Int) -> ICalRecurrence {
        .init(
            doesRepeat: self.doesRepeat,
            repeatEveryType: self.repeatEveryType,
            endsNever: self.endsNever,
            endsAfterNum: self.endsAfterNum,
            repeatEvery: repeatEvery,
            repeatWeekOn: self.repeatWeekOn,
            repeatMonthOnIth: self.repeatMonthOnIth,
            repeatMonthOnWeekDay: self.repeatMonthOnWeekDay,
            endsOnDate: self.endsOnDate
        )
    }

    func copy(repeatWeekOn: [Int]?) -> ICalRecurrence {
        .init(
            doesRepeat: self.doesRepeat,
            repeatEveryType: self.repeatEveryType,
            endsNever: self.endsNever,
            endsAfterNum: self.endsAfterNum,
            repeatEvery: self.repeatEvery,
            repeatWeekOn: repeatWeekOn,
            repeatMonthOnIth: self.repeatMonthOnIth,
            repeatMonthOnWeekDay: self.repeatMonthOnWeekDay,
            endsOnDate: self.endsOnDate
        )
    }

    func copy(repeatMonthOnWeekDay: Int?) -> ICalRecurrence {
        .init(
            doesRepeat: self.doesRepeat,
            repeatEveryType: self.repeatEveryType,
            endsNever: self.endsNever,
            endsAfterNum: self.endsAfterNum,
            repeatEvery: self.repeatEvery,
            repeatWeekOn: self.repeatWeekOn,
            repeatMonthOnIth: self.repeatMonthOnIth,
            repeatMonthOnWeekDay: repeatMonthOnWeekDay,
            endsOnDate: self.endsOnDate
        )
    }

    func copy(repeatMonthOnIth: ICalRecurrence.RepeatMonthOnIth?) -> ICalRecurrence {
        .init(
            doesRepeat: self.doesRepeat,
            repeatEveryType: self.repeatEveryType,
            endsNever: self.endsNever,
            endsAfterNum: self.endsAfterNum,
            repeatEvery: self.repeatEvery,
            repeatWeekOn: self.repeatWeekOn,
            repeatMonthOnIth: repeatMonthOnIth,
            repeatMonthOnWeekDay: self.repeatMonthOnWeekDay,
            endsOnDate: self.endsOnDate
        )
    }
}
