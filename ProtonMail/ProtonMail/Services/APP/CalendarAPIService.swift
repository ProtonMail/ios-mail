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

import Combine
import ProtonCoreServices
import ProtonInboxICal
import ProtonInboxRSVP

struct CalendarAPIService {
    private let apiService: APIService

    init(apiService: APIService) {
        self.apiService = apiService
    }
}

extension CalendarAPIService: EventKeyPacketUpdating {
    func updateSharedKeyPacket(
        with sharedKeyPacket: String,
        calendarID: String,
        eventID: String
    ) -> AnyPublisher<Void, any Error> {
        let request = UpdateProtonToProtonInvitationRequest(
            calendarID: calendarID,
            eventID: eventID,
            sharedKeyPacket: sharedKeyPacket
        )

        return apiService.perform(request: request)
    }
}

extension CalendarAPIService: EventParticipationStatusUpdating {
    func updateParticipationStatus(
        with answer: AttendeeAnswer,
        updateTime: Date,
        calendarID: String,
        eventID: String,
        attendeeID: String
    ) -> AnyPublisher<Void, Error> {
        let status: AttendeeTransformer.Status

        switch answer {
        case .yes:
            status = .yes
        case .no:
            status = .no
        case .maybe:
            status = .maybe
        case .unanswered:
            status = .unanswered
        }

        let request = UpdateParticipationStatusRequest(
            attendeeID: attendeeID,
            calendarID: calendarID,
            eventID: eventID,
            status: status,
            updateTime: updateTime
        )

        return apiService.perform(request: request)
    }
}

extension CalendarAPIService: EventPersonalPartUpdating {
    func updatePersonalPart(
        with notifications: [ICalEvent.RawNotification]?,
        calendarID: String,
        eventID: String
    ) -> AnyPublisher<Void, any Error> {
        let apiNotifications: [EventNotification]? = notifications?.map { notification in
            let type: EventNotification.NotificationType

            switch notification.type {
            case .display:
                type = .push
            case .email:
                type = .email
            }

            return .init(type: type, trigger: notification.trigger)
        }

        let request = UpdatePersonalPartRequest(
            calendarID: calendarID,
            eventID: eventID,
            notifications: apiNotifications
        )

        return apiService.perform(request: request)
    }
}

extension CalendarAPIService: VTimeZonesInfoProviding {
    func vTimeZonesInfo(timeZoneIDs: [String]) -> AnyPublisher<any VTimeZonesInfo, any Error> {
        let request = VTimeZonesRequest(timeZoneIDs: timeZoneIDs)

        return apiService
            .perform(request: request)
            .map { (response: VTimeZoneResponse) in
                response
            }
            .eraseToAnyPublisher()
    }
}

extension VTimeZoneResponse: VTimeZonesInfo {
    var timeZones: [String: String] {
        timezones
    }
}
