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

public protocol EventDefaultNotificationsMetadata {
    var calendarID: String { get }
    var isAllDay: Bool { get }
}

extension ICalEvent: EventDefaultNotificationsMetadata {

    public var calendarID: String {
        calendarId
    }

}

public struct ICalEvent {

    public struct RawNotification: Equatable {
        public let type: ICalNotificationType
        public let trigger: String

        public init(type: ICalNotificationType, trigger: String) {
            self.type = type
            self.trigger = trigger
        }
    }

    // FIXME: - Those properties should not be here
    public var calendarId: String
    public var localEventId: String!
    public var apiEventId: String?
    public var sharedEventId: String?
    public var calendarKeyPacket: String?
    public var isOrganizer: Bool // false default
    public var isProtonToProtonInvitation: Bool
    public var rawNotifications: [RawNotification]?
    public var lastModifiedInCoreData: Date?

    public var recurrenceIDTimeZoneIdentifier: String?
    public var recurrenceIDIsAllDay: Bool?
    public var exdates: [Date]?
    public var exdatesTimeZoneIdentifiers: [String]?
    public var location: EKStructuredLocation?
    public var notes: String?
    public var status: String?
    public var organizer: ICalAttendee?
    public let addressKeyPacket: String?
    public var sharedEventID: String?
    public var sharedKeyPacket: String?
    public var icsUID: String
    public var createdTime: Date
    public var title: String?
    public var isAllDay: Bool
    public var startDate: Date
    public var startDateTimeZone: TimeZone
    public var startDateTimeZoneIdentifier: String
    public var endDate: Date
    public var endDateTimeZoneIdentifier: String
    public var endDateTimeZone: TimeZone
    public var recurrence: ICalRecurrence
    public let recommendedWKST: Int?
    public var recurrenceID: Date?
    public var notifications: [ICalNotification]?
    public var sequence: Int
    public var participants: [ICalAttendee]
    public var isOrphanSingleEdit: Bool
    public var recurringRulesLibical: icalrecurrencetype?
    public var invitationState: EKParticipantStatus
    public var mainEventRecurrence: ICalRecurrence?
    public var isFirstOccurrence: Bool = false
    public var isLastOccurrence: Bool = false
    public var numOfSelectedWeeklyOn: Int = 0
    public var ics: String
    public internal(set) var color: String?

    public init(
        calendarId: String,
        localEventId: String? = nil,
        apiEventId: String? = nil,
        sharedEventId: String? = nil,
        calendarKeyPacket: String? = nil,
        isOrganizer: Bool = false,
        isProtonToProtonInvitation: Bool,
        rawNotications: [RawNotification]?,
        lastModifiedInCoreData: Date? = nil,
        recurrenceIDTimeZoneIdentifier: String? = nil,
        recurrenceIDIsAllDay: Bool? = nil,
        exdates: [Date]? = nil,
        exdatesTimeZoneIdentifiers: [String]? = nil,
        location: EKStructuredLocation? = nil,
        notes: String? = nil,
        status: String? = nil,
        organizer: ICalAttendee? = nil,
        addressKeyPacket: String?,
        sharedEventID: String? = nil,
        sharedKeyPacket: String? = nil,
        icsUID: String,
        createdTime: Date,
        title: String? = nil,
        isAllDay: Bool = false,
        startDate: Date,
        startDateTimeZone: TimeZone,
        startDateTimeZoneIdentifier: String,
        endDate: Date,
        endDateTimeZoneIdentifier: String,
        endDateTimeZone: TimeZone,
        recurrence: ICalRecurrence = ICalRecurrence(),
        recommendedWKST: Int? = nil,
        recurrenceID: Date? = nil,
        notifications: [ICalNotification]? = nil,
        sequence: Int = 0,
        participants: [ICalAttendee] = [],
        recurringRulesLibical: icalrecurrencetype? = nil,
        invitationState: EKParticipantStatus = .unknown,
        isOrphanSingleEdit: Bool = false,
        mainEventRecurrence: ICalRecurrence? = nil,
        isFirstOccurrence _: Bool = false,
        isLastOccurrence _: Bool = false,
        numOfSelectedWeeklyOn: Int = 0,
        ics: String = "",
        color: String?
    ) {
        self.calendarId = calendarId
        self.localEventId = localEventId
        self.apiEventId = apiEventId
        self.sharedEventId = sharedEventId
        self.calendarKeyPacket = calendarKeyPacket
        self.isOrganizer = isOrganizer
        self.isProtonToProtonInvitation = isProtonToProtonInvitation
        self.rawNotifications = rawNotications
        self.lastModifiedInCoreData = lastModifiedInCoreData
        self.recurrenceIDTimeZoneIdentifier = recurrenceIDTimeZoneIdentifier
        self.recurrenceIDIsAllDay = recurrenceIDIsAllDay
        self.exdates = exdates
        self.exdatesTimeZoneIdentifiers = exdatesTimeZoneIdentifiers
        self.location = location
        self.notes = notes
        self.status = status
        self.organizer = organizer
        self.addressKeyPacket = addressKeyPacket
        self.sharedEventID = sharedEventID
        self.sharedKeyPacket = sharedKeyPacket
        self.icsUID = icsUID
        self.createdTime = createdTime
        self.title = title
        self.isAllDay = isAllDay
        self.startDate = startDate
        self.startDateTimeZone = startDateTimeZone
        self.startDateTimeZoneIdentifier = startDateTimeZoneIdentifier
        self.endDate = endDate
        self.endDateTimeZone = endDateTimeZone
        self.endDateTimeZoneIdentifier = endDateTimeZoneIdentifier
        self.recurrence = recurrence
        self.recommendedWKST = recommendedWKST
        self.recurrenceID = recurrenceID
        self.notifications = notifications
        self.sequence = sequence
        self.participants = participants
        self.recurringRulesLibical = recurringRulesLibical
        self.invitationState = invitationState
        self.isOrphanSingleEdit = isOrphanSingleEdit
        self.mainEventRecurrence = mainEventRecurrence
        self.numOfSelectedWeeklyOn = numOfSelectedWeeklyOn
        self.ics = ics
        self.color = color
    }
}

extension ICalEvent {
    func cloneForRecurringEvent(startingDateStringUTC: String) -> ICalEvent {
        var event = self
        let newStartDate = Date.getDateFrom(timeString: startingDateStringUTC)!.date

        let duration = self.endDate.timeIntervalSince1970 - self.startDate.timeIntervalSince1970

        event.startDate = newStartDate
        event.endDate = newStartDate.addingTimeInterval(duration)

        return event
    }

    func copy(changedRecurrence: ICalRecurrence) -> ICalEvent {
        var event = self
        event.recurrence = changedRecurrence

        guard self.recurrence.doesRepeat, self.recurrence.repeatEveryType == .week else {
            event.numOfSelectedWeeklyOn = 0
            return event
        }

        event.numOfSelectedWeeklyOn = self.recurrence.repeatWeekOn?.count ?? 0
        return event
    }

    func setStartDate(startDate: Date, timezone: String, startDateCalendar: Calendar) -> ICalEvent {
        var event = self
        event = event.maintainRecurrence(newStartDate: startDate, startDateCalendar: startDateCalendar)
        event = event.maintainRecurrence(newTimeZoneID: timezone)
        event.startDate = startDate
        event.startDateTimeZoneIdentifier = timezone
        event.startDateTimeZone = TimeZone(identifier: timezone)!
        return event
    }

    /// No conversion will happen here
    /// Expected endDate to be in UTC
    func setEndDate(endDate: Date, timezone: String) -> ICalEvent {
        var event = self
        event.endDate = endDate
        event.endDateTimeZoneIdentifier = timezone
        event.endDateTimeZone = TimeZone(identifier: timezone)!
        return event
    }

    func maintainRecurrence(newTimeZoneID: String) -> ICalEvent {
        var event = self
        guard self.isAllDay == false,
              var until = recurrence.endsOnDate
        else {
            return event
        }
        // to the last min of UTC0
        until = until.utcToLocal(timezone: event.startDateTimeZone)

        let newTimeZone = TimeZone(identifier: newTimeZoneID)!
        until = until.localToUTC(timezone: newTimeZone)

        event.recurrence = event.recurrence.copy(endsOnDate: until)
        return event
    }

    func maintainRecurrence(newStartDate: Date, startDateCalendar: Calendar) -> ICalEvent {
        var event = self
        let calendar = startDateCalendar
        switch self.recurrence.repeatEveryType {
        case .week:
            var setRepeatOn = Set<Int>(self.recurrence.repeatWeekOn ?? [])

            if self.numOfSelectedWeeklyOn <= setRepeatOn.count {
                let oldRepeatOn = calendar.component(.weekday, from: self.startDate)
                setRepeatOn.remove(oldRepeatOn)
            }

            let repeatOn = calendar.component(.weekday, from: newStartDate)
            setRepeatOn.insert(repeatOn)

            event.recurrence = event.recurrence.copy(repeatWeekOn: [Int](setRepeatOn).sorted())
        case .month:
            // if it was set to repeat on ith & weekday
            if self.recurrence.repeatMonthOnIth != nil {
                let isLast = calendar.isLastInWeekdayOrdinal(date: newStartDate)
                let ordinal = calendar.component(.weekdayOrdinal, from: newStartDate)

                if isLast, ordinal == 4 {
                    if self.recurrence.repeatMonthOnIth != .last {
                        let onIth = ICalRecurrence.RepeatMonthOnIth(value: ordinal - 1)
                        event.recurrence = event.recurrence.copy(repeatMonthOnIth: onIth)
                    }
                } else if isLast {
                    event.recurrence = event.recurrence.copy(repeatMonthOnIth: .last)
                } else {
                    let onIth = ICalRecurrence.RepeatMonthOnIth(value: ordinal - 1)
                    event.recurrence = event.recurrence.copy(repeatMonthOnIth: onIth)
                }

                let weekDay = calendar.component(.weekday, from: newStartDate)
                event.recurrence = event.recurrence.copy(repeatMonthOnWeekDay: weekDay)
            }
        default:
            break
        }

        if let endsOn = self.recurrence.endsOnDate, endsOn < newStartDate {
            event.recurrence = event.recurrence.copy(endsOnDate: newStartDate)
        }

        return event
    }
}
