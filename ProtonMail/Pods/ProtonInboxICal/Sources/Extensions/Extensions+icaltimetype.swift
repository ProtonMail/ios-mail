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

public extension icaltimetype {
    /**
      - Parameter date: The date in UTC0 that will fill in the *icaltimetype*
      - Parameter timeZone: Default is nil. When this presents, it means the given date should be turn into local time before filling.
      - Parameter isAllDay: Indicating whether or not the time is all-day by setting the *is_date* in *icaltime*.

      # Further explanation

      - If *timeZone* is set **nil** and *isAllDay* is **false**, then the time will be set in Zulu time.
      - if *isAllDAy* is **true**, then we won't do the transofrmation on the date.

      # Notes

      * All day is floating time, which don't need transformation
         * But if the passed date is `firstMinuteDate` this kind of boundary, one has to make sure the day in UTC0 is what they want. This function won't do any transformation for all-day's date.
      * Part day should be localized, so we need timeZone to do the transformation here..
         * For **UNTIL**, this must be Zulu time. i.e. UTC0
     */
    init(_ date: Date, timeZone: TimeZone? = nil, isAllDay: Bool) {
        let isZulu = timeZone == nil && isAllDay == false

        var date = date
        if !isAllDay, let timeZone = timeZone {
            date = date.utcToLocal(timezone: timeZone)
        }

        self = icaltime_from_string(
            date.getTimestampString(isAllDay: isAllDay, isZulu: isZulu)
        )

        self.is_date = isAllDay ? 1 : 0
    }
}
