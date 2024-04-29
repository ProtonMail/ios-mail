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

import ProtonInboxICal

extension ICalEvent {

    func withoutWKST() -> Self {
        .init(
            calendarId: calendarID,
            localEventId: localEventId,
            apiEventId: apiEventId,
            sharedEventId: sharedEventId,
            calendarKeyPacket: calendarKeyPacket,
            isOrganizer: isOrganizer,
            isProtonToProtonInvitation: isProtonToProtonInvitation,
            rawNotications: rawNotifications,
            recurrenceIDTimeZoneIdentifier: recurrenceIDTimeZoneIdentifier,
            recurrenceIDIsAllDay: recurrenceIDIsAllDay,
            exdates: exdates,
            exdatesTimeZoneIdentifiers: exdatesTimeZoneIdentifiers,
            location: location,
            notes: notes,
            status: status,
            organizer: organizer,
            addressKeyPacket: addressKeyPacket,
            sharedEventID: sharedEventID,
            sharedKeyPacket: sharedKeyPacket,
            icsUID: icsUID,
            createdTime: createdTime,
            title: title,
            isAllDay: isAllDay,
            startDate: startDate,
            startDateTimeZone: startDateTimeZone,
            startDateTimeZoneIdentifier: startDateTimeZoneIdentifier,
            endDate: endDate,
            endDateTimeZoneIdentifier: endDateTimeZoneIdentifier,
            endDateTimeZone: endDateTimeZone,
            recurrence: recurrence,
            recommendedWKST: nil,
            recurrenceID: recurrenceID,
            notifications: notifications,
            sequence: sequence,
            participants: participants,
            recurringRulesLibical: recurringRulesLibical,
            invitationState: invitationState,
            isOrphanSingleEdit: isOrphanSingleEdit,
            mainEventRecurrence: mainEventRecurrence,
            isFirstOccurrence: isFirstOccurrence,
            isLastOccurrence: isLastOccurrence,
            numOfSelectedWeeklyOn: numOfSelectedWeeklyOn,
            ics: ics,
            color: color
        )
    }

}
