//
//  PMDateFormatter.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail. If not, see <https://www.gnu.org/licenses/>.

import Foundation

class PMDateFormatter {

    static let shared = PMDateFormatter()

    var isDateInToday = Environment.calendar.isDateInToday
    var isDateInYesterday = Environment.calendar.isDateInYesterday

    private lazy var todayFormatter = formatterFactory(localizedDateFormatFromTemplate: "HHmm")
    private lazy var currentWeekFormatter = formatterFactory(localizedDateFormatFromTemplate: "EEEE")
    private lazy var fullDateFormatter = formatterFactory(localizedDateFormatFromTemplate: "MMMMddyyyy")

    private var calendar: Calendar {
        var calendar = Environment.calendar
        calendar.timeZone = Environment.timeZone
        calendar.locale = Environment.locale
        return calendar
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
        formatter.locale = Environment.locale
        formatter.timeZone = Environment.timeZone
        formatter.setLocalizedDateFormatFromTemplate(localizedDateFormatFromTemplate)
        return formatter
    }

}
