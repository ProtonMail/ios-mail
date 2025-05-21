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

import Foundation
import proton_app_uniffi

struct ScheduleSendOptionsProvider {
    let scheduleSendOptions: () -> DraftScheduleSendOptionsResult
}

extension ScheduleSendOptionsProvider {

    static func dummy(
        isCustomAvailable: Bool,
        stubTomorrowTime: UInt64? = nil,
        stubMondayTime: UInt64? = nil,
        calendar: Calendar = .current
    ) -> ScheduleSendOptionsProvider {
        .init(
            scheduleSendOptions: {
                let now = Date()

                var components = DateComponents()
                components.hour = 8
                components.minute = 0
                components.second = 0
                let tomorrow = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime)!

                components.weekday = 2
                components.hour = 8
                components.minute = 0
                components.second = 0
                let nextMonday = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime)!

                return DraftScheduleSendOptionsResult.ok(
                    .init(
                        tomorrowTime: stubTomorrowTime ?? UInt64(tomorrow.timeIntervalSince1970),
                        mondayTime: stubMondayTime ?? UInt64(nextMonday.timeIntervalSince1970),
                        isCustomOptionAvailable: isCustomAvailable
                    ))
            }
        )
    }
}
