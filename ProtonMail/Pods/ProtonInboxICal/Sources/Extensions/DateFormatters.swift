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

import Foundation

public enum DateFormatters {
    public enum Timestamp {
        public static let zulu: DateFormatter = {
            let formatter = makeUSUTC()
            formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            return formatter
        }()

        public static let zuluWithoutTimezone: DateFormatter = {
            let formatter = makeUSUTC()
            formatter.dateFormat = "yyyyMMdd'T'HHmmss"
            return formatter
        }()

        public static let allDay: DateFormatter = {
            let formatter = makeUSUTC()
            formatter.dateFormat = "yyyyMMdd"
            return formatter
        }()
    }

    static var allDay: ISO8601DateFormatter = {
        let formatter = makeISO8601UTC()
        formatter.formatOptions = [
            .withYear,
            .withMonth,
            .withDay
        ]
        return formatter
    }()

    static var partialDay: ISO8601DateFormatter = {
        let formatter = makeISO8601UTC()
        formatter.formatOptions = [
            .withYear,
            .withMonth,
            .withDay,
            .withTime
        ]
        return formatter
    }()

    static func makeUTC() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = .GMT
        return formatter
    }

    static func makeUSUTC() -> DateFormatter {
        let formatter = makeUTC()
        formatter.locale = .init(identifier: "en_US")
        return formatter
    }

    private static func makeISO8601UTC() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .GMT
        return formatter
    }
}
