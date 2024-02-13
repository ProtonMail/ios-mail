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

public class ICalWriter {
    private let timestamp: () -> Date

    public init(timestamp: @escaping () -> Date) {
        self.timestamp = timestamp
    }

    // MARK: ics string generator

    /// Generates the ics string from the given VEVENT component pointer
    ///
    ///  This function will wrap it in a VCALENDAR object and not free the event pointer
    public func getICS(unsafeEvent: OpaquePointer) -> String {
        // If we only using the component but not clone the event pointer,
        // the free component for the parsed vcalendar component will fail.
        // Therefore, the only way to maintain the created pointer here
        // is to clone the event (deeply).
        let vCalendar = ICalVCalendarWriter(timestamp: timestamp)
        vCalendar.addSubComponent(safe: icalcomponent_clone(unsafeEvent))
        return iCalString(for: vCalendar.component)
    }

    /// Generates the ics string from the given CalendarModelEvent
    ///
    /// This function will wrap it in a VCALENDAR object
    public func getICS(event: ICalEvent) throws -> String {
        guard let vCalendar = try vCalendar(for: event, buildType: .allParts) else {
            fatalError("Can't get VEvent ics from CalendarModelEvent properly")
        }

        return iCalString(for: vCalendar.component)
    }

    /// Generates the invitation ICS string only from the given `ICalEvent`.
    ///
    /// This function will wrap it in a VCALENDAR object. If there is no data/VEvent in `ICalEvent`, the String will be nil
    public func invitationICS(event: ICalEvent, timeZones: [String], method: ICSMethod) throws -> String? {
        guard let vCalendar = try vCalendar(for: event, buildType: method.buildType) else { return nil }

        _ = vCalendar
            .addMethod(method.property)
            .addCalscale()

        timeZones.forEach { _ = vCalendar.addVTimeZone(ics: $0) }

        return ics(for: vCalendar)
    }

    public func getICS(event: ICalEvent, type: ICalVEventWriter.BuildType, timezones: [String]) throws -> String? {
        guard let vCalendar = try vCalendar(for: event, buildType: type) else { return nil }

        return ics(for: vCalendar)
    }

    private func vCalendar(for event: ICalEvent, buildType: ICalVEventWriter.BuildType) throws -> ICalVCalendarWriter? {
        try ICalVCalendarWriter(timestamp: timestamp).addVEvent(model: event, buildType)
    }

    private func ics(for vCalendar: ICalVCalendarWriter) -> String? {
        return vCalendar.isEmpty ? nil : iCalString(for: vCalendar.component)
    }

    private func iCalString(for vCalendarPointer: OpaquePointer) -> String {
        String(cString: icalcomponent_as_ical_string(vCalendarPointer))
    }
}

private extension ICSMethod {

    var buildType: ICalVEventWriter.BuildType {
        switch self {
        case .request(sessionKey: let sessionKey):
            return .invite(sesionKey: sessionKey)
        case .reply:
            return .reply
        case .cancel:
            return .cancel
        }
    }

    var property: icalproperty_method {
        switch self {
        case .request:
            return ICAL_METHOD_REQUEST
        case .reply:
            return ICAL_METHOD_REPLY
        case .cancel:
            return ICAL_METHOD_CANCEL
        }
    }

}
