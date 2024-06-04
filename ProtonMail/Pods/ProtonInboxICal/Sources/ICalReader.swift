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

import EventKit

public class ICalReader {

    public init(
        timeZoneProvider: TimeZoneProvider,
        currentDateProvider: @escaping () -> Date,
        icsUIDProvider: @escaping () -> String,
        iCalWriter: ICalWriter
    ) {
        self.timeZoneProvider = timeZoneProvider
        self.currentDateProvider = currentDateProvider
        self.icsUIDProvider = icsUIDProvider
        self.iCalWriter = iCalWriter
    }

    private let timeZoneProvider: TimeZoneProvider
    private let currentDateProvider: () -> Date
    private let icsUIDProvider: () -> String
    private let iCalWriter: ICalWriter

    private func getConvertedDate(time: String, isAllDay: Bool, timezone _timezone: String?) -> (date: Date, timezone: String) {
        if let timezone = _timezone {
            if isAllDay == true {}

            // time is local time
            let dateObj = Date.getDateFrom(timeString: time)!.date

            return (dateObj, timezone)
        } else {
            // no timezone -> Zulu or all-day
            let timezone = TimeZone.GMT.identifier

            let dateObj = Date.getDateFrom(timeString: time)!.date
            return (dateObj, timezone)
        }
    }

    /**
     This function parses the ics string into CalendarModelEvent
     */
    private func parse(eventComponent: OpaquePointer, attendeeData: [ICalAttendeeData], dependecies: ICalReaderDependecies) -> ICalEvent {
        var event = ICalEvent(
            calendarId: dependecies.calendarID,
            isProtonToProtonInvitation: dependecies.isProtonToProtonInvitation,
            rawNotications: dependecies.notifications,
            addressKeyPacket: dependecies.addressKeyPacket,
            icsUID: icsUIDProvider(),
            createdTime: currentDateProvider(),
            startDate: dependecies.startDate,
            startDateTimeZone: dependecies.startDateTimeZone,
            startDateTimeZoneIdentifier: dependecies.startDateTimeZoneIdentifier,
            endDate: dependecies.endDate,
            endDateTimeZoneIdentifier: dependecies.endDateTimeZoneIdentifier,
            endDateTimeZone: dependecies.endDateTimeZone,
            color: dependecies.color
        )

        // FIXME: - move assigning those properties higher
        event.localEventId = dependecies.localEventID
        event.apiEventId = dependecies.apiEventID
        event.sharedEventID = dependecies.sharedEventID
        event.sharedKeyPacket = dependecies.sharedKeyPacket
        event.calendarKeyPacket = dependecies.calendarKeyPacket
        event.isOrganizer = dependecies.isOrganizer
        event.lastModifiedInCoreData = dependecies.lastModifiedInCoreData

        // uid
        let _uid = icalcomponent_get_uid(eventComponent).toString
        guard let uid = _uid else {
            fatalError()
        }

        event.icsUID = uid

        // created
        if let icsCreatedTimePointer = icalcomponent_get_first_property(eventComponent,
                                                                        ICAL_CREATED_PROPERTY)
        {
            let icsCreatedTime = icalproperty_get_created(icsCreatedTimePointer)
            let createdTimeString = icaltime_as_ical_string(icsCreatedTime).toString.unsafelyUnwrapped
            event.createdTime = self.getConvertedDate(time: createdTimeString,
                                                      isAllDay: false,
                                                      timezone: nil).date
        }

        // dtstart, dtend
        // DTEND >= DTSTART
        // DTEND can be missing for 0 duration event
        let _dtstart_icaltime = icalcomponent_get_dtstart(eventComponent)
        event.isAllDay = _dtstart_icaltime.is_date > 0 ? true : false
        let _dtstart = icaltime_as_ical_string(_dtstart_icaltime).toString
        guard let dtstart = _dtstart else {
            fatalError("Missing DTSTART")
        }
        let _dtstart_timezone = self.getTimezone(property: icalcomponent_get_first_property(eventComponent,
                                                                                            ICAL_DTSTART_PROPERTY))

        let _dtend_timezone: String?
        let _dtend_icaltime: icaltimetype
        let dtend: String
        if let dtEndProperty = icalcomponent_get_first_property(eventComponent,
                                                                ICAL_DTEND_PROPERTY)
        {
            _dtend_timezone = self.getTimezone(property: dtEndProperty)
            _dtend_icaltime = icalcomponent_get_dtend(eventComponent)
            dtend = icaltime_as_ical_string(_dtend_icaltime).toString.unsafelyUnwrapped
        } else {
            if _dtstart_icaltime.is_date == 1 {
                // all-day event, DTEND = DTSTART + 1
                _dtend_timezone = _dtstart_timezone
                var tmp = self.getConvertedDate(time: dtstart,
                                                isAllDay: event.isAllDay,
                                                timezone: _dtend_timezone).date
                tmp = Calendar.calendarUTC0.date(byAdding: .day, value: 1, to: tmp)!
                dtend = tmp.getTimestampString(isAllDay: event.isAllDay,
                                               isZulu: false)
                _dtend_icaltime = icaltime_from_string(dtend)
            } else {
                // partial day event, DTEND = DTSTART
                _dtend_timezone = _dtstart_timezone
                _dtend_icaltime = _dtstart_icaltime
                dtend = dtstart
            }
        }

        guard _dtstart_icaltime.is_date == _dtend_icaltime.is_date else {
            fatalError() // FIXME:
        }

        // If no timezone is present, it's assumed to be ZULU timezone
        // As for non-all-day events, timezone MUST always be present. Thus, without specifying the timezone, we assume it to be ZULU (UTC)
        let eventStartDate = self.getConvertedDate(time: dtstart,
                                                   isAllDay: event.isAllDay,
                                                   timezone: _dtstart_timezone) // ZULU will be assumed if no timezone is present
        event = event.setStartDate(
            startDate: eventStartDate.date.localToUTC(timezone: self.timeZoneProvider.timeZone(identifier: eventStartDate.timezone)),
            timezone: eventStartDate.timezone,
            startDateCalendar: dependecies.startDateCalendar
        )
        let eventEndDate = self.getConvertedDate(time: dtend,
                                                 isAllDay: event.isAllDay,
                                                 timezone: _dtend_timezone)
        event = event.setEndDate(
            endDate: eventEndDate.date.localToUTC(timezone: self.timeZoneProvider.timeZone(identifier: eventEndDate.timezone)), // Fix me
            timezone: eventEndDate.timezone
        )

        // sequence
        event.sequence = Int(icalcomponent_get_sequence(eventComponent))

        // title
        event.title = icalcomponent_get_summary(eventComponent).toString // ical summary = title

        // location
        let _location = icalcomponent_get_location(eventComponent).toString
        if let location = _location {
            event.location = EKStructuredLocation(title: location)
        }

        // notes
        event.notes = icalcomponent_get_description(eventComponent).toString

        // status
        let status = icalcomponent_get_status(eventComponent)
        switch status {
        case ICAL_STATUS_TENTATIVE:
            event.status = "TENTATIVE"
        case ICAL_STATUS_CONFIRMED:
            event.status = "CONFIRMED"
        case ICAL_STATUS_CANCELLED:
            event.status = "CANCELLED"
        default:
            break
        }

        // recurring rules
        var recurringProperty = icalcomponent_get_first_property(eventComponent,
                                                                 ICAL_RRULE_PROPERTY)
        while recurringProperty != nil {
            let recurring = icalproperty_get_rrule(recurringProperty)
            event.recurringRulesLibical = recurring

            if let convertedRecurring = ICalPropertyRRule().convert(dtstart: _dtstart_icaltime, rrule: recurring) {
                event = event.copy(changedRecurrence: convertedRecurring)
            }

            recurringProperty = icalcomponent_get_next_property(eventComponent,
                                                                ICAL_RRULE_PROPERTY)
        }

        // recurrenceID: date-time type might be different from the start date
        // Consider the following case that the main event's start time is in partial day format,
        // but the single edited event's start time is in full-day format
        //
        // Thus, we can't infer the date-time type from the start time of the single edited event for the recurrence-ID
        if let recurrenceIDProperty = icalcomponent_get_first_property(eventComponent,
                                                                       ICAL_RECURRENCEID_PROPERTY)
        {
            let _recurrenceID_icaltime = icalcomponent_get_recurrenceid(eventComponent)
            let _recurrenceID = icaltime_as_ical_string(_recurrenceID_icaltime).toString

            if let recurrenceID = _recurrenceID {
                let recur = Date.getDateFrom(timeString: recurrenceID)

                if let recur = recur {
                    event.recurrenceIDIsAllDay = recur.mainEventIsAllDay

                    if recur.mainEventIsAllDay == false {
                        // If no timezone is present, it's assumed to be ZULU timezone
                        // As for non-all-day events, timezone MUST always be present. Thus, without specifying the timezone, we assume it to be ZULU (UTC)
                        let timeZoneString = self.getTimezone(property: recurrenceIDProperty) ?? TimeZone.GMT.identifier
                        event.recurrenceID = Date.getDateFrom(timeString: recurrenceID)?.date.localToUTC(timezone: self.timeZoneProvider.timeZone(identifier: timeZoneString))

                        if event.recurrenceID == nil {

                        } else {
                            event.recurrenceIDTimeZoneIdentifier = self.timeZoneProvider.convertTimeZoneFromTable(identifier: timeZoneString)
                        }
                    } else {
                        event.recurrenceID = recur.date
                        event.recurrenceIDTimeZoneIdentifier = TimeZone.GMT.identifier
                    }
                }
            }
        }

        // exdate
        var exdate: OpaquePointer? = icalcomponent_get_first_property(eventComponent,
                                                                      ICAL_EXDATE_PROPERTY)
        if exdate != nil {
            event.exdates = []
            event.exdatesTimeZoneIdentifiers = []
        }
        while exdate != nil {
            let exdateProperty = icalproperty_get_exdate(exdate!)
            let exdateString = icaltime_as_ical_string(exdateProperty).toString

            if let _exdate_timezone = self.getTimezone(property: exdate!) {
                if _exdate_timezone != _dtstart_timezone {

                } else {
                    if let exdateString = exdateString {
                        if let t = timeZoneProvider.convertTimeZoneFromTable(identifier: _exdate_timezone),
                           let d = Date.getDateFrom(timeString: exdateString)?.date.localToUTC(timezone: timeZoneProvider.timeZone(identifier: t))
                        {
                            event.exdates?.append(d)
                            event.exdatesTimeZoneIdentifiers?.append(t)
                        }
                    }
                }
            } else {
                // zulu
                if let exdateString = exdateString {
                    event.exdates?.append(Date.getDateFrom(timeString: exdateString)!.date)
                    event.exdatesTimeZoneIdentifiers?.append(TimeZone.GMT.identifier)
                }
            }

            exdate = icalcomponent_get_next_property(eventComponent,
                                                     ICAL_EXDATE_PROPERTY)
        }

        // organizer / attendee
        let attendeeRet = ICalPropertyAttendee.getAttendee(calendarID: dependecies.calendarID,
                                                           localEventID: dependecies.localEventID,
                                                           eventComponent: eventComponent,
                                                           attendeeData: attendeeData)

        // organizer must exist, attendee can be none
        if let organizer = attendeeRet.organizer {
            event.organizer = organizer
            event.participants = attendeeRet.participants

            // We need to keep track of event.invitationState
            // Case 1: we are the organizer
            // Case 2: we are the attendee

            let userEmailAddresses = dependecies.addresses.map(\.email.canonicalizedEmailAddress)

            if let organizerCanonizedEmailAddress = attendeeRet.organizer?.user.email.canonicalizedEmailAddress,
               userEmailAddresses.contains(organizerCanonizedEmailAddress),
               let organizerStatus = event.organizer?.status
            {
                // Case 1
                event.invitationState = organizerStatus
            } else if let particiapnt = CurrentUserParticipantResolver.resolve(
                participants: attendeeRet.participants,
                addresses: dependecies.addresses
            ) {
                // Case 2
                event.invitationState = particiapnt.atendee.status
            }
        }

        // add event to map
        event.ics = self.iCalWriter.getICS(unsafeEvent: eventComponent)

        return event
    }

    public func parse_single_event_ics(dependecies: ICalReaderDependecies, attendeeData: [ICalAttendeeData]) -> ICalEvent {
        // If the string contains only one component, the parser will return the component in libical form.
        // If the string contains multiple components, the multiple components will be returned as the children of an ICAL_XROOT_COMPONENT component -> according to our assumption, it will be 1 VCALENDAR
        guard let calendarComponent = icalparser_parse_string(dependecies.ics) else {
            fatalError()
        }

        defer {
            icalcomponent_free(calendarComponent)
        }

        // The assumption is that there is always one VCALENDAR and it encapsulates the VEVENT(s)
        var _eventComponent = icalcomponent_get_first_component(calendarComponent, ICAL_VEVENT_COMPONENT)

        guard let eventComponent = _eventComponent else {
            fatalError("should have exactly 1 event")
        }

        let ret = self.parse(eventComponent: eventComponent, attendeeData: attendeeData, dependecies: dependecies)

        // get next event in component
        _eventComponent = icalcomponent_get_next_component(calendarComponent, ICAL_VEVENT_COMPONENT)
        guard _eventComponent == nil else {
            fatalError("should ONLY have 1 event")
        }

        return ret
    }

    /**
     The data must contain single edits, otherwise the modification be disregarded which is probably not the use case that you intended for.
     */
    public func parse_recurring_event_ics(dependecies: [ICalReaderDependecies], leftBoundDate: Date, rightBoundDate: Date, attendeeData: [ICalAttendeeData], calendar: Calendar) -> [ICalEvent] {
        var ret = [ICalEvent]()
        // case 1: main event + recurrenceID
        // case 2: only recurrenceID (orphan)

        var rootRecurringEventIdx = -1 // root recurring event
        var events = [ICalEvent]()

        // find the root recurring event
        for (i, tmp) in dependecies.enumerated() {
            // token is not enough to distinquich the single-edits
            let attendees = attendeeData.filter { $0.eventID == tmp.apiEventID }
            let event = self.parse_single_event_ics(dependecies: tmp, attendeeData: attendees)
            events.append(event)
            if event.recurringRulesLibical != nil {
                if rootRecurringEventIdx == -1 {
                    rootRecurringEventIdx = i
                }
            }
        }

        // all orphan events
        guard rootRecurringEventIdx >= 0 else {
            for i in 0 ..< events.count {
                events[i].isOrphanSingleEdit = true
            }
            return events
        }

        // main event exists
        let rootEvent = events[rootRecurringEventIdx]

        // fill in the data

        // get recurring event starting times within the given starting and ending dates
        var recurringEventUTCStartingTimes = [String]()

        recurringEventUTCStartingTimes = ICalPropertyRRule().generateStartTimeUTC(event: rootEvent,
                                                                                  leftBoundDate: leftBoundDate,
                                                                                  rightBoundDate: rightBoundDate,
                                                                                  calendar: calendar).startingTime

        // drop time that is same as single-edit's
        for i in 0 ..< events.count {
            if i == rootRecurringEventIdx {
                continue
            }

            guard let recurrenceID = events[i].recurrenceID else {
                continue
            }

            // append ret using events with recurrenceIDs
            // we need to add the single edit if it's in the range
            if events[i].startDate.compare(rightBoundDate) == .orderedAscending,
               events[i].endDate.compare(leftBoundDate) == .orderedDescending { // start < rightBound && end > leftBound
                ret.append(events[i])
            }

            // we don't need to take into account start times that are equal to this recurrence id
            if let firstIndex = recurringEventUTCStartingTimes.firstIndex(of: recurrenceID.getTimestampString(isAllDay: rootEvent.isAllDay, isZulu: true)) {
                recurringEventUTCStartingTimes.remove(at: firstIndex)
            }
        }

        // ret so far only has single-edits that are within the range we want
        for index in 0 ..< ret.count {
            ret[index].mainEventRecurrence = rootEvent.recurrence // add recurrence rules for display
        }

        // gen rest recurring events using time listing
        recurringEventUTCStartingTimes.forEach { time in
            ret.append(rootEvent.cloneForRecurringEvent(startingDateStringUTC: time))
        }

        // MARK: first/last occurrence flags

        if let firstStartTimeString = ICalPropertyRRule().getFirstOccurrenceStartTimeString(event: rootEvent),
           let firstStartDate = Date.getDateFrom(timeString: firstStartTimeString)?.date
        {
            let index = ret.firstIndex(where: { event in
                if let recurrenceID = event.recurrenceID {
                    return recurrenceID == firstStartDate
                }
                return event.startDate == firstStartDate
            })

            if index != nil {
                ret[index!].isFirstOccurrence = true
            }
        }

        if rootEvent.recurrence.endsNever == false,
           let lastStartTimeString = ICalPropertyRRule().getLastOccurrenceStartTimeString(event: rootEvent, calendar: calendar),
           let lastStartDate = Date.getDateFrom(timeString: lastStartTimeString)?.date
        {
            let index = ret.firstIndex(where: { event in
                if let recurrenceID = event.recurrenceID {
                    return recurrenceID == lastStartDate
                }
                return event.startDate == lastStartDate
            })

            if index != nil {
                ret[index!].isLastOccurrence = true
            }
        }

        return ret
    }

    /**
     This function merges the ics file components together, as the ics files from the API is split
     */
    private func merge(oldEventComponent: OpaquePointer, newEventComponent: OpaquePointer, date: Date) -> String {
        // create new VEVENT component
        let vevent: OpaquePointer = icalcomponent_new(ICAL_VEVENT_COMPONENT)
        defer {
            icalcomponent_free(vevent)
        }

        // created, lastmodified, dtstamp
        // icaltime_today() // FIXME: can't get current time from this function for some reason
        let current = icaltime_from_string(Date.getCurrentZuluTimestampString(for: date))
        let created = icalproperty_new_created(current)
        icalcomponent_add_property(vevent,
                                   created)
        let lastModified = icalproperty_new_lastmodified(current)
        icalcomponent_add_property(vevent,
                                   lastModified)
        let dtstamp = icalproperty_new_dtstamp(current)
        icalcomponent_add_property(vevent,
                                   dtstamp)

        // uid
        let _oldUID = icalcomponent_get_uid(oldEventComponent).toString
        guard let oldUID = _oldUID else {
            fatalError()
        }
        let _newUID = icalcomponent_get_uid(newEventComponent).toString
        guard let newUID = _newUID else {
            fatalError()
        }

        if oldUID != newUID {

        }
        let uid = icalproperty_new_uid(oldUID)
        icalcomponent_add_property(vevent,
                                   uid)

        // sequence
        if let property = icalcomponent_get_first_property(oldEventComponent,
                                                           ICAL_SEQUENCE_PROPERTY)
        {
            icalcomponent_add_property_clone(vevent,
                                             property)
        } else if let property = icalcomponent_get_first_property(newEventComponent,
                                                                  ICAL_SEQUENCE_PROPERTY)
        {
            icalcomponent_add_property_clone(vevent,
                                             property)
        }

        // status
        if let property = icalcomponent_get_first_property(oldEventComponent,
                                                           ICAL_STATUS_PROPERTY)
        {
            icalcomponent_add_property_clone(vevent,
                                             property)
        } else if let property = icalcomponent_get_first_property(newEventComponent,
                                                                  ICAL_STATUS_PROPERTY)
        {
            icalcomponent_add_property_clone(vevent,
                                             property)
        }

        // title
        if let property = icalcomponent_get_first_property(oldEventComponent,
                                                           ICAL_SUMMARY_PROPERTY)
        {
            icalcomponent_add_property_clone(vevent,
                                             property)
        } else if let property = icalcomponent_get_first_property(newEventComponent,
                                                                  ICAL_SUMMARY_PROPERTY)
        {
            icalcomponent_add_property_clone(vevent,
                                             property)
        }

        // location
        if let property = icalcomponent_get_first_property(oldEventComponent,
                                                           ICAL_LOCATION_PROPERTY)
        {
            icalcomponent_add_property_clone(vevent,
                                             property)
        } else if let property = icalcomponent_get_first_property(newEventComponent,
                                                                  ICAL_LOCATION_PROPERTY)
        {
            icalcomponent_add_property_clone(vevent,
                                             property)
        }

        // notes
        if let property = icalcomponent_get_first_property(oldEventComponent,
                                                           ICAL_DESCRIPTION_PROPERTY)
        {
            icalcomponent_add_property_clone(vevent,
                                             property)
        } else if let property = icalcomponent_get_first_property(newEventComponent,
                                                                  ICAL_DESCRIPTION_PROPERTY)
        {
            icalcomponent_add_property_clone(vevent,
                                             property)
        }

        // dtstart, dtend
        // DTEND >= DTSTART
        // DTEND can be missing for 0 duration event
        if let dtstart = icalcomponent_get_first_property(oldEventComponent,
                                                          ICAL_DTSTART_PROPERTY)
        {
            icalcomponent_add_property_clone(vevent,
                                             dtstart)

            if let dtEndProperty = icalcomponent_get_first_property(oldEventComponent,
                                                                    ICAL_DTEND_PROPERTY)
            {
                icalcomponent_add_property_clone(vevent,
                                                 dtEndProperty)
            }
        } else if let dtstart = icalcomponent_get_first_property(newEventComponent,
                                                                 ICAL_DTSTART_PROPERTY)
        {
            icalcomponent_add_property_clone(vevent,
                                             dtstart)

            if let dtEndProperty = icalcomponent_get_first_property(newEventComponent,
                                                                    ICAL_DTEND_PROPERTY)
            {
                icalcomponent_add_property_clone(vevent,
                                                 dtEndProperty)
            }
        }

        // alarm
        var alarm: OpaquePointer?
        var evc: OpaquePointer?
        if let tmp = icalcomponent_get_first_component(oldEventComponent,
                                                       ICAL_VALARM_COMPONENT)
        {
            alarm = tmp
            evc = oldEventComponent
        } else if let tmp = icalcomponent_get_first_component(newEventComponent,
                                                              ICAL_VALARM_COMPONENT)
        {
            alarm = tmp
            evc = newEventComponent
        }

        while alarm != nil {
            icalcomponent_add_component_clone(vevent,
                                              alarm!)

            alarm = icalcomponent_get_next_component(evc!,
                                                     ICAL_VALARM_COMPONENT)
        }

        // recurring
        var recurring: OpaquePointer?
        evc = nil
        if let tmp = icalcomponent_get_first_property(oldEventComponent,
                                                      ICAL_RRULE_PROPERTY)
        {
            recurring = tmp
            evc = oldEventComponent
        } else if let tmp = icalcomponent_get_first_property(newEventComponent,
                                                             ICAL_RRULE_PROPERTY)
        {
            recurring = tmp
            evc = newEventComponent
        }

        while recurring != nil {
            icalcomponent_add_property_clone(vevent,
                                             recurring!)

            recurring = icalcomponent_get_next_property(evc!,
                                                        ICAL_RRULE_PROPERTY)
        }

        // RECURRECE-ID
        if let property = icalcomponent_get_first_property(oldEventComponent,
                                                           ICAL_RECURRENCEID_PROPERTY)
        {
            icalcomponent_add_property_clone(vevent,
                                             property)
        } else if let property = icalcomponent_get_first_property(newEventComponent,
                                                                  ICAL_RECURRENCEID_PROPERTY)
        {
            icalcomponent_add_property_clone(vevent,
                                             property)
        }

        unionExdates(from: oldEventComponent, and: newEventComponent).forEach { exdate in
            icalcomponent_add_property_clone(vevent, exdate)
        }

        // organizer
        if let property = icalcomponent_get_first_property(oldEventComponent,
                                                           ICAL_ORGANIZER_PROPERTY)
        {
            icalcomponent_add_property_clone(vevent,
                                             property)
        } else if let property = icalcomponent_get_first_property(newEventComponent,
                                                                  ICAL_ORGANIZER_PROPERTY)
        {
            icalcomponent_add_property_clone(vevent,
                                             property)
        }

        // attendee
        var attendee: OpaquePointer?
        evc = nil
        if let tmp = icalcomponent_get_first_property(oldEventComponent,
                                                      ICAL_ATTENDEE_PROPERTY)
        {
            attendee = tmp
            evc = oldEventComponent
        } else if let tmp = icalcomponent_get_first_property(newEventComponent,
                                                             ICAL_ATTENDEE_PROPERTY)
        {
            attendee = tmp
            evc = newEventComponent
        }

        while attendee != nil {
            icalcomponent_add_property_clone(vevent,
                                             attendee!)

            attendee = icalcomponent_get_next_property(evc!,
                                                       ICAL_ATTENDEE_PROPERTY)
        }

        return self.iCalWriter.getICS(unsafeEvent: vevent)
    }

    public func parse_and_merge_event_ics(old: String, new: String, date: () -> Date = Date.init) -> String {
        // If the string contains only one component, the parser will return the component in libical form.
        // If the string contains multiple components, the multiple components will be returned as the children of an ICAL_XROOT_COMPONENT component -> according to our assumption, it will be 1 VCALENDAR
        guard let oldCalendarComponent = icalparser_parse_string(old) else {
            fatalError()
        }
        defer {
            icalcomponent_free(oldCalendarComponent)
        }

        guard new.isEmpty == false else {
            return old
        }

        guard let newCalendarComponent = icalparser_parse_string(new) else {
            fatalError()
        }
        defer {
            icalcomponent_free(newCalendarComponent)
        }

        // The assumption is that there is always one VCALENDAR and it encapsulates the VEVENT(s)
        var _oldEventComponent = icalcomponent_get_first_component(oldCalendarComponent,
                                                                   ICAL_VEVENT_COMPONENT)
        guard let oldEventComponent = _oldEventComponent else {
            fatalError("should have exactly 1 event")
        }

        var _newEventComponent = icalcomponent_get_first_component(newCalendarComponent,
                                                                   ICAL_VEVENT_COMPONENT)
        guard let newEventComponent = _newEventComponent else {
            fatalError("should have exactly 1 event")
        }

        let ret = merge(oldEventComponent: oldEventComponent, newEventComponent: newEventComponent, date: date())

        // get next event in component
        _oldEventComponent = icalcomponent_get_next_component(oldCalendarComponent,
                                                              ICAL_VEVENT_COMPONENT)
        guard _oldEventComponent == nil else {
            fatalError("should ONLY have 1 event")
        }

        _newEventComponent = icalcomponent_get_next_component(newCalendarComponent,
                                                              ICAL_VEVENT_COMPONENT)
        guard _newEventComponent == nil else {
            fatalError("should ONLY have 1 event")
        }

        return ret
    }

    private func getTimezone(property: OpaquePointer) -> String? {
        let _timezone_parameter = icalproperty_get_first_parameter(property,
                                                                   ICAL_TZID_PARAMETER)
        if _timezone_parameter == nil {
            return nil
        }

        return icalparameter_get_tzid(_timezone_parameter).toString
    }

    private func unionExdates(
        from oldEventComponent: OpaquePointer,
        and newEventComponent: OpaquePointer
    ) -> [OpaquePointer] {
        let oldExdates = exdates(fromEventComponent: oldEventComponent)
        let newExdates = exdates(fromEventComponent: newEventComponent)
        return unionExdates(oldExdates, newExdates)
    }

    private func exdates(fromEventComponent eventComponent: OpaquePointer) -> [OpaquePointer] {
        let exdateProperty: icalproperty_kind = ICAL_EXDATE_PROPERTY

        var exdate: OpaquePointer? = icalcomponent_get_first_property(eventComponent, exdateProperty)
        var exdates: [OpaquePointer] = []

        while let unwrappedExdate = exdate {
            exdates.append(unwrappedExdate)
            exdate = icalcomponent_get_next_property(eventComponent, exdateProperty)
        }

        return exdates
    }

    private func unionExdates(_ first: [OpaquePointer], _ second: [OpaquePointer]) -> [OpaquePointer] {
        let allExdatePointers: [OpaquePointer] = first + second
        let allExdates: [icaltimetype] = allExdatePointers.map(icalproperty_get_exdate)

        var uniqueExdatePointers: [OpaquePointer] = []
        var uniqueExdates: [icaltimetype] = []

        zip(allExdatePointers, allExdates).forEach { exdatePointer, exdate in
            if !uniqueExdates.contains(exdate) {
                uniqueExdatePointers.append(exdatePointer)
                uniqueExdates.append(exdate)
            }
        }

        return uniqueExdatePointers
    }
}

extension icaltimetype: Equatable {

    public static func ==(lhs: icaltimetype, rhs: icaltimetype) -> Bool {
        icaltime_compare(lhs, rhs) == 0
    }

}
