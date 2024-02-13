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

public class ICalPropertyRRuleWriter: ICalPropertyWriter {
    var rrule: OpaquePointer {
        property
    }

    public init(_ type: icalrecurrencetype) {
        super.init(icalproperty_new_rrule(type))
    }

    public convenience init?(recurrence: ICalRecurrence, timeZone: TimeZone, isAllDay: Bool, WKST: Int?) {
        if recurrence.doesRepeat == false {
            return nil
        }

        var type = icalrecurrencetype()
        // must have
        switch recurrence.repeatEveryType {
        case .day:
            type.freq = ICAL_DAILY_RECURRENCE
        case .week:
            type.freq = ICAL_WEEKLY_RECURRENCE
        case .month:
            type.freq = ICAL_MONTHLY_RECURRENCE
        case .year:
            type.freq = ICAL_YEARLY_RECURRENCE
        }

        if recurrence.endsNever == false {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            if let endsAfterNum = recurrence.endsAfterNum {
                type.count = Int32(endsAfterNum)
            } else if var endsOnDate = recurrence.formatedEndsOnDate(isAllDay: isAllDay, calendar: calendar) {
                // from UI's date picker, it's inclusive already. 23:59:59 (local's UTC0 time)
                if Calendar.calendarUTC0.component(.second, from: endsOnDate) != 9 {
                    // throw?
                }

                // But for all day, the UTC0 date might +1 from the intended date
                if isAllDay {
                    endsOnDate = endsOnDate.utcToLocal(timezone: timeZone)
                }

                type.until = icaltimetype(endsOnDate, isAllDay: isAllDay)
            }
        }

        type.interval = Int16(recurrence.repeatEvery)

        var by_day: [Int16] = []
        var by_set_pos: [Int16] = []
        if let repeatWeekOn = recurrence.repeatWeekOn {
            by_day = repeatWeekOn.map { weekOn -> Int16 in
                icalrecurrencetype_encode_day(.init(UInt32(weekOn)), 0)
            }
        } else if let repeatMonthOnIth = recurrence.repeatMonthOnIth,
                  let repeatMonthOnWeekDay = recurrence.repeatMonthOnWeekDay
        {
            by_day = [icalrecurrencetype_encode_day(.init(UInt32(repeatMonthOnWeekDay)), 0)]
            by_set_pos = [Int16(repeatMonthOnIth.integer)]
        }

        by_day.append(Int16(ICAL_RECURRENCE_ARRAY_MAX.rawValue))
        by_set_pos.append(Int16(ICAL_RECURRENCE_ARRAY_MAX.rawValue))
        unsafeCopyToTuple(array: &by_day, to: &type.by_day)
        unsafeCopyToTuple(array: &by_set_pos, to: &type.by_set_pos)

        type.by_second.0 = Int16(ICAL_RECURRENCE_ARRAY_MAX.rawValue)
        type.by_minute.0 = Int16(ICAL_RECURRENCE_ARRAY_MAX.rawValue)
        type.by_hour.0 = Int16(ICAL_RECURRENCE_ARRAY_MAX.rawValue)
        type.by_week_no.0 = Int16(ICAL_RECURRENCE_ARRAY_MAX.rawValue)
        type.by_month.0 = Int16(ICAL_RECURRENCE_ARRAY_MAX.rawValue)
        type.by_month_day.0 = Int16(ICAL_RECURRENCE_ARRAY_MAX.rawValue)
        type.by_year_day.0 = Int16(ICAL_RECURRENCE_ARRAY_MAX.rawValue)

        if let WKST = WKST {
            type.week_start = .init(UInt32(WKST))
        }

        self.init(type)
    }

}

/**
 Unsafe copy array to tuple. One must make sure the type of *tuple*'s values are same as *ElementType*.

 # Tested

 It's all good when the sizes of array and tuple are different.
 */
private func unsafeCopyToTuple<ElementType, Tuple>(array: inout [ElementType], to tuple: inout Tuple) {
    withUnsafeMutablePointer(to: &tuple) { pointer in
        let bound = pointer.withMemoryRebound(to: ElementType.self, capacity: array.count) { $0 }
        array.enumerated().forEach { (bound + $0.offset).pointee = $0.element }
    }
}
