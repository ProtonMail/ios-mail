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

extension URL {
    enum ProtonCalendar {
        /// Only use this URL to detect if an old version of Calendar is installed.
        /// Old means without proper deep link support.
        static var legacyScheme: URL {
            URL(string: "ProtonCalendar://")!
        }

        static func eventDetails(for event: IdentifiableEvent) -> URL {
            let queryItems: [URLQueryItem] = [
                URLQueryItem(name: "eventID", value: event.id),
                URLQueryItem(name: "calendarID", value: event.calendarID),
                URLQueryItem(name: "startTime", value: "\(Int(event.startDate.timeIntervalSince1970))")
            ]

            if #available(iOS 16.0, *) {
                return URL(string: "ch.protonmail.calendar://eventDetails")!.appending(queryItems: queryItems)
            } else {
                var components = URLComponents()
                components.scheme = "ch.protonmail.calendar"
                components.host = "eventDetails"
                components.queryItems = queryItems
                return components.url!
            }
        }
    }
}
