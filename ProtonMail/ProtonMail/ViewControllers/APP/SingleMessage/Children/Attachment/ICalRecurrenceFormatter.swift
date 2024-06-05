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

import ProtonInboxICal

struct ICalRecurrenceFormatter {
    private let calendar = Calendar.autoupdatingCurrent

    private let dateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    private let untilDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    func string(from recurrence: ICalRecurrence, startDate: Date) -> String? {
        guard recurrence.doesRepeat else {
            return nil
        }

        let frequencyAndDaysDescription = [
            frequencyDescription(of: recurrence),
            specificDaysDescription(of: recurrence, startDate: startDate)
        ]
            .compactMap { $0 }
            .joined(separator: " ")

        return [
            frequencyAndDaysDescription,
            endingDescription(of: recurrence)
        ]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    private func frequencyDescription(of recurrence: ICalRecurrence) -> String {
        if recurrence.repeatEvery == 1 {
            return recurrence.repeatEveryType.intervalOfOneDescription
        } else {
            var dateComponents = DateComponents()
            dateComponents.setValue(recurrence.repeatEvery, for: recurrence.repeatEveryType.calendarComponent)

            guard let intervalDescription = dateComponentsFormatter.string(from: dateComponents) else {
                assertionFailure()
                return ""
            }

            return String(format: L10n.Event.every, intervalDescription)
        }
    }

    private func specificDaysDescription(of recurrence: ICalRecurrence, startDate: Date) -> String? {
        let weekdayNames = calendar.weekdaySymbols

        if let repeatWeekOn = recurrence.repeatWeekOn {
            let daysString = repeatWeekOn
                .map { weekdayNames[$0 - 1] }
                .joined(separator: ", ")

            return String(format: L10n.Event.onDays, daysString)
        } else if let repeatMonthOnWeekDay = recurrence.repeatMonthOnWeekDay {
            if let repeatMonthOnIth = recurrence.repeatMonthOnIth {
                return String(
                    format: L10n.Event.onThe,
                    "\(repeatMonthOnIth.spelledOut) \(weekdayNames[repeatMonthOnWeekDay - 1])"
                )
            } else {
                return String(format: L10n.Event.onDay, repeatMonthOnWeekDay)
            }
        } else if recurrence.repeatEveryType == .month {
            let fallbackDay = calendar.component(.day, from: startDate)
            return String(format: L10n.Event.onDay, fallbackDay)
        } else {
            return nil
        }
    }

    private func endingDescription(of recurrence: ICalRecurrence) -> String? {
        if let endsAfterNum = recurrence.endsAfterNum {
            return String(format: L10n.Event.times, endsAfterNum)
        } else if let endsOnDate = recurrence.endsOnDate {
            return String(format: L10n.Event.until, untilDateFormatter.string(from: endsOnDate))
        } else {
            return nil
        }
    }
}

private extension ICalRecurrence.RepeatEveryType {
    var calendarComponent: Calendar.Component {
        switch self {
        case .day:
            return .day
        case .week:
            return .weekOfMonth
        case .month:
            return .month
        case .year:
            return .year
        }
    }

    var intervalOfOneDescription: String {
        switch self {
        case .day:
            return L10n.Recurrence.daily
        case .week:
            return L10n.Recurrence.weekly
        case .month:
            return L10n.Recurrence.monthly
        case .year:
            return L10n.Recurrence.yearly
        }
    }
}

private extension ICalRecurrence.RepeatMonthOnIth {
    var spelledOut: String {
        switch self {
        case .first:
            return L10n.Recurrence.first
        case .second:
            return L10n.Recurrence.second
        case .third:
            return L10n.Recurrence.third
        case .fourth:
            return L10n.Recurrence.fourth
        case .last:
            return L10n.Recurrence.last
        }
    }
}
