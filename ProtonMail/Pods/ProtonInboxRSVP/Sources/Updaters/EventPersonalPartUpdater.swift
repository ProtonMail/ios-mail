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

public struct EventPersonalPartUpdater {

    private struct UpdateEventPersonalPartPayload {
        let notifications: [ICalEvent.RawNotification]?
    }

    private let eventPersonalPartUpdater: EventPersonalPartUpdating

    public init(eventPersonalPartUpdater: EventPersonalPartUpdating) {
        self.eventPersonalPartUpdater = eventPersonalPartUpdater
    }

    public func updatePersonalPart(of event: ICalEvent, for answer: AttendeeAnswer) -> AnyPublisher<Void, Error> {
        let calendarID: String = event.calendarID
        let eventID: String = event.apiEventId.unsafelyUnwrapped

        guard let payload = updatePersonalPartPayload(event, answer) else {
            return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        return eventPersonalPartUpdater
            .updatePersonalPart(with: payload.notifications, calendarID: calendarID, eventID: eventID)
    }

    private func updatePersonalPartPayload(
        _ event: ICalEvent,
        _ answer: AttendeeAnswer
    ) -> UpdateEventPersonalPartPayload? {
        switch UpdateEventPersonalPartActionCalculator.action(for: event, with: answer) {
        case .updateWithDefaultNotifications:
            return .init(notifications: nil)
        case .updateWithEmptyNotifications:
            return .init(notifications: [])
        case .noUpdate:
            return nil
        }
    }
}
