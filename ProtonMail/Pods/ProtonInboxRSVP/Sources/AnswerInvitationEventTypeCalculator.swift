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

import EventKit
import ProtonInboxICal

public struct AnswerInvitationEventTypeCalculator {

    public enum EventType {
        case nonRecurring
        case orphanSingleEdit
        case singleEdit
        case recurring(SingleEditsState)
    }

    public enum SingleEditsState {
        case noSingleEditsToReset
        case someSingleEditsToReset([EventToAnswer])
    }

    private let permissionValidator: AnswerToEventPermissionValidator

    public init(emailAddressStorage: EmailAddressStorage) {
        self.permissionValidator = .init(emailAddressStorage: emailAddressStorage)
    }

    public func eventType(
        for calendarEvent: CalendarEvent,
        and calendarDetails: CalendarInfo,
        with givenAnswer: AttendeeStatusDisplay
    ) -> EventType? {
        switch calendarEvent.eventType {
        case .singleEdit(let type):
            return type == .orphan ? .orphanSingleEdit : .singleEdit
        case .nonRecurring:
            return .nonRecurring
        case .recurring(let info):
            let singleEditState = singleEditsState(
                from: info.singleEdits,
                calendarDetails: calendarDetails,
                with: givenAnswer
            )

            return .recurring(singleEditState)
        case .encrypted:
            return nil
        }
    }

    private func singleEditsState(
        from singleEdits: [ICalEvent],
        calendarDetails: CalendarInfo,
        with givenAnswer: AttendeeStatusDisplay
    ) -> SingleEditsState {
        let allAnswered = singleEdits.filter { event in event.answerStatus != .unanswered }
        let nonMatching = allAnswered.filter { answeredEvent in answeredEvent.answerStatus != givenAnswer.answerStatus }
        let validatedContext = validatedContext(calendarDetails: calendarDetails)
        let eventsToReset = nonMatching.compactMap { event in
            EventToAnswer(event: event, validatedContext: validatedContext(event))
        }

        guard !eventsToReset.isEmpty else {
            return .noSingleEditsToReset
        }

        return .someSingleEditsToReset(.init(eventsToReset))
    }

    private func validatedContext(
        calendarDetails: CalendarInfo
    ) -> (ICalEvent) -> AnswerToEvent.ValidatedContext? {
        return { event in
            permissionValidator
                .canAnswer(for: event, with: calendarDetails)
                .validatedContext
        }
    }

}

private extension ICalEvent {

    var answerStatus: AttendeeAnswer {
        invitationState.attendeeAnswer
    }

}

private extension AttendeeStatusDisplay {

    var answerStatus: AttendeeAnswer {
        switch self {
        case .maybe:
            return .maybe
        case .no:
            return .no
        case .yes:
            return .yes
        }
    }

}

private extension AnswerToEvent.ValidationResult {

    var validatedContext: AnswerToEvent.ValidatedContext? {
        switch self {
        case .canAnswer(let validatedContext):
            return validatedContext
        case .canNotAnswer:
            return nil
        }
    }

}
