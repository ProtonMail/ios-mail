//
//  ExternalURL.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

extension URL {
    enum AppStore {
        private static let baseURL = URL(string: "itms-apps://itunes.apple.com/app")!

        static var calendar: URL {
            baseURL.appendingPathComponent("id1514709943")
        }

        static var mail: URL {
            baseURL.appendingPathComponent("id979659905")
        }
    }

    enum ProtonCalendar {
        /// Only use this URL to detect if an old version of Calendar is installed.
        /// Old means without proper deep link support.
        static var legacyScheme: URL {
            URL(string: "ProtonCalendar://")!
        }

        private static func baseURL(host: String) -> URL {
            URL(string: "ch.protonmail.calendar://\(host)")!
        }

        static func showEvent(apiEventID: String, calendarID: String, startTime: Int) -> URL {
            let queryItems: [URLQueryItem] = [
                URLQueryItem(name: "eventID", value: apiEventID),
                URLQueryItem(name: "calendarID", value: calendarID),
                URLQueryItem(name: "startTime", value: "\(startTime)")
            ]

            if #available(iOS 16.0, *) {
                return baseURL(host: "eventDetails").appending(queryItems: queryItems)
            } else {
                var components = URLComponents()
                components.scheme = "protoncalendar"
                components.host = "eventDetails"
                components.queryItems = queryItems
                return components.url!
            }
        }
    }
}
