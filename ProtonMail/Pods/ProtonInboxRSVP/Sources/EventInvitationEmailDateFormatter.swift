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

public final class EventInvitationEmailDateFormatter {

    private let localization: L10nProviding
    private let dateFormatterProvider: DateFormatterProviding
    private lazy var fullDayFormatter = dateFormatterProvider.dayFormatter().copy(with: .GMT)
    private lazy var partDayFormatter = dateFormatterProvider.dayFormatter()
    private lazy var timeZoneFormatter = makeTimeZoneFormatter()

    public init(localization: L10nProviding, dateFormatterProvider: DateFormatterProviding) {
        self.localization = localization
        self.dateFormatterProvider = dateFormatterProvider
    }

    public func formattedDate(for eventDate: Date, isAllDayEvent: Bool, eventTimeZone: TimeZone, userID: String) -> String {
        isAllDayEvent
            ? fullDayFormattedDate(from: eventDate)
            : partDayFormattedDateTime(from: eventDate, timeZone: eventTimeZone, userID: userID)
    }

    private func fullDayFormattedDate(from date: Date) -> String {
        fullDayFormatter.string(from: date)
    }

    private func partDayFormattedDateTime(from date: Date, timeZone: TimeZone, userID: String) -> String {
        let timeFormatter = dateFormatterProvider.timeFormatter(userID: userID, with: timeZone)
        let formattedDate = partDayFormatter.copy(with: timeZone).string(from: date)
        let formattedTime = timeFormatter.string(from: date)
        let formattedTimeZone = timeZoneFormatter.copy(with: timeZone).string(from: date)

        return localization.localizedString(for: .emailInvitationSubjectFullDateWithTimeAndTimeZone(
            formattedDate: formattedDate,
            formattedTime: formattedTime,
            formattedTimeZone: formattedTimeZone
        ))
    }

    private func makeTimeZoneFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        let shortLocalizedGMT = "(O)"
        formatter.dateFormat = shortLocalizedGMT
        formatter.locale = Locale(identifier: "en_US_POSIX")

        return formatter
    }
}
