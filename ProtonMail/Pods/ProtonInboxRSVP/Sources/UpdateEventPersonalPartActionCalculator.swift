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

public enum UpdateEventPersonalPartActionCalculator {
    public enum Action {
        case updateWithDefaultNotifications
        case updateWithEmptyNotifications
        case noUpdate
    }

    public static func action(for event: ICalEvent, with answer: AttendeeAnswer) -> Action {
        let notificationsState = notificationsState(of: event)
        let from = event.invitationState.attendeeAnswer
        let to = answer

        switch (notificationsState, from, to) {
        case
            (.null, .unanswered, .yes),
            (.null, .unanswered, .maybe),
            (.null, .no, .yes),
            (.null, .no, .maybe),
            (.empty, .unanswered, .yes),
            (.empty, .unanswered, .maybe),
            (.empty, .no, .yes),
            (.empty, .no, .maybe):
            return .updateWithDefaultNotifications
        case
            (_, .unanswered, .no),
            (_, .yes, .no),
            (_, .maybe, .no),
            (_, .yes, .unanswered),
            (_, .maybe, .unanswered),
            (_, .no, .unanswered):
            return .updateWithEmptyNotifications
        case
            (.nonEmpty, .unanswered, .yes),
            (.nonEmpty, .unanswered, .maybe),
            (.nonEmpty, .no, .yes),
            (.nonEmpty, .no, .maybe),
            (_, .yes, .maybe),
            (_, .maybe, .yes),
            (_, .no, .no),
            (_, .maybe, .maybe),
            (_, .yes, .yes),
            (_, .unanswered, .unanswered):
            return .noUpdate
        }
    }

    private enum NotificationsState {
        case null
        case empty
        case nonEmpty
    }

    private static func notificationsState(of event: ICalEvent) -> NotificationsState {
        switch event.notifications {
        case .some(let notifications):
            return notifications.isEmpty ? .empty : .nonEmpty
        case .none:
            return .null
        }
    }
}
