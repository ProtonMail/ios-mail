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

import ICalKitWrapper
import ProtonInboxICal

// sourcery: mock
protocol ExtractBasicEventInfo {
    func execute(icsData: Data) throws -> BasicEventInfo
}

struct ExtractBasicEventInfoImpl: ExtractBasicEventInfo {
    private let timeZoneProvider = TimeZoneProvider()

    func execute(icsData: Data) throws -> BasicEventInfo {
        guard let icsString = String(data: icsData, encoding: .utf8) else {
            throw EventRSVPError.icsDataIsNotValidUTF8String
        }

        let calendarComponent = icalparser_parse_string(icsString)

        defer {
            icalcomponent_free(calendarComponent)
        }

        let method = icalcomponent_get_method(calendarComponent)

        guard [ICAL_METHOD_REQUEST, ICAL_METHOD_CANCEL].contains(method) else {
            throw EventRSVPError.icsDoesNotContainSupportedMethod
        }

        guard let eventComponent = icalcomponent_get_first_component(calendarComponent, ICAL_VEVENT_COMPONENT) else {
            throw EventRSVPError.icsDoesNotContainEvents
        }

        guard let uidComponent = icalcomponent_get_uid(eventComponent) else {
            throw EventRSVPError.icsDoesNotContainUID
        }

        let uid = String(cString: uidComponent)
        let recurrenceID = parseRecurrenceID(from: eventComponent)
        return .inviteDataFromICS(eventUID: uid, recurrenceID: recurrenceID)
    }

    private func parseRecurrenceID(from eventComponent: OpaquePointer?) -> Int? {
        guard
            let recurrenceIDProperty = icalcomponent_get_first_property(eventComponent, ICAL_RECURRENCEID_PROPERTY)
        else {
            return nil
        }

        let timeZoneIdentifier: String
        if
            let timeZoneParameter = icalproperty_get_first_parameter(recurrenceIDProperty, ICAL_TZID_PARAMETER),
            let timeZoneCString = icalparameter_get_tzid(timeZoneParameter) {
            timeZoneIdentifier = String(cString: timeZoneCString)
        } else {
            timeZoneIdentifier = "GMT"
        }

        let timeZone = timeZoneProvider.timeZone(identifier: timeZoneIdentifier)

        guard let utcValue = icalcomponent_get_recurrenceid(eventComponent).toDate() else {
            return nil
        }

        let localValue = utcValue.localToUTC(timezone: timeZone)
        return Int(localValue.timeIntervalSince1970)
    }
}

private extension icaltimetype {
    func toDate() -> Date? {
        guard let cString = icaltime_as_ical_string(self) else {
            return nil
        }

        let string = String(cString: cString)
        return Date.getDateFrom(timeString: string)?.date
    }
}

private extension Date {
    func localToUTC(timezone: TimeZone) -> Date {
        let timeInterval = timeIntervalSince1970 - Double(timezone.secondsFromGMT(for: self))
        return Date(timeIntervalSince1970: timeInterval)
    }
}
