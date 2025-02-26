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

enum MessageExpiryDurationCalculator {
    struct ExpiryDuration {
        let interval: TimeInterval
       
        var isOneMinuteOrMore: Bool {
            interval >= 60
        }
    }

    static func duration(from unixTimestamp: Int, currentDate: Date) -> ExpiryDuration {
        let expiryDate = Date(timeIntervalSince1970: TimeInterval(unixTimestamp))
        let timeInterval = expiryDate.timeIntervalSince(currentDate)

        return .init(interval: max(timeInterval, 0))
    }
}
