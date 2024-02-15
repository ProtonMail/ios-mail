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

public protocol TimeZoneProviderProtocol {
    func timeZone(identifier: String) -> TimeZone
}

public class TimeZoneProvider: TimeZoneProviderProtocol {

    public init() {}

    func convertTimeZoneFromTable(identifier timezone: String) -> String? {
        if allowedTimeZones.contains(timezone) {
            return timezone
        }

        var convertedTimeZone: String?
        if let _convertedTimeZone = deprecatedTimezone[timezone] {
            convertedTimeZone = _convertedTimeZone
        }

        if let candidate = convertedTimeZone {
            if let _convertedTimeZone = aliasesTimezone[candidate] {
                convertedTimeZone = _convertedTimeZone
            }
        } else {
            if let _convertedTimeZone = aliasesTimezone[timezone] {
                convertedTimeZone = _convertedTimeZone
            }
        }

        if let candidate = convertedTimeZone {
            if let _convertedTimeZone = canonicalTimezones[candidate] {
                convertedTimeZone = _convertedTimeZone
            }
        } else {
            if let _convertedTimeZone = canonicalTimezones[timezone] {
                convertedTimeZone = _convertedTimeZone
            }
        }

        return convertedTimeZone
    }

    /**
     This function will take a time zone string, convert to the allowed timezones using conversion tables, and then return the TimeZone object
     */
    public func timeZone(identifier timezone: String) -> TimeZone {
        if let convertedTimeZone = self.convertTimeZoneFromTable(identifier: timezone) {
            guard let ret = TimeZone(identifier: convertedTimeZone) else {
                fatalError("TimeZone after conversion is not able to be created on iOS.")
            }
            return ret
        }

        guard let tz = TimeZone(identifier: timezone) else {
            fatalError("Original TimeZone is not able to be created on iOS.")
        }
        return tz
    }
}
