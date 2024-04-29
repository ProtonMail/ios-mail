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

public struct EventsToResetAnswerRepository {

    private let eventTypeCalculator: AnswerInvitationEventTypeCalculator

    public init(emailAddressStorage: EmailAddressStorage) {
        self.eventTypeCalculator = .init(emailAddressStorage: emailAddressStorage)
    }

    public func singleEditsToReset(
        notMatchingWith answer: AttendeeStatusDisplay,
        calendarEvent: CalendarEvent,
        calendarDetails: CalendarInfo
    ) -> [EventToAnswer] {
        switch eventTypeCalculator.eventType(for: calendarEvent, and: calendarDetails, with: answer) {
        case .singleEdit, .orphanSingleEdit, .nonRecurring, .none:
            return []
        case .recurring(let recurringType):
            return eventsToReset(for: recurringType)
        }
    }

    private func eventsToReset(
        for singleEditsState: AnswerInvitationEventTypeCalculator.SingleEditsState
    ) -> [EventToAnswer] {
        switch singleEditsState {
        case .noSingleEditsToReset:
            return []
        case .someSingleEditsToReset(let eventsToReset):
            return eventsToReset
        }
    }

}
