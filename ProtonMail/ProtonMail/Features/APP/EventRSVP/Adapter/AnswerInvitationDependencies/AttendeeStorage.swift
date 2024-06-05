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

import ProtonInboxICal
import ProtonInboxRSVP

extension AnswerInvitationUseCase {
    struct InMemoryAttendeeStorage: AttendeeStorage {
        let attendeeTransformers: [AttendeeTransformer]

        func attendeeID(for attendee: ICalAttendee) -> String? {
            let matchingAttendees = attendeeTransformers.filter { $0.token == attendee.token }
            assert(matchingAttendees.count == 1)
            return matchingAttendees.first?.ID
        }
    }
}
