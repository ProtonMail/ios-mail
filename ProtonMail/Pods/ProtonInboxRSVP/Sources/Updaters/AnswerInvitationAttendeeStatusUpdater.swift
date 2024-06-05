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

import Combine
import ProtonInboxICal

public struct AnswerInvitationAttendeeStatusUpdater {

    public struct Context {
        public let answer: AttendeeAnswer
        public let attendee: ICalAttendee
        public let currentDate: Date

        public init(answer: AttendeeAnswer, attendee: ICalAttendee, currentDate: Date) {
            self.answer = answer
            self.attendee = attendee
            self.currentDate = currentDate
        }
    }

    private let eventParticipationStatusUpdater: EventParticipationStatusUpdating
    private let attendeeStorage: AttendeeStorage

    public init(
        eventParticipationStatusUpdater: EventParticipationStatusUpdating,
        attendeeStatusStorage: AttendeeStorage
    ) {
        self.eventParticipationStatusUpdater = eventParticipationStatusUpdater
        self.attendeeStorage = attendeeStatusStorage
    }

    public func updateAttendeeStatus(
        at event: IdentifiableEvent,
        with context: Context
    ) -> AnyPublisher<Void, Error> {
        guard let attendeeID = attendeeStorage.attendeeID(for: context.attendee) else {
            return Fail(error: AnswerInvitationUseCaseError.missingAttendeeID).eraseToAnyPublisher()
        }

        return eventParticipationStatusUpdater
            .updateParticipationStatus(
                with: context.answer,
                updateTime: context.currentDate,
                calendarID: event.calendarID,
                eventID: event.id,
                attendeeID: attendeeID
            )
    }

}
