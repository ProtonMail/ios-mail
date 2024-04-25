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

import ProtonInboxRSVP

extension AnswerInvitationUseCase {
    struct InMemoryCalendarKeyStorage: CalendarKeyStorage {
        let keyTransformers: [KeyTransformer]

        func activeKeys(calendarID: String) -> ActiveCalendarKeysInfo? {
            let activeCalendarKeys = keyTransformers.filter {
                $0.calendarID == calendarID && $0.flags.contains(.active)
            }

            guard let activePrimaryKey = activeCalendarKeys.first(where: { $0.flags.contains(.primary) }) else {
                assertionFailure("No active primary key")
                return nil
            }

            return .init(activePrimaryKey: activePrimaryKey, activeKeys: activeCalendarKeys)
        }
    }
}

extension KeyTransformer: CalendarKey {
    var id: String {
        ID
    }
}
