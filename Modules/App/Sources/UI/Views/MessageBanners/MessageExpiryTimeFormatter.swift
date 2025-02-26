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

enum MessageExpiryTimeFormatter {
    static func string(from unixTimestamp: Int, currentDate: Date) -> String {
        let duration = MessageExpiryDurationCalculator.duration(from: unixTimestamp, currentDate: currentDate)
        let formatter = duration.isOneMinuteOrMore ? mainFormatter : lastMinuteFormatter

        return formatter.string(from: duration.interval).unsafelyUnwrapped
    }
    
    // MARK: - Private

    private static let mainFormatter = makeFormatter(units: [.day, .hour, .minute])
    private static let lastMinuteFormatter = makeFormatter(units: [.second])

    private static func makeFormatter(units: NSCalendar.Unit) -> DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = units
        formatter.unitsStyle = .full
        return formatter
    }
}
