// Copyright (c) 2025 Proton Technologies AG
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

import Foundation

extension Date {
    /**
     Calculates a future date by applying an initial time buffer and then rounding up to the nearest specified minute interval.

     Example:

     ```swift
     let now = Date() // Assume current time is 10:07
     let roundedDate = now.roundedUp(
         by: 15,
         withInitialBuffer: 10
     )
     // roundedDate will be 10:30
     ```

     */
    func roundedUp(by minuteInterval: TimeInterval, withInitialBuffer bufferInMinutes: TimeInterval) -> Date {
        let futureTime = addingTimeInterval(bufferInMinutes * 60)
        let totalMinutes = futureTime.timeIntervalSince1970 / 60

        let numberOfMinuteBlocksRoundedUp = ceil(totalMinutes / minuteInterval)
        let finalNumberOfMinutes = numberOfMinuteBlocksRoundedUp * minuteInterval

        return Date(timeIntervalSince1970: finalNumberOfMinutes * 60)
    }
}
