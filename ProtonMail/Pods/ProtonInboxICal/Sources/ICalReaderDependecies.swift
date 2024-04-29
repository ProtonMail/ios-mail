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

public struct ICalReaderDependecies {
    public let startDate: Date
    public let startDateTimeZone: TimeZone
    public let startDateTimeZoneIdentifier: String
    public let endDate: Date
    public let endDateTimeZoneIdentifier: String
    public let endDateTimeZone: TimeZone
    public let calendarID: String
    public let localEventID: String
    public let allEmailsCanonized: [String]
    public let ics: String
    public let apiEventID: String?
    public let startDateCalendar: Calendar
    public let color: String?

    // FIXME: - Those properties should not be here
    public let addressKeyPacket: String?
    public let sharedEventID: String?
    public let sharedKeyPacket: String?
    public let calendarKeyPacket: String?
    public let isOrganizer: Bool
    public let isProtonToProtonInvitation: Bool
    public let notifications: [ICalEvent.RawNotification]?
    public let lastModifiedInCoreData: Date?

    public init(
        startDate: Date,
        startDateTimeZone: TimeZone,
        startDateTimeZoneIdentifier: String,
        endDate: Date,
        endDateTimeZoneIdentifier: String,
        endDateTimeZone: TimeZone,
        calendarID: String,
        localEventID: String,
        allEmailsCanonized: [String],
        ics: String,
        apiEventID: String?,
        startDateCalendar: Calendar,
        addressKeyPacket: String?,
        sharedEventID: String?,
        sharedKeyPacket: String?,
        calendarKeyPacket: String?,
        isOrganizer: Bool,
        isProtonToProtonInvitation: Bool,
        notifications: [ICalEvent.RawNotification]?,
        lastModifiedInCoreData: Date?,
        color: String?
    ) {
        self.startDate = startDate
        self.startDateTimeZone = startDateTimeZone
        self.startDateTimeZoneIdentifier = startDateTimeZoneIdentifier
        self.endDate = endDate
        self.endDateTimeZoneIdentifier = endDateTimeZoneIdentifier
        self.endDateTimeZone = endDateTimeZone
        self.calendarID = calendarID
        self.localEventID = localEventID
        self.allEmailsCanonized = allEmailsCanonized
        self.ics = ics
        self.apiEventID = apiEventID
        self.startDateCalendar = startDateCalendar
        self.sharedEventID = sharedEventID
        self.addressKeyPacket = addressKeyPacket
        self.sharedKeyPacket = sharedKeyPacket
        self.calendarKeyPacket = calendarKeyPacket
        self.isOrganizer = isOrganizer
        self.isProtonToProtonInvitation = isProtonToProtonInvitation
        self.notifications = notifications
        self.lastModifiedInCoreData = lastModifiedInCoreData
        self.color = color
    }
}
