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

import ProtonInboxICal

// sourcery: mock
protocol ExtractBasicEventInfo {
    func execute(icsData: Data) throws -> BasicEventInfo
}

struct ExtractBasicEventInfoImpl: ExtractBasicEventInfo {
    func execute(icsData: Data) throws -> BasicEventInfo {
        guard let icsString = String(data: icsData, encoding: .utf8) else {
            throw EventRSVPError.icsDataIsNotValidUTF8String
        }

        let component = icalparser_parse_string(icsString)

        defer {
            icalcomponent_free(component)
        }

        guard let uidComponent = icalcomponent_get_uid(component) else {
            throw EventRSVPError.icsDataDoesNotContainUID
        }

        let uid = String(cString: uidComponent)
        let recurrenceID = icalcomponent_get_recurrenceid(component).toUnixTimestamp()
        return BasicEventInfo(eventUID: uid, recurrenceID: recurrenceID)
    }
}

private extension icaltimetype {
    func toUnixTimestamp() -> Int? {
        guard let cString = icaltime_as_ical_string(self) else {
            return nil
        }

        let string = String(cString: cString)

        guard let date = Date.getDateFrom(timeString: string)?.date else {
            return nil
        }

        return Int(date.timeIntervalSince1970)
    }
}
