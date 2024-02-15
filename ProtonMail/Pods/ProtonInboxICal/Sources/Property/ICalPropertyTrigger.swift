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

public enum ICalPropertyTrigger {

    /// Due to the limitation, the trigger will be rounded down unconditionally.
    /// We only generate relative time trigger!
    /// All-day events don't have limits on components within the trigger, but partial-day events have.
    ///
    /// The trigger should validate the following constraints:
    /// ```
    /// - abs(Days) < 7000 (weeks are validated as days because of some PHP limitation)
    /// - abs(Hours) < 1000
    /// - abs(Minutes) < 10'000
    /// - abs(Seconds) == 0
    /// ```
    ///
    public static func generateTrigger(
        isAllDay: Bool,
        notificationData: ICalNotification
    ) -> icaltriggertype {
        var trigger = icaltriggertype()

        if isAllDay {
            guard let atHour = notificationData.atHour, let atMinute = notificationData.atMinute else {
                fatalError("`atHour` and `atMinute` parameters can not be missing for all day event.")
            }
            let startDate = Calendar.calendarUTC0.startOfDay(for: Date())

            // we get the trigger time relative to start time
            var triggerDate = Calendar.calendarUTC0.date(byAdding: .day,
                                                         value: -notificationData.beforeDays,
                                                         to: startDate,
                                                         wrappingComponents: false)!
            triggerDate = Calendar.calendarUTC0.date(byAdding: .day,
                                                     value: -notificationData.beforeWeeks * 7,
                                                     to: triggerDate,
                                                     wrappingComponents: false)!
            triggerDate = Calendar.calendarUTC0.date(bySetting: .hour,
                                                     value: atHour,
                                                     of: triggerDate)!
            triggerDate = Calendar.calendarUTC0.date(bySetting: .minute,
                                                     value: atMinute,
                                                     of: triggerDate)!

            let diff = Calendar.calendarUTC0.dateComponents([.day, .hour, .minute], from: startDate, to: triggerDate)

            guard var day = diff.day,
                  var hour = diff.hour,
                  var minute = diff.minute
            else {
                fatalError("Internal error")
            }

            trigger.duration.is_neg = (day < 0 || hour < 0 || minute < 0) ? 1 : 0

            day = abs(day)
            hour = abs(hour)
            minute = abs(minute)

            trigger.duration.weeks = UInt32(day / 7)
            trigger.duration.days = UInt32(day % 7)
            trigger.duration.hours = UInt32(hour)
            trigger.duration.minutes = UInt32(minute)
        } else {
            trigger.duration.is_neg = (notificationData.beforeWeeks >= 0)
                && (notificationData.beforeDays >= 0)
                && (notificationData.beforeMinutes >= 0)
                && (notificationData.beforeHours >= 0) ? 1 : 0

            trigger.duration.weeks = UInt32(abs(notificationData.beforeWeeks))
            trigger.duration.days = UInt32(abs(notificationData.beforeDays))
            trigger.duration.hours = UInt32(abs(notificationData.beforeHours))

            trigger.duration.minutes = UInt32(abs(notificationData.beforeMinutes))
        }

        return trigger
    }
}
