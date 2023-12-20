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

import ProtonCoreNetworking

// MARK: requests and responses

enum CalendarAPI {
    static let prefix = "/calendar/v1"
}

struct CalendarEventsRequest: Request {
    let uid: String

    var path: String {
        "\(CalendarAPI.prefix)/events"
    }

    var parameters: [String: Any]? {
        ["UID": uid]
    }
}

struct CalendarEventsResponse: Decodable {
    let events: [FullEventTransformer]
}

struct CalendarBootstrapRequest: Request {
    let calendarID: String

    var path: String {
        "\(CalendarAPI.prefix)/\(calendarID)/bootstrap"
    }
}

struct CalendarBootstrapResponse: Decodable {
    let members: [MemberTransformer]
}

// MARK: models

struct FullEventTransformer: Decodable {
    let calendarID: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let fullDay: Int
}

struct MemberTransformer: Decodable {
    let color: String
    let name: String
}
