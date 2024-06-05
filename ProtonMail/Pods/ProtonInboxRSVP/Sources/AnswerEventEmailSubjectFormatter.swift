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

import ProtonInboxICal

struct AnswerEventEmailSubjectFormatter {
    private let localization: L10nProviding
    private let emailSubjectDateFormatter: EventInvitationEmailDateFormatter

    init(localization: L10nProviding, dateFormatterProvider: DateFormatterProviding) {
        self.localization = localization
        emailSubjectDateFormatter = .init(localization: localization, dateFormatterProvider: dateFormatterProvider)
    }

    func string(for event: ICalEvent, userID: String) -> String {
        let formattedDate = emailSubjectDateFormatter.formattedDate(
            for: event.startDate,
            isAllDayEvent: event.isAllDay,
            eventTimeZone: event.startDateTimeZone,
            userID: userID
        )
        let time = event.startDate..<event.endDate
        let isAllDaySingleDay = event.isAllDay && Calendar.calendarUTC0.days(from: time) == 1
        let l10nKey = isAllDaySingleDay ?
            L10nKey.emailAnswerSubjectAllDaySingle(formattedDate: formattedDate) :
            L10nKey.emailAnswerSubjectOther(formattedDate: formattedDate)
        return localization.localizedString(for: l10nKey)
    }
}
