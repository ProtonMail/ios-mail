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

public struct ICalNotification: Equatable {
    public var type: ICalNotificationType

    /// belongs to all-day event - must be filled
    public let atHour: Int?
    /// belongs to all-day event - must be filled
    public let atMinute: Int?
    /// shared variables between all-day and partial day events
    public let beforeWeeks: Int
    /// shared variables between all-day and partial day events
    public let beforeDays: Int

    // FIXME: use optional
    /// belongs to partial day event
    public let beforeHours: Int
    /// belongs to partial day event
    public let beforeMinutes: Int

    public init(
        type: ICalNotificationType,
        atHour: Int?,
        atMinute: Int?,
        beforeWeeks: Int = 0,
        beforeDays: Int = 0,
        beforeHours: Int = 0,
        beforeMinutes: Int = 0
    ) {
        self.type = type
        self.atHour = atHour
        self.atMinute = atMinute
        self.beforeWeeks = beforeWeeks
        self.beforeDays = beforeDays
        self.beforeHours = beforeHours
        self.beforeMinutes = beforeMinutes
    }
}
