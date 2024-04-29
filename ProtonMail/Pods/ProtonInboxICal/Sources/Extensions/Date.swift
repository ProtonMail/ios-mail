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

extension Date {
    func utcToLocal(timezone: TimeZone) -> Date {
        let timeInterval = self.timeIntervalSince1970 + Double(timezone.secondsFromGMT(for: self))
        return Date(timeIntervalSince1970: timeInterval)
    }

    func getTimestampString(isAllDay: Bool, isZulu: Bool) -> String {
        let dateFormatter: DateFormatter
        if isAllDay {
            dateFormatter = DateFormatters.Timestamp.allDay
        } else {
            if isZulu {
                dateFormatter = DateFormatters.Timestamp.zulu
            } else {
                dateFormatter = DateFormatters.Timestamp.zuluWithoutTimezone
            }
        }

        return dateFormatter.string(from: self)
    }

    static func getCurrentZuluTimestampString(for date: Date) -> String {
        DateFormatters.Timestamp.zulu.string(from: date)
    }

    public static func getDateFrom(timeString: String) -> (date: Date, mainEventIsAllDay: Bool)? {
        let parseAllDayEvent = { () -> (date: Date, mainEventIsAllDay: Bool)? in
            if let ret = DateFormatters.allDay.date(from: timeString) {
                return (ret, true)
            }
            return nil
        }

        let parsePartialDayEvent = { () -> (date: Date, mainEventIsAllDay: Bool)? in
            if let ret = DateFormatters.partialDay.date(from: timeString) {
                return (ret, false)
            }
            return nil
        }

        var ret = parsePartialDayEvent()

        if let ret = ret {
            return ret
        } else {
            ret = parseAllDayEvent()
        }

        if let ret = ret {
            return ret
        }

        return ret
    }

    func localToUTC(timezone: TimeZone) -> Date {
        let timeInterval = self.timeIntervalSince1970 - Double(timezone.secondsFromGMT(for: self))
        return Date(timeIntervalSince1970: timeInterval)
    }

    /// Treating date in UTC0, transforming with *AppStateManager.calendar*, so DST is concerned
    func addSecond(_ value: Int, calendar: Calendar) -> Date {
        let ret = calendar.date(byAdding: .second, value: value, to: self)
        guard let date = ret else {
            return self
        }
        return date
    }

    /// Treating date in UTC0, transforming with *AppStateManager.calendar*, so DST is concerned
    func addMinute(_ value: Int, calendar: Calendar) -> Date {
        self.addSecond(value * 60, calendar: calendar)
    }

    /// Treating date in UTC0, transforming with *AppStateManager.calendar*, so DST is concerned
    func addHour(_ value: Int, calendar: Calendar) -> Date {
        self.addMinute(60 * value, calendar: calendar)
    }

    /// Treating date in UTC0, transforming with *AppStateManager.calendar*, so DST is concerned
    func addDay(_ value: Int, calendar: Calendar) -> Date {
        self.addHour(24 * value, calendar: calendar)
    }

    /// Treating date in UTC0
    /// When it's over the possible range, it will returns the boundary one. e.g. 1/31 =>  2/29
    /// Otherwise, the day and time remain the same
    func addMonth(_ value: Int) -> Date? {
        Calendar.calendarUTC0.date(byAdding: .month, value: value, to: self)
    }

    func add(_ valueType: Calendar.Component, value: Int, calendar: Calendar) -> Date? {
        calendar.date(byAdding: valueType, value: value, to: self)
    }
}
