//
//  PMDateFormatter.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail. If not, see <https://www.gnu.org/licenses/>.

import Foundation

class PMDateFormatter {

    private(set) static var shared = PMDateFormatter()

    var isDateInToday = Environment.calendar.isDateInToday
    var isDateInYesterday = Environment.calendar.isDateInYesterday
    var isDateInTomorrow = Environment.calendar.isDateInTomorrow

    private let notificationCenter: NotificationCenter

    private lazy var todayFormatter = formatterFactory(localizedDateFormatFromTemplate: "jjmm")
    private lazy var currentWeekFormatter = formatterFactory(localizedDateFormatFromTemplate: "EEEE")
    private lazy var fullDateFormatter = formatterFactory(localizedDateFormatFromTemplate: "MMMMddyyyy")
    private lazy var monthDateFormatter = formatterFactory(localizedDateFormatFromTemplate: "MMMM, dd, jjmm")
    private lazy var minuteFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute]
        return formatter
    }()
    private lazy var dateFormatter = formatterFactory(localizedDateFormatFromTemplate: "EEEE, MMMM dd")
    private lazy var timeFormatter = formatterFactory(localizedDateFormatFromTemplate: "hhmm a")

    private lazy var detailDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Environment.locale()
        formatter.timeZone = Environment.timeZone
        formatter.timeStyle = .medium
        formatter.dateStyle = .long
        return formatter
    }()

    private var calendar: Calendar {
        var calendar = Environment.calendar
        calendar.timeZone = Environment.timeZone
        calendar.locale = Environment.locale()
        return calendar
    }

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        addLocaleChangesObserver()
    }

    func string(from date: Date, weekStart: WeekStart) -> String {
        let currentDate = Environment.currentDate()

        if isDateInToday(date) {
            return todayFormatter.string(from: date)
        } else if isDateInYesterday(date) {
            return LocalString._yesterday
        } else if isPreviousWeek(currentDate: currentDate, date: date, weekStart: weekStart) {
            return fullDateFormatter.string(from: date)
        } else {
            return currentWeekFormatter.string(from: date)
        }
    }

    func checkIsDateWillHappenInTheNext10Mins(_ date: Date) -> Bool {
        let currentDate = Environment.currentDate()
        let timeDifference = date.timeIntervalSince1970 - currentDate.timeIntervalSince1970
        return timeDifference <= 600
    }

    func stringForScheduledMsg(from date: Date, inListView: Bool = false) -> String {
        let currentDate = Environment.currentDate()
        let timeDifference = date.timeIntervalSince1970 - currentDate.timeIntervalSince1970
        if isDateInToday(date) || timeDifference <= 0 {
            if timeDifference < 60 { // 1 min
                return inListView ? LocalString._less_than_1min_in_list_view :
                    LocalString._less_than_1min_not_in_list_view
            } else if timeDifference <= 1_800 { // 30 mins
                let minute = minuteFormatter.string(from: timeDifference) ?? ""
                let displayMinute = max(Int(minute) ?? 0, 0)
                return String(format: LocalString._scheduled_message_time_in_minute,
                              displayMinute)
            } else {
                return String(format: LocalString._scheduled_message_time_today,
                              todayFormatter.string(from: date))
            }
        } else if isDateInTomorrow(date) {
            return String(format: LocalString._scheduled_message_time_tomorrow,
                          todayFormatter.string(from: date))
        } else {
            return monthDateFormatter.string(from: date)
        }
    }

    func titleForScheduledBanner(from date: Date) -> (String, String) {
        let dateString = dateFormatter.string(from: date)
        let timeString = timeFormatter.string(from: date)
        return (dateString, timeString)
    }

    func detailDateString(from date: Date) -> String {
        return detailDateFormatter.string(from: date)
    }

    private func isPreviousWeek(currentDate: Date, date: Date, weekStart: WeekStart) -> Bool {
        date < beginningOfTheWeekDate(currentDate: currentDate, date: date, weekStart: weekStart)
    }

    private func isWeekStartDate(currentDate: Date, date: Date, weekStart: WeekStart) -> Bool {
        var dateComponenets = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: currentDate)
        dateComponenets.weekday = weekStart.weekStartInGregorianCalendar
        dateComponenets.timeZone = Environment.timeZone
        guard let weekStartDate = calendar.date(from: dateComponenets) else { return false }
        return calendar.isDate(weekStartDate, inSameDayAs: date)
    }

    private func beginningOfTheWeekDate(currentDate: Date, date: Date, weekStart: WeekStart) -> Date {
        guard !isWeekStartDate(currentDate: currentDate, date: date, weekStart: weekStart) else { return date }
        var dateComponents = DateComponents()
        dateComponents.timeZone = Environment.timeZone
        dateComponents.weekday = weekStart.weekStartInGregorianCalendar
        return calendar.nextDate(
            after: currentDate,
            matching: dateComponents,
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .backward
        ) ?? currentDate
    }

    private func formatterFactory(localizedDateFormatFromTemplate: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Environment.locale()
        formatter.timeZone = Environment.timeZone
        formatter.setLocalizedDateFormatFromTemplate(localizedDateFormatFromTemplate)
        return formatter
    }

    @objc
    private func localeChanged() {
        Self.shared = PMDateFormatter()
    }

    private func addLocaleChangesObserver() {
        notificationCenter.addObserver(
            self,
            selector: #selector(localeChanged),
            name: NSLocale.currentLocaleDidChangeNotification,
            object: nil
        )
    }

}
