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
import Foundation

enum ICalPropertyAttendee {
    /**
     Setup both organizer and attendees

     Currently we assume there will only be at most 1 organizer (might have none)

     If you have attendees you must have exactly one organizer (for REQUEST for eg https://tools.ietf.org/html/rfc2446#section-3.2.2)

     If you don’t have any attendees the field can be omitted

     The organizer might be in the attendee list in ProtonMail, but for other providers, this is not guaranteed
     */
    static func getAttendee(calendarID: String, localEventID: String, eventComponent: OpaquePointer, attendeeData: [ICalAttendeeData]) -> (organizer: ICalAttendee?, participants: [ICalAttendee]) {
        let organizerProperty = icalcomponent_get_first_property(eventComponent,
                                                                 ICAL_ORGANIZER_PROPERTY)

        var organizer: ICalAttendee?
        if let organizerProperty = organizerProperty,
           let value = icalproperty_get_value_as_string(organizerProperty).toString {

            organizer = ICalAttendee(
                calendarId: calendarID,
                localEventId: localEventID,
                user: .init(
                    name: icalproperty_get_parameter_as_string(organizerProperty, "CN").toString,
                    email: value.deletingPrefix("mailto:")
                ),
                role: .chair,
                status: .unknown,
                token: nil
            )
        }

        // loop over attendees
        var attendee = icalcomponent_get_first_property(eventComponent, ICAL_ATTENDEE_PROPERTY)
        if attendee == nil {
            return (organizer, [])
        }

        var participants: [ICalAttendee] = []
        while attendee != nil {
            let token = icalproperty_get_parameter_as_string(attendee, "X-PM-TOKEN").toString
            let cn = icalproperty_get_parameter_as_string(attendee, "CN").toString

            let roleString = icalproperty_get_parameter_as_string(attendee, "ROLE").toString
            let role = EKParticipantRole(icalString: roleString)

            let email = (icalproperty_get_value_as_string(attendee).toString ?? "").deletingPrefix("mailto:")

            var status: EKParticipantStatus = .unknown
            for i in 0 ..< attendeeData.count { // should consist of data for both organizer and participant
                if attendeeData[i].token == token {
                    // Participation status of the attendee: 0: Unanswered, 1: Maybe, 2: No, 3: Yes
                    switch attendeeData[i].status {
                    case 0:
                        status = .pending
                    case 1:
                        status = .tentative
                    case 2:
                        status = .declined
                    case 3:
                        status = .accepted
                    default:
                        status = .unknown
                    }

                    break
                }
            }

            // It's possible the cn is empty based on ICS Surgery
            if let organizerEmail = organizer?.user.email {
                // set organizer status
                if cn == organizer?.user.name,
                   email == organizerEmail,
                   let prevOrganizer = organizer
                {
                    organizer = .init(
                        calendarId: calendarID,
                        localEventId: localEventID,
                        user: prevOrganizer.user,
                        role: prevOrganizer.role,
                        status: status,
                        token: nil
                    )
                }
            }

            participants.append(
                ICalAttendee(
                    calendarId: calendarID,
                    localEventId: localEventID,
                    user: .init(name: cn, email: email),
                    role: role,
                    status: status,
                    token: token
                )
            )

            attendee = icalcomponent_get_next_property(eventComponent,
                                                       ICAL_ATTENDEE_PROPERTY)
        }

        if organizer?.user.email == nil {
            return (nil, [])
        }

        return (organizer, participants)
    }
}
