// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCoreICS
import ProtonCoreServices

// sourcery: mock
protocol EventRSVP {
    func parseData(icsData: Data) async throws -> EventDetails
}

struct LocalEventRSVP: EventRSVP {
    private let apiService: APIService
    private let parser = ICSEventParser()

    init(apiService: APIService) {
        self.apiService = apiService
    }

    func parseData(icsData: Data) async throws -> EventDetails {
        guard let icsString = String(data: icsData, encoding: .utf8) else {
            throw EventRSVPError.dataIsNotValidUTF8String
        }

        let icsEvents = parser.parse(icsString: icsString)

        guard let relevantICSEvent = icsEvents.first else {
            throw EventRSVPError.noEventsInICS
        }

        let calendarEventsRequest = CalendarEventsRequest(uid: relevantICSEvent.uid)

        let calendarEventsResponse: CalendarEventsResponse = try await apiService.perform(
            request: calendarEventsRequest
        ).1

        // TODO: instead of `first`, we might need to add filtering by RecurrenceID (not supported by current parser)
        guard let apiEvent = calendarEventsResponse.events.first else {
            throw EventRSVPError.noEventsReturnedFromAPI
        }

        let calendarBootstrapRequest = CalendarBootstrapRequest(calendarID: apiEvent.calendarID)

        let calendarBootstrapResponse: CalendarBootstrapResponse = try await apiService.perform(
            request: calendarBootstrapRequest
        ).1

        guard let member = calendarBootstrapResponse.members.first else {
            throw EventRSVPError.noMembersInBootstrapResponse
        }

        return .init(
            title: "Team Collaboration Workshop",
            startDate: Date(timeIntervalSince1970: apiEvent.startTime),
            endDate: Date(timeIntervalSince1970: apiEvent.endTime),
            calendar: .init(
                name: member.name,
                iconColor: member.color
            ),
            location: .init(
                name: "Zoom call",
                url: URL(string: "https://zoom-call")!
            ),
            participants: [
                .init(email: "aubrey.thompson@proton.me", isOrganizer: true, status: .attending)
            ] + (1...3).map { .init(email: "participant.\($0)@proton.me", isOrganizer: false, status: .attending) }
        )
    }
}

enum EventRSVPError: Error {
    case dataIsNotValidUTF8String
    case noEventsInICS
    case noEventsReturnedFromAPI
    case noMembersInBootstrapResponse
}
