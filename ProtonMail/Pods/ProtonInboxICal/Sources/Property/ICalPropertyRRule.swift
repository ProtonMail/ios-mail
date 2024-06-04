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

/*
 https://gitlab.gnome.org/GNOME/evolution-ews/-/blob/16c65d23b5107ba197556027d52c19504551381f/src/server/e-ews-calendar-utils.c
 https://libical.github.io/libical/apidocs/icalrecur_8h.html#a96c160e7e6b16e0e369c540f2ee164c7
 */

let ICAL_RECURRENCE_ARRAY_MAX_INT16: Int16 = Int16(ICAL_RECURRENCE_ARRAY_MAX.rawValue)

// FIXME: - [CALIOS-2810] Temporary code that proxy logs to the app target. Has to be removed after fixing CALIOS-2784.
public enum ICalAnalytics {
    public static var capture: ((_ message: String) -> Void)?
    public static var addTrace: ((_ trace: String, _ fileID: String, _ function: String, _ line: UInt) -> Void)?
}

public class ICalPropertyRRule {
    public init() {}

    let timeZoneProvider = TimeZoneProvider()

    func findFirstIndexOfMaxInt16(in array: [Int16]) -> Int {
        array.firstIndex(where: { $0 == ICAL_RECURRENCE_ARRAY_MAX_INT16 }) ?? 0
    }

    enum month_num_options: Int {
        case MONTH_NUM_INVALID = -1
        case MONTH_NUM_FIRST = 0
        case MONTH_NUM_SECOND = 1
        case MONTH_NUM_THIRD = 2
        case MONTH_NUM_FOURTH = 3
        case MONTH_NUM_FIFTH = 4
        case MONTH_NUM_LAST = 5
        case MONTH_NUM_DAY = 6
        case MONTH_NUM_OTHER = 7
    }

    enum month_day_options: Int {
        case MONTH_DAY_NTH = 0
        case MONTH_DAY_MON = 2
        case MONTH_DAY_TUE = 3
        case MONTH_DAY_WED = 4
        case MONTH_DAY_THU = 5
        case MONTH_DAY_FRI = 6
        case MONTH_DAY_SAT = 7
        case MONTH_DAY_SUN = 1
    }

    func e_ews_cal_util_month_num_to_day_of_week_index(month_num: month_num_options) -> Int? {
        switch month_num {
        case month_num_options.MONTH_NUM_FIRST:
            return 1 - 1 // 0
        case month_num_options.MONTH_NUM_SECOND:
            return 2 - 1 // 1
        case month_num_options.MONTH_NUM_THIRD:
            return 3 - 1 // 2
        case month_num_options.MONTH_NUM_FOURTH:
            return 4 - 1 // 3
        case month_num_options.MONTH_NUM_FIFTH, month_num_options.MONTH_NUM_LAST:
            return -1 // -1
        default:
            return nil
        }
    }

    func e_ews_cal_util_month_index_to_days_of_week(month_index: Int) -> month_day_options? {
        switch month_index {
        case 0:
            return .MONTH_DAY_SUN
        case 1:
            return .MONTH_DAY_MON
        case 2:
            return .MONTH_DAY_TUE
        case 3:
            return .MONTH_DAY_WED
        case 4:
            return .MONTH_DAY_THU
        case 5:
            return .MONTH_DAY_FRI
        case 6:
            return .MONTH_DAY_SAT
        default:
            return nil
        }
    }

    func convert(dtstart: icaltimetype, rrule: icalrecurrencetype) -> ICalRecurrence? {
        var recurrence = ICalRecurrence()
        recurrence = recurrence.copy(doesRepeat: true)

        if rrule.count > 0 || icaltime_is_null_time(rrule.until) == 0 {
            recurrence = recurrence.copy(endsNever: false)

            if rrule.count > 0 {
                recurrence = recurrence.copy(endsAfterNum: Int(rrule.count))
            } else {
                // https://confluence.protontech.ch/display/CALENDAR/Basics
                // UNTIL is Zulu
                let dateComponents = DateComponents(year: Int(rrule.until.year),
                                                    month: Int(rrule.until.month),
                                                    day: Int(rrule.until.day),
                                                    hour: Int(rrule.until.hour),
                                                    minute: Int(rrule.until.minute),
                                                    second: Int(rrule.until.second))
                recurrence = recurrence.copy(endsOnDate: Calendar.calendarUTC0.date(from: dateComponents))
            }
        }

        switch rrule.freq {
        case ICAL_DAILY_RECURRENCE,
             ICAL_WEEKLY_RECURRENCE,
             ICAL_MONTHLY_RECURRENCE,
             ICAL_YEARLY_RECURRENCE:
            break
        default:
            return nil
        }

        let n_by_day = findFirstIndexOfMaxInt16(in: array(byDay: rrule.by_day))

        let n_by_month_day = findFirstIndexOfMaxInt16(in: array(byMonthDay: rrule.by_month_day))

        let n_by_year_day = findFirstIndexOfMaxInt16(in: array(byYearDay: rrule.by_year_day))

        let n_by_week_no = findFirstIndexOfMaxInt16(in: array(byWeekNo: rrule.by_week_no))

        let n_by_month = findFirstIndexOfMaxInt16(in: array(byMonth: rrule.by_month))

        let n_by_set_pos = findFirstIndexOfMaxInt16(in: array(bySetPos: rrule.by_set_pos))

        switch rrule.freq {
        case ICAL_DAILY_RECURRENCE:
            if n_by_day != 0 ||
                n_by_month_day != 0 ||
                n_by_year_day != 0 ||
                n_by_week_no != 0 ||
                n_by_month != 0 ||
                n_by_set_pos != 0
            {
                return nil
            }

            if rrule.interval > 0 {
                recurrence = recurrence
                    .copy(repeatEveryType: .day)
                    .copy(repeatEvery: Int(rrule.interval))
            }
        case ICAL_WEEKLY_RECURRENCE:

            if n_by_month_day != 0 ||
                n_by_year_day != 0 ||
                n_by_week_no != 0 ||
                n_by_month != 0 ||
                n_by_set_pos != 0
            {
                return nil
            }

            var day_mask = 0

            var ii = 0
            let by_day_array: [Int16] = array(byDay: rrule.by_day)
            while ii < 8, by_day_array[ii] != ICAL_RECURRENCE_ARRAY_MAX_INT16 {
                let weekday = icalrecurrencetype_day_day_of_week(by_day_array[ii])
                let pos = icalrecurrencetype_day_position(by_day_array[ii])

                if pos != 0 {
                    return nil
                }

                switch weekday {
                case ICAL_SUNDAY_WEEKDAY:
                    day_mask |= 1 << 0
                case ICAL_MONDAY_WEEKDAY:
                    day_mask |= 1 << 1
                case ICAL_TUESDAY_WEEKDAY:
                    day_mask |= 1 << 2
                case ICAL_WEDNESDAY_WEEKDAY:
                    day_mask |= 1 << 3
                case ICAL_THURSDAY_WEEKDAY:
                    day_mask |= 1 << 4
                case ICAL_FRIDAY_WEEKDAY:
                    day_mask |= 1 << 5
                case ICAL_SATURDAY_WEEKDAY:
                    day_mask |= 1 << 6
                default:
                    break
                }

                ii += 1
            }

            if ii == 0 {
                let day_of_week = icaltime_day_of_week(dtstart)

                if day_of_week >= 1 {
                    day_mask |= 1 << (day_of_week - 1)
                }
            }

            var ndays = 0
            for i in 0 ..< 7 {
                if (day_mask & (1 << i)) != 0 {
                    ndays += 1
                }
            }

            recurrence = recurrence
                .copy(repeatEveryType: .week)
                .copy(repeatEvery: Int(rrule.interval))

            if ndays > 0 {
                recurrence = recurrence.copy(repeatWeekOn: [])
                assert(day_mask >= 0)

                for i in 0 ..< 7 {
                    // Sunday = 1...
                    if (day_mask & (1 << i)) != 0 {
                        switch i {
                        case 0: // sunday
                            recurrence = recurrence.copy(repeatWeekOn: recurrence.repeatWeekOn?.appending(1))
                        case 1: // monday
                            recurrence = recurrence.copy(repeatWeekOn: recurrence.repeatWeekOn?.appending(2))
                        case 2: // tuesday
                            recurrence = recurrence.copy(repeatWeekOn: recurrence.repeatWeekOn?.appending(3))
                        case 3: // wednesday
                            recurrence = recurrence.copy(repeatWeekOn: recurrence.repeatWeekOn?.appending(4))
                        case 4: // thursday
                            recurrence = recurrence.copy(repeatWeekOn: recurrence.repeatWeekOn?.appending(5))
                        case 5: // friday
                            recurrence = recurrence.copy(repeatWeekOn: recurrence.repeatWeekOn?.appending(6))
                        case 6: // saturday
                            recurrence = recurrence.copy(repeatWeekOn: recurrence.repeatWeekOn?.appending(7))
                        default:
                            return nil
                        }
                    }
                }
            } else {
                // might be weekly
                // might be weekly with COUNT
            }

        case ICAL_MONTHLY_RECURRENCE:
            var month_index = 1

            if n_by_year_day != 0 ||
                n_by_week_no != 0 ||
                n_by_month != 0 ||
                n_by_set_pos > 1
            {
                return nil
            }

            let by_set_pos_array: [Int16] = array(bySetPos: rrule.by_set_pos)
            let by_month_day_array: [Int16] = array(byMonthDay: rrule.by_month_day)
            let by_day_array: [Int16] = array(byDay: rrule.by_day)

            var month_day: month_day_options
            var month_num: month_num_options
            if n_by_month_day == 1 {
                if n_by_set_pos != 0 {
                    return nil
                }

                let nth = by_month_day_array[0]
                if nth < 1, nth != -1 {
                    return nil
                }

                if nth == -1 {
                    month_index = Int(dtstart.day)
                    month_num = month_num_options.MONTH_NUM_LAST
                } else {
                    month_index = Int(nth)
                    month_num = month_num_options.MONTH_NUM_DAY
                }
                month_day = month_day_options.MONTH_DAY_NTH
            } else if n_by_day == 1 {
                let weekday = icalrecurrencetype_day_day_of_week(by_day_array[0])
                var pos = icalrecurrencetype_day_position(by_day_array[0])

                if pos == 0 {
                    if n_by_set_pos != 1 {
                        return nil
                    }

                    pos = Int32(by_set_pos_array[0])
                }

                switch weekday {
                case ICAL_MONDAY_WEEKDAY:
                    month_day = month_day_options.MONTH_DAY_MON
                case ICAL_TUESDAY_WEEKDAY:
                    month_day = month_day_options.MONTH_DAY_TUE
                case ICAL_WEDNESDAY_WEEKDAY:
                    month_day = month_day_options.MONTH_DAY_WED
                case ICAL_THURSDAY_WEEKDAY:
                    month_day = month_day_options.MONTH_DAY_THU
                case ICAL_FRIDAY_WEEKDAY:
                    month_day = month_day_options.MONTH_DAY_FRI
                case ICAL_SATURDAY_WEEKDAY:
                    month_day = month_day_options.MONTH_DAY_SAT
                case ICAL_SUNDAY_WEEKDAY:
                    month_day = month_day_options.MONTH_DAY_SUN
                default:
                    return nil
                }

                if pos == -1 {
                    month_num = month_num_options.MONTH_NUM_LAST
                } else {
                    month_num = month_num_options.init(rawValue: Int(pos) - 1)!
                }
            } else if n_by_day > 1, n_by_set_pos == 1, n_by_month_day == 0 {
                let pos = by_set_pos_array[0]
                if pos == -1 {
                    month_num = month_num_options.MONTH_NUM_LAST
                } else {
                    month_num = month_num_options.init(rawValue: Int(pos) - 1)!
                }

                recurrence = recurrence
                    .copy(repeatEveryType: .month)
                    .copy(repeatEvery: Int(rrule.interval))

                var ii = 0
                while by_day_array[ii] != ICAL_RECURRENCE_ARRAY_MAX_INT16 {
                    let weekday = icalrecurrencetype_day_day_of_week(by_day_array[ii])
                    let pos = icalrecurrencetype_day_position(by_day_array[ii])

                    if pos != 0 {
                        return nil
                    }

                    switch weekday {
                    case ICAL_SUNDAY_WEEKDAY:
                        recurrence = recurrence.copy(repeatMonthOnWeekDay: 1)
                    case ICAL_MONDAY_WEEKDAY:
                        recurrence = recurrence.copy(repeatMonthOnWeekDay: 2)
                    case ICAL_TUESDAY_WEEKDAY:
                        recurrence = recurrence.copy(repeatMonthOnWeekDay: 3)
                    case ICAL_WEDNESDAY_WEEKDAY:
                        recurrence = recurrence.copy(repeatMonthOnWeekDay: 4)
                    case ICAL_THURSDAY_WEEKDAY:
                        recurrence = recurrence.copy(repeatMonthOnWeekDay: 5)
                    case ICAL_FRIDAY_WEEKDAY:
                        recurrence = recurrence.copy(repeatMonthOnWeekDay: 6)
                    case ICAL_SATURDAY_WEEKDAY:
                        recurrence = recurrence.copy(repeatMonthOnWeekDay: 7)
                    default:
                        break
                    }

                    ii += 1
                }

                break
            } else {
                // normal case
                recurrence = recurrence
                    .copy(repeatEveryType: .month)
                    .copy(repeatEvery: Int(rrule.interval))

                break
            }

            recurrence = recurrence
                .copy(repeatEveryType: .month)
                .copy(repeatEvery: Int(rrule.interval))

            switch month_day {
            case month_day_options.MONTH_DAY_NTH:
                if month_num == month_num_options.MONTH_NUM_LAST {
                    recurrence = recurrence
                        .copy(repeatMonthOnIth: .last)
                } else {
                    // No action, not supported
                }
            case month_day_options.MONTH_DAY_MON:
                guard let weekIndex = e_ews_cal_util_month_num_to_day_of_week_index(month_num: month_num) else {
                    return nil
                }

                recurrence = recurrence
                    .copy(repeatMonthOnWeekDay: 2)
                    .copy(repeatMonthOnIth: ICalRecurrence.RepeatMonthOnIth(value: weekIndex))
            case month_day_options.MONTH_DAY_TUE:
                guard let weekIndex = e_ews_cal_util_month_num_to_day_of_week_index(month_num: month_num) else {
                    return nil
                }
                recurrence = recurrence
                    .copy(repeatMonthOnWeekDay: 3)
                    .copy(repeatMonthOnIth: ICalRecurrence.RepeatMonthOnIth(value: weekIndex))
            case month_day_options.MONTH_DAY_WED:
                guard let weekIndex = e_ews_cal_util_month_num_to_day_of_week_index(month_num: month_num) else {
                    return nil
                }
                recurrence = recurrence
                    .copy(repeatMonthOnWeekDay: 4)
                    .copy(repeatMonthOnIth: ICalRecurrence.RepeatMonthOnIth(value: weekIndex))
            case month_day_options.MONTH_DAY_THU:
                guard let weekIndex = e_ews_cal_util_month_num_to_day_of_week_index(month_num: month_num) else {
                    return nil
                }
                recurrence = recurrence
                    .copy(repeatMonthOnWeekDay: 5)
                    .copy(repeatMonthOnIth: ICalRecurrence.RepeatMonthOnIth(value: weekIndex))
            case month_day_options.MONTH_DAY_FRI:
                guard let weekIndex = e_ews_cal_util_month_num_to_day_of_week_index(month_num: month_num) else {
                    return nil
                }
                recurrence = recurrence
                    .copy(repeatMonthOnWeekDay: 6)
                    .copy(repeatMonthOnIth: ICalRecurrence.RepeatMonthOnIth(value: weekIndex))
            case month_day_options.MONTH_DAY_SAT:
                guard let weekIndex = e_ews_cal_util_month_num_to_day_of_week_index(month_num: month_num) else {
                    return nil
                }
                recurrence = recurrence
                    .copy(repeatMonthOnWeekDay: 7)
                    .copy(repeatMonthOnIth: ICalRecurrence.RepeatMonthOnIth(value: weekIndex))
            case month_day_options.MONTH_DAY_SUN:
                guard let weekIndex = e_ews_cal_util_month_num_to_day_of_week_index(month_num: month_num) else {
                    return nil
                }
                recurrence = recurrence
                    .copy(repeatMonthOnWeekDay: 1)
                    .copy(repeatMonthOnIth: ICalRecurrence.RepeatMonthOnIth(value: weekIndex))
            }

        case ICAL_YEARLY_RECURRENCE:
            // we only support repeating yearly for now

            recurrence = recurrence
                .copy(repeatEveryType: .year)
                .copy(repeatEvery: Int(rrule.interval))

        default:
            recurrence = recurrence.copy(doesRepeat: false) // FIXME: TEMP FIX
        }

        return recurrence
    }

    public func convert(recurring: ICalRecurrence, startDateTimezone: TimeZone, isAllDay: Bool, WKST: Int?) -> icalrecurrencetype? {
        if recurring.doesRepeat == false {
            return nil
        }

        var str = ""

        // must have
        switch recurring.repeatEveryType {
        case .day:
            str += "FREQ=DAILY;"
        case .week:
            str += "FREQ=WEEKLY;"
        case .month:
            str += "FREQ=MONTHLY;"
        case .year:
            str += "FREQ=YEARLY;"
        }

        if recurring.endsNever == false {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = startDateTimezone
            if let endsAfterNum = recurring.endsAfterNum {
                str += "COUNT=\(endsAfterNum);"
            } else if var endsOnDate = recurring.formatedEndsOnDate(isAllDay: isAllDay, calendar: calendar) {
                // From UI's datePicker, it'a already the last second (local) of that day in UTC0; also inclusive
                // e.g. in Taipei, dd 15:59:59; in LA, dd+1 06:59:59
                if isAllDay {
                    // to remove the +1 for all day, since we only case the day(RFC's date) part
                    endsOnDate = endsOnDate.utcToLocal(timezone: startDateTimezone)
                }

                // it must be UTC0 for until
                str += "UNTIL=\(endsOnDate.getTimestampString(isAllDay: isAllDay, isZulu: true));"
            }
        }

        if recurring.repeatEvery > 1 {
            str += "INTERVAL=\(recurring.repeatEvery);"
        }

        let weekdayStr = ["", "SU", "MO", "TU", "WE", "TH", "FR", "SA"]
        if let repeatWeekOn = recurring.repeatWeekOn {
            str += "BYDAY="

            for (i, weekday) in repeatWeekOn.enumerated() {
                str += weekdayStr[weekday]
                if i != repeatWeekOn.count - 1 {
                    str += ","
                }
            }

            str += ";"
        } else if let repeatMonthOnIth = recurring.repeatMonthOnIth,
                  let repeatMonthOnWeekDay = recurring.repeatMonthOnWeekDay
        {
            str += "BYDAY=\(weekdayStr[repeatMonthOnWeekDay]);BYSETPOS=\(repeatMonthOnIth.integer);"
        } else if let repeatMonthOnIth = recurring.repeatMonthOnIth,
                  repeatMonthOnIth == .last,
                  recurring.repeatEveryType == .month {
            str += "BYMONTHDAY=\(repeatMonthOnIth.integer)"
        }

        if let WKST = WKST {
            str += "WKST=\(weekdayStr[WKST]);"
        }

        return icalrecurrencetype_from_string(str)
    }

    /**
     Works ONLY for the event with COUNT

     It will return the position of the event index in the original chain. If an single edit is passed in, the recurrenceID is used to determine the index.

     Will return -1 if no match is found.
     */
    public func getRecurrenceIndex(mainEvent: ICalEvent, event: ICalEvent) -> Int {
        guard mainEvent.recurringRulesLibical != nil else {
            return -1
        }

        let iterator = self.getIterator(event: mainEvent)
        defer {
            icalrecur_iterator_free(iterator)
        }

        var time = icalrecur_iterator_next(iterator)
        var idx = 0
        while icaltime_is_null_time(time) == 0 {
            guard let cur_dtstart = icaltime_as_ical_string(time).toString else {
                break
            }

            let startTime = Date.getDateFrom(timeString: cur_dtstart)!.date

            if let recurrenceID = event.recurrenceID,
               let recurrenceIDTimezone = event.recurrenceIDTimeZoneIdentifier
            {
                let converted = recurrenceID.utcToLocal(timezone: self.timeZoneProvider.timeZone(identifier: recurrenceIDTimezone))
                if startTime.compare(converted) == .orderedSame {
                    return idx
                }
            } else {
                if startTime.compare(event.startDate.utcToLocal(timezone: event.startDateTimeZone)) == .orderedSame {
                    return idx
                }
            }

            idx += 1
            time = icalrecur_iterator_next(iterator)
        }

        return -1
    }

    /**
     Generates the starting times of the recurring event up to count recurrences

     RECURRENCE-ID replacement is not done here

     - Parameter event: The recurring event to be expanded
     - Parameter startingDate: the left bound in UTC+0 (inclusive)
     - Parameter count: The max count of starting time to be returned (might be less, e.g. until is set)

     - Returns: The recurring event's starting times in UTC+0 string.
     */
    func generateStartTimeUTC(event: ICalEvent, startingDate: Date, count: Int, calendar: Calendar) -> [String] {
        // since the minimum recurring is daily, so using interval as year should be ok

        var ret = [String]()
        var leftBoundDate = startingDate
        var rightBoundDate = leftBoundDate.addDay(300, calendar: calendar)
        while ret.count < count {
            let tmp = self.generateStartTimeUTC(event: event,
                                                leftBoundDate: leftBoundDate,
                                                rightBoundDate: rightBoundDate,
                                                calendar: calendar)

            ret.append(contentsOf: tmp.startingTime)

            if tmp.hasMore == false {
                break
            }

            leftBoundDate = rightBoundDate
            rightBoundDate = leftBoundDate.addDay(300, calendar: calendar)
        }

        while ret.count > count {
            _ = ret.popLast()
        }

        return ret
    }

    /**
     Returns the icalrecur iterator, with adjusted UNTIL
     */
    func getIterator(event: ICalEvent) -> OpaquePointer? {
        // In *getTimestampString*, we won't generate the time part, which is essential for part-day.
        // But for all-day, it might cause the day to be minus 1 in GMT-X time. e.g. Los_Angelos time
        // Since we take the All-day's time as the local time in display, we'll just use UTC0
        let timeZone = event.isAllDay ? .GMT : event.startDateTimeZone

        if var recur = event.recurringRulesLibical {
            if icaltime_is_null_time(recur.until) == 0 {
                if let until = icaltime_as_ical_string(recur.until).toString,
                   let untilDate = Date.getDateFrom(timeString: until)
                {
                    // adjust UNTIL
                    // Because we don't generate the icaltime_from_string with timezone, so we need to adjust the UNTIL from zulu to current timezone!
                    // Otherwise we will have UNTIL=20210101T155959Z causing us missing all recurrence starting from 20210101T160000 from Taiwan to not show up
                    // case: event starts at 21:00~22:00 in TPE, daily until X
                    let convertedUntilDate = untilDate.date.utcToLocal(timezone: timeZone)
                    recur.until = icaltime_from_string(convertedUntilDate.getTimestampString(isAllDay: untilDate.mainEventIsAllDay,
                                                                                             isZulu: true))

                    // For some reason, when main event is all day, we can't get the accurate lastOccurrence
                    // The reversed iterator will skipp the until's, so we have to add one second here
                    if recur.until.is_date == 1 {
                        recur.until.second = 1
                        recur.until.is_date = 0
                    }
                }
            }

            recur = recur.copyWithOmmitedSaturdayForWeekStart()

            return icalrecur_iterator_new(recur,
                                          icaltime_from_string(
                                              event.startDate.utcToLocal(timezone: timeZone)
                                                  .getTimestampString(isAllDay: event.isAllDay,
                                                                      isZulu: false)
                                          ))
        }

        return nil
    }

    /**
     Generates the starting times of the recurring event within the time bound and respect EXDATE

     RECURRENCE-ID replacement is not done here

     - Parameter event: The recurring event to be expanded
     - Parameter leftBoundDate: the left bound in UTC+0 (inclusive)
     - Parameter rightBoundDate: the right bound in UTC+0 (exclusive)

     - Returns: The recurring event's starting times within the bound in UTC+0 string.
     */
    func generateStartTimeUTC(event: ICalEvent, leftBoundDate: Date, rightBoundDate: Date, calendar: Calendar) -> (startingTime: [String], hasMore: Bool) {
        // calculation needs to be calculated based on local time
        // failure to do so may lead to issues with Daylight Saving Time (DST)
        // for example, a meeting before DST ends is at 2, after will still be at 2, but using UTC to calculate the time, you will have the meeting before DST ends at 2 but after at 3
        var recurringEventUTCStartingTimes = [String]()

        // All-day's startTime is local time already. So we just need UTC0 here.
        let startTimeTimeZone = event.isAllDay ? .GMT : event.startDateTimeZone

        let iterator = self.getIterator(event: event)
        defer {
            icalrecur_iterator_free(iterator)
        }

        let startTime = leftBoundDate.utcToLocal(timezone: startTimeTimeZone)
        let offset = event.startDate.timeIntervalSince1970 - event.endDate.timeIntervalSince1970
        let adjustedStartTime = startTime.addingTimeInterval(offset) // if we have recurring event spanning several days, without doing this, you will miss the case where the starting date is before the leftBoundDate!

        let endTime = rightBoundDate.utcToLocal(timezone: startTimeTimeZone) // keep the consistency for overlap() to work
        // until isinclusive, so we make sure the rightBoundary is inclusive by minusing one
        // somehow when it's all day, we'll have to add one day
        let adjustedEndTime = event.isAllDay ?
            endTime.addDay(1, calendar: calendar) : max(endTime.addSecond(-1, calendar: calendar), startTime)

        let duration = event.endDate.timeIntervalSince1970 - event.startDate.timeIntervalSince1970

        // this func is [from, to]
        let errno = icalrecur_iterator_set_range(iterator,
                                                 icaltime_from_string(adjustedStartTime.getTimestampString(isAllDay: event.isAllDay,
                                                                                                           isZulu: false)),
                                                 icaltime_from_string(adjustedEndTime.addingTimeInterval(1).getTimestampString(isAllDay: event.isAllDay,
                                                                                                         isZulu: false)))

        // if errno is 0, which is the one with count (or invalid rule)
        // in the case of rrule with count, the iterator will start from head anyways, which we will just need to filter out the dates that are out of bound later
        var time = icalrecur_iterator_next(iterator)
        while icaltime_is_null_time(time) == 0 {
            // break if the rrule overruns the endDate
            guard let cur_dtstart = icaltime_as_ical_string(time).toString else {
                break
            }

            let recurringStart = Date.getDateFrom(timeString: cur_dtstart)!.date
            let recurringEnd = recurringStart.addingTimeInterval(duration)

            /*
                Recurring events with COUNT will not be fast-forwarded with icalrecur_iterator_set_range, so it might generate out of bound results

                e.g. if there is a daily recurring event starting on October 1, 2020 for 3 times, but the querying window is November 1, 2020~December 1, 2020. All recurrences will be out of bound.
             */
            if event.isAllDay {
                if Calendar.calendarUTC0.overlap(candidateStartingDate: recurringStart,
                                                 candidateEndingDate: recurringEnd,
                                                 rangeStartingDate: startTime,
                                                 rangeEndingDate: endTime)
                {
                    recurringEventUTCStartingTimes.append(recurringStart.getTimestampString(isAllDay: event.isAllDay,
                                                                                            isZulu: true))
                }
            } else {
                if Calendar.calendarUTC0.overlap(candidateStartingDate: recurringStart,
                                                 candidateEndingDate: recurringEnd,
                                                 rangeStartingDate: startTime,
                                                 rangeEndingDate: endTime)
                {
                    recurringEventUTCStartingTimes.append(recurringStart.localToUTC(timezone: startTimeTimeZone).getTimestampString(isAllDay: event.isAllDay,
                                                                                                                                    isZulu: true))
                }
            }

            time = icalrecur_iterator_next(iterator)
        }
        var hasMore: Bool
        if errno == 1 { // normal case, let the icalrecur_iterator_set_range handle it
            hasMore = icaltime_is_null_time(time) == 0 ? false : true
        } else { // case with COUNT, the range will be travered as a whole, so always will have no hasMore
            hasMore = false
        }

        // filter out EXDATE
        if let exdates = event.exdates {
            recurringEventUTCStartingTimes = recurringEventUTCStartingTimes.filter { startingTime -> Bool in
                if let tmp = Date.getDateFrom(timeString: startingTime)?.date {
                    for exdate in exdates {
                        if exdate.compare(tmp) == .orderedSame {
                            return false
                        }
                    }
                }

                return true
            }
        }

        return (recurringEventUTCStartingTimes, hasMore)
    }

    /// In UTC0
    /// event should be recurring
    func getFirstOccurrenceStartTimeString(event: ICalEvent) -> String? {
        // calculation needs to be calculated based on local time
        // failure to do so may lead to issues with Daylight Saving Time (DST)

        guard event.recurrence.doesRepeat else {
            let rrule: String
            if var recurrenceType = event.recurringRulesLibical {
                rrule = String(cString: icalrecurrencetype_as_string(&recurrenceType))
            } else {
                rrule = "missing recurringRulesLibical"
            }
            ICalAnalytics.addTrace?("RRule: \(rrule)", #file, #function, #line)
            ICalAnalytics.capture?("Got non-recurring event")
            assertionFailure("\(#function) got non-recurring event")
            return nil
        }

        var startDateString: String?

        /// in local if it's not all day
        let exdates: [Date] = {
            let exdates = event.exdates ?? []
            if event.isAllDay {
                return exdates
            }
            return exdates.map { $0.utcToLocal(timezone: event.startDateTimeZone) }
        }()

        let iterator = self.getIterator(event: event)
        defer {
            icalrecur_iterator_free(iterator)
        }

        // if errno is 0, which is the one with count (or invalid rule)
        // in the case of rrule with count, the iterator will start from head anyways, which we will just need to filter out the dates that are out of bound later
        var time = icalrecur_iterator_next(iterator)
        while icaltime_is_null_time(time) == 0 {
            // break if the rrule overruns the endDate
            guard let cur_dtstart = icaltime_as_ical_string(time).toString else {
                break
            }

            let recurringStart = Date.getDateFrom(timeString: cur_dtstart)!.date

            // if recurringStart is not one of exdates
            if exdates.contains(recurringStart) == false {
                if event.isAllDay {
                    startDateString = recurringStart.getTimestampString(isAllDay: event.isAllDay, isZulu: true)
                } else {
                    startDateString = recurringStart.localToUTC(timezone: event.startDateTimeZone).getTimestampString(isAllDay: event.isAllDay,
                                                                                                                      isZulu: true)
                }
                break
            }
            time = icalrecur_iterator_next(iterator)
        }

        return startDateString
    }

    /// In UTC0
    /// event should be recurring & not endsNever
    func getLastOccurrenceStartTimeString(event: ICalEvent, calendar: Calendar) -> String? {
        // calculation needs to be calculated based on local time
        // failure to do so may lead to issues with Daylight Saving Time (DST)

        guard event.recurrence.doesRepeat else {
            assertionFailure("\(#function) got non-recurring event")
            return nil
        }

        var lastStartDate: Date?

        let startTimeTimeZone = event.isAllDay ? .GMT : event.startDateTimeZone
        /// in local if it's not all day
        let exdates: [Date] = {
            let exdates = event.exdates ?? []
            if event.isAllDay {
                return exdates
            }
            return exdates.map { $0.utcToLocal(timezone: startTimeTimeZone) }
        }()

        // reverse iterator doesn't work when startDate equals to until
        if let endsOnDate = event.recurrence.endsOnDate {
            // All-day's startTime is local time already. So we just need UTC0 here.
            let startTimeTimeZone = event.isAllDay ? .GMT : event.startDateTimeZone

            let startTimeString = event.startDate.utcToLocal(timezone: startTimeTimeZone)
                .getTimestampString(isAllDay: event.isAllDay,
                                    isZulu: false)

            // Somehow all day needs the end boundary to add one more day
            // so the reversed iterator can work properly
            let endTimeString = endsOnDate.addDay(event.isAllDay ? 1 : 0, calendar: calendar).utcToLocal(timezone: startTimeTimeZone)
                .getTimestampString(isAllDay: event.isAllDay,
                                    isZulu: false)

            if startTimeString == endTimeString {
                lastStartDate = event.startDate
            } else {
                let start = icaltime_from_string(startTimeString)
                let end = icaltime_from_string(endTimeString)

                let iterator = self.getIterator(event: event)
                defer {
                    icalrecur_iterator_free(iterator)
                }
                icalrecur_iterator_set_range(iterator, end, start) // reverse it

                // if errno is 0, which is the one with count (or invalid rule)
                // in the case of rrule with count, the iterator will start from head anyways, which we will just need to filter out the dates that are out of bound later
                var time = icalrecur_iterator_prev(iterator)
                while icaltime_is_null_time(time) == 0 {
                    // break if the rrule overruns the endDate
                    guard let cur_dtstart = icaltime_as_ical_string(time).toString else {
                        break
                    }

                    let recurringStart = Date.getDateFrom(timeString: cur_dtstart)!.date

                    // if recurringStart is not one of exdates
                    if exdates.contains(recurringStart) == false {
                        lastStartDate = recurringStart
                        break
                    }

                    time = icalrecur_iterator_prev(iterator)
                }
            }

        } else if event.recurrence.endsAfterNum != nil {
            let startDates = self.getAllStartDates(event: event)
            lastStartDate = startDates.reversed().first(where: { exdates.contains($0) == false })
        } else {
            assertionFailure("endsNever event should not be sent into \(#function)")
        }

        if event.isAllDay {
            return lastStartDate?.getTimestampString(isAllDay: event.isAllDay, isZulu: true)
        } else {
            return lastStartDate?.localToUTC(timezone: startTimeTimeZone).getTimestampString(isAllDay: event.isAllDay,
                                                                                             isZulu: true)
        }
    }

    /// Generate all startDates when event is
    /// * recurring
    /// * does end
    /// Returns in local
    func getAllStartDates(event: ICalEvent) -> [Date] {
        guard event.recurrence.doesRepeat, event.recurrence.endsNever == false else {
            assertionFailure("One should not use \(#function) to generate non-stopping event, non-recurring event")
            return []
        }

        var dates: [Date] = []

        let iterator = self.getIterator(event: event)
        defer {
            icalrecur_iterator_free(iterator)
        }

        // if errno is 0, which is the one with count (or invalid rule)
        // in the case of rrule with count, the iterator will start from head anyways, which we will just need to filter out the dates that are out of bound later
        var time = icalrecur_iterator_next(iterator)
        while icaltime_is_null_time(time) == 0 {
            // break if the rrule overruns the endDate
            guard let cur_dtstart = icaltime_as_ical_string(time).toString else {
                break
            }

            let recurringStart = Date.getDateFrom(timeString: cur_dtstart)!.date
            dates.append(recurringStart)

            time = icalrecur_iterator_next(iterator)
        }

        return dates
    }
}

private extension icalrecurrencetype {

    /// For some reason having `week_start` set to `ICAL_SATURDAY_WEEKDAY` affects having different `DTStart` which
    /// breaks computation of occurrences for recurring event.
    /// There is an issue in libical library (most likely) - /src/libical/icalrecur.c#L1904
    func copyWithOmmitedSaturdayForWeekStart() -> icalrecurrencetype {
        var copy = self
        copy.week_start = week_start.saturdayToMonday
        return copy
    }

}

private extension icalrecurrencetype_weekday {

    var saturdayToMonday: icalrecurrencetype_weekday {
        self == ICAL_SATURDAY_WEEKDAY ? ICAL_MONDAY_WEEKDAY : self
    }

}
