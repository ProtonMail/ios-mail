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

public class ICalVEventWriter: ICalComponentWriter {

    private let timeZoneProvider: TimeZoneProviderProtocol
    private let event: ICalEvent
    private let timestamp: () -> Date

    var vevent: OpaquePointer {
        self.component
    }

    init(
        event: ICalEvent,
        timestamp: @escaping () -> Date,
        timeZoneProvider: TimeZoneProviderProtocol = TimeZoneProvider()
    ) {
        self.event = event
        self.timestamp = timestamp
        self.timeZoneProvider = timeZoneProvider
        super.init(icalcomponent_new(ICAL_VEVENT_COMPONENT))
    }

    // MARK: Public func

    public enum BuildType: Equatable {
        case allParts
        case sharedSigned
        case sharedEncrypted
        case calendarSigned
        case attendeesEncrypted
        case reply
        case invite(sesionKey: String)
        case cancel

        /// This vairable will make the build not returning *nil* once it's empty
        var isEssential: Bool {
            self == .sharedSigned || self == .sharedEncrypted
        }
    }

    /// Constructs the rest needed components & properties.
    /// ### Notes
    ///  - Only generate when it's empty component. (no property nor subComponent generated before)
    ///  - Returns nil when it's empty component.
    func build(_ type: BuildType) throws -> Self? {
        guard self.isEmpty else {
            return nil
        }

        switch type {
        case .allParts:
            _ = try self
                .addDTStart()
                .addDTEnd()
                .addRRule()
                .addRecurrenceID()
                .addExdates()
                .addSequence()
                .addOrganizer()
                .addSummary()
                .addDescription()
                .addLocation()
                .addStatus()
                .addTransparency()

        case .sharedSigned:
            _ = try self
                .addDTStart()
                .addDTEnd()
                .addRRule()
                .addRecurrenceID()
                .addExdates()
                .addSequence()
                .addOrganizer()
                .addCreated()
                .addLastModified()

        case .sharedEncrypted:
            _ = try self
                .addSummary()
                .addDescription()
                .addLocation()

        case .calendarSigned:
            _ = self.addStatus()
                .addTransparency()

        case .reply:
            _ = try self
                .addDTStart()
                .addDTEnd()
                .addRRule()
                .addRecurrenceID()
                .addSequence()
                .addOrganizer()
                .addSummary()
                .addLocation()
                .addXPMReply()
                .addAttendees(type: .reply)

        case .invite(let sessionKey):
            _ = try self
                .addDTStart()
                .addDTEnd()
                .addRRule()
                .addRecurrenceID()
                .addSequence()
                .addOrganizer()
                .addSummary(default: "") // mandatory in RFC
                .addDescription()
                .addLocation()
                .addStatus()
                .addAttendees(type: .invitation)
                .addTransparency()
                .addSharedEventID()
                .addSessionKey(sessionKey)
        case .attendeesEncrypted:
            _ = try addAttendees(type: .invitation)
        case .cancel:
            _ = try addDTStart()
                .addDTEnd()
                .addRRule()
                .addRecurrenceID()
                .addSequence()
                .addOrganizer()
                .addSummary(default: "")
                .addDescription()
                .addLocation()
                .addStatus()
                .addTransparency()
                .addSharedEventID()
        }

        if type.isEssential == false, self.isEmpty {
            return nil
        }

        _ = self
            .addUID()
            .addDTStamp()

        return self
    }

    // MARK: Private func

    // MARK: Properties

    /// icsUID - exists in all parts
    private func addUID() -> Self {
        addProperty(safe: icalproperty_new_uid(self.event.icsUID))
        return self
    }

    /// exists in all parts
    private func addCreated() -> Self {
        let timeString = self.event.createdTime.getTimestampString(isAllDay: false, isZulu: true)
        addProperty(safe: icalproperty_new_created(icaltime_from_string(timeString)))
        return self
    }

    /// exists in all parts
    private func addLastModified() -> Self {
        let timestamp = Date.getCurrentZuluTimestampString(for: timestamp())
        addProperty(safe: icalproperty_new_lastmodified(icaltime_from_string(timestamp)))
        return self
    }

    /// Add only when summary exists
    /// - Parameter default: The default summary that will be used when event.title is nil. Default as nil.
    private func addSummary(default: String? = nil) throws -> Self {
        if let title = event.title ?? `default` {
            if title.count > ICalManagerConstants.maxSummaryLength {
                throw ICalManagerWriteError.summaryTooLong
            }

            addProperty(safe: icalproperty_new_summary(title))
        }
        return self
    }

    /// exists in all parts
    private func addDTStamp() -> Self {
        let timestamp = Date.getCurrentZuluTimestampString(for: timestamp())
        addProperty(safe: icalproperty_new_dtstamp(icaltime_from_string(timestamp)))
        return self
    }

    private func addDTStart() -> Self {
        addDate(
            date: event.startDate,
            timeZone: event.startDateTimeZone,
            timeZoneIdentifier: event.startDateTimeZoneIdentifier,
            dateTimePropertyFactory: icalproperty_new_dtstart
        )

        return self
    }

    /// Only add when it's not 0 duration
    private func addDTEnd() throws -> Self {
        guard self.event.startDate.getTimestampString(isAllDay: self.event.isAllDay, isZulu: true)
            != self.event.endDate.getTimestampString(isAllDay: self.event.isAllDay, isZulu: true)
        else {
            // drop DTEND
            // as the the range is [startDate, endDate)
            return self
        }

        guard self.event.startDate.compare(self.event.endDate) == .orderedAscending else { // Dependency
            throw ICalManagerWriteError.startDateIsAfterEndDate
        }

        addDate(
            date: event.endDate,
            timeZone: event.endDateTimeZone,
            timeZoneIdentifier: event.endDateTimeZoneIdentifier,
            dateTimePropertyFactory: icalproperty_new_dtend
        )

        return self
    }

    private func addDate(
        date: Date,
        timeZone: TimeZone,
        timeZoneIdentifier: String,
        dateTimePropertyFactory: (icaltimetype) -> OpaquePointer?
    ) {
        let isPartDayEvent = !event.isAllDay
        let icalTime: icaltimetype

        if isPartDayEvent && timeZone == .GMT {
            let formattedStartDateZulu = Date.getCurrentZuluTimestampString(for: date)
            icalTime = icaltime_from_string(formattedStartDateZulu)
        } else {
            icalTime = icaltimetype(date, timeZone: timeZone, isAllDay: event.isAllDay)
        }

        let dateTime = addProperty(safe: dateTimePropertyFactory(icalTime).unsafelyUnwrapped)

        if isPartDayEvent && timeZone != .GMT {
            let timeZoneID = icalparameter_new_tzid(timeZoneIdentifier).unsafelyUnwrapped
            dateTime.addParameter(safe: timeZoneID)
        }
    }

    /// only when convertion to recurrencetype succeeds
    private func addRRule() -> Self {
        if let icalrecurrencetype = ICalPropertyRRule().convert(recurring: event.recurrence,
                                                                startDateTimezone: event.startDateTimeZone,
                                                                isAllDay: event.isAllDay,
                                                                WKST: event.recommendedWKST)
        {
            _ = addProperty(safe: icalproperty_new_rrule(icalrecurrencetype))
        }
        return self
    }

    /// Only when recurrenceID exists
    private func addRecurrenceID() -> Self {
        // date-time type might be different from the start date, as it's overriding the main event!
        if let recurrenceID = event.recurrenceID,
           let recurrenceIDTimeZone = event.recurrenceIDTimeZoneIdentifier,
           let recurrenceIDIsAllDay = event.recurrenceIDIsAllDay
        {
            let timeZone = self.timeZoneProvider.timeZone(identifier: recurrenceIDTimeZone)
            let icalTime = icaltimetype(recurrenceID,
                                        timeZone: timeZone,
                                        isAllDay: recurrenceIDIsAllDay)
            let object = addProperty(safe: icalproperty_new_recurrenceid(icalTime))
            if recurrenceIDIsAllDay == false {
                object.addParameter(safe: icalparameter_new_tzid(recurrenceIDTimeZone))
            }
        }
        return self
    }

    /// Only when exdates exist
    private func addExdates() -> Self {
        if let exdates = event.exdates,
           let exdateTimeZones = event.exdatesTimeZoneIdentifiers
        {
            guard exdates.count == exdateTimeZones.count else {
                assertionFailure("Wrong usage")
                return self
            }

            for (exdate, timeZoneID) in zip(exdates, exdateTimeZones) {
                let timeZone = self.timeZoneProvider.timeZone(identifier: timeZoneID)
                let icalTime = icaltimetype(exdate,
                                            timeZone: timeZone,
                                            isAllDay: event.isAllDay)

                let object = addProperty(safe: icalproperty_new_exdate(icalTime))
                if self.event.isAllDay == false {
                    object.addParameter(safe: icalparameter_new_tzid(timeZoneID))
                }
            }
        }
        return self
    }

    /// Add only when location exists
    private func addLocation() throws -> Self {
        if let location = event.location?.title {
            if location.count > ICalManagerConstants.maxLocationLength {
                throw ICalManagerWriteError.locationTooLong
            }

            addProperty(safe: icalproperty_new_location(location))
        }
        return self
    }

    /// Add only when description exists
    private func addDescription() throws -> Self {
        if let notes = event.notes {
            if notes.count > ICalManagerConstants.maxDescriptionLength {
                throw ICalManagerWriteError.descriptionTooLong
            }

            addProperty(safe: icalproperty_new_description(notes))
        }
        return self
    }

    /**
     This property defines whether or not an event is transparent to busy time searches.

     ### Notes
     It has two possible values:
     * OPAQUE, default value if the property is not specified
     * TRANSPARENT
     */
    private func addTransparency() -> Self {
        addProperty(safe: icalproperty_new_transp(ICAL_TRANSP_OPAQUE))
        return self
    }

    private func addSequence() -> Self {
        addProperty(safe: icalproperty_new_sequence(Int32(event.sequence)))
        return self
    }

    // MARK: Invites

    /// Default is set as confirmed
    private func addStatus() -> Self {
        // default value
        var icalPropertyStatus: icalproperty_status = ICAL_STATUS_CONFIRMED
        if let status = event.status {
            switch status {
            case "TENTATIVE":
                icalPropertyStatus = ICAL_STATUS_TENTATIVE
            case "CONFIRMED":
                icalPropertyStatus = ICAL_STATUS_CONFIRMED
            case "CANCELLED":
                icalPropertyStatus = ICAL_STATUS_CANCELLED
            default:
                break
            }
        }
        addProperty(safe: icalproperty_new_status(icalPropertyStatus))
        return self
    }

    /// Add only when organizer exists
    private func addOrganizer() throws -> Self {
        if let organizer = event.organizer {
            if let object = ICalPropertyOrganizerWriter().build(model: organizer) {
                addProperty(object)
            } else {
                throw ICalManagerWriteError.failToBuildOrganizer
            }
        }
        return self
    }

    /// Reply flag ID
    private func addXPMReply() throws -> Self {
        guard event.isProtonToProtonInvitation else {
            return self
        }

        let prop = icalproperty_new_x("TRUE")!
        icalproperty_set_x_name(prop, "X-PM-PROTON-REPLY")

        let param = icalparameter_new_value(ICAL_VALUE_BOOLEAN)
        icalproperty_add_parameter(prop, param)

        addProperty(safe: prop)
        return self
    }

    /// shared event ID
    /// Throw when there's no `.sharedEventID`
    private func addSharedEventID() throws -> Self {
        guard let ID = event.sharedEventID else {
            throw ICalManagerWriteError.missingSharedEventID
        }

        let x = icalproperty_new_x(ID).unsafelyUnwrapped
        icalproperty_set_x_name(x, "X-PM-SHARED-EVENT-ID")
        addProperty(safe: x)
        return self
    }

    /// base64 of the unencrypted shared key packet, aka shared session key.
    private func addSessionKey(_ sessionKey: String) -> Self {
        let x = icalproperty_new_x(sessionKey).unsafelyUnwrapped
        icalproperty_set_x_name(x, "X-PM-SESSION-KEY")
        addProperty(safe: x)
        return self
    }

    /// Add all the attendees
    func addAttendees(type: AttendeeObjectType) throws -> Self {
        try event.participants.forEach { attendee in
            if let object = ICalPropertyAttendeeWriter().build(model: attendee, type: type) {
                addProperty(object)
            } else {
                throw ICalManagerWriteError.failToBuildAttendee
            }
        }
        return self
    }
}
