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

public enum ICalManagerConstants {
    // inclusive
    public static let maxSummaryLength = 255
    public static let maxLocationLength = 255
    public static let maxDescriptionLength = 3000
    public static let maxAlarmCount = 10

    // close closure
    // inclusive
    public static let maxRecurrenceIntervalDaily = 999
    public static let maxRecurrenceIntervalWeekly = 4999
    public static let maxRecurrenceIntervalMonthly = 999
    public static let maxRecurrenceIntervalYearly = 99
    public static let maxRecurrenceCount = (1 ... 49)
    public static let maxRecurrenceUntil: Date = {
        let dateFormatter = DateFormatters.makeUSUTC()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.date(from: "31/12/2038")!
    }()

    // open closure
    // exclusion
    public static let maxNotificationDays = 7000
    public static let maxNotificationHours = 1000
    public static let maxNotificationMinutes = 10000
    public static let maxNotificationSeconds = 0
}
