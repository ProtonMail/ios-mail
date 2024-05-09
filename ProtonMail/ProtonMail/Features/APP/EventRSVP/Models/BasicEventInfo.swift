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

import Foundation

/// The minimum amount of information needed to fetch event data from the BE.
enum BasicEventInfo: Equatable {
    case inviteDataFromICS(eventUID: String, recurrenceID: Int?)
    case inviteDataFromHeaders(eventUID: String, recurrenceID: Int?)
    case reminderDataFromHeaders(eventUID: String, occurrence: Int, recurrenceID: Int?)

    var eventUID: String {
        switch self {
        case
                .inviteDataFromICS(let eventUID, _),
                .inviteDataFromHeaders(let eventUID, _),
                .reminderDataFromHeaders(let eventUID, _, _):
            return eventUID
        }
    }

    var isReminder: Bool {
        switch self {
        case .inviteDataFromICS, .inviteDataFromHeaders:
            return false
        case .reminderDataFromHeaders:
            return true
        }
    }

    var occurrence: Int? {
        switch self {
        case .inviteDataFromICS, .inviteDataFromHeaders:
            return nil
        case .reminderDataFromHeaders(_, let occurrence, _):
            return occurrence
        }
    }

    var recurrenceID: Int? {
        switch self {
        case
                .inviteDataFromICS(_, let recurrenceID),
                .inviteDataFromHeaders(_, let recurrenceID),
                .reminderDataFromHeaders(_, _, let recurrenceID):
            return recurrenceID
        }
    }

    init?(messageHeaders: [String: Any]) {
        guard let eventUID = messageHeaders[MessageHeaderKey.pmCalendarEventUID] as? String else {
            return nil
        }

        let isReminder = messageHeaders[MessageHeaderKey.pmCalendarCalendarID] != nil

        let occurrence = (messageHeaders[MessageHeaderKey.pmCalendarOccurrence] as? String)
            .flatMap { Int($0, radix: 10) }

        if isReminder, let occurrence {
            let recurrenceID = (messageHeaders[MessageHeaderKey.pmCalendarRecurrenceID] as? String)
                .flatMap { Int($0, radix: 10) }

            self = .reminderDataFromHeaders(eventUID: eventUID, occurrence: occurrence, recurrenceID: recurrenceID)
        } else {
            // NOTE: This is not a mistake. In case of invites, RecurrenceID is placed in the Occurence header
            let recurrenceID = occurrence
            self = .inviteDataFromHeaders(eventUID: eventUID, recurrenceID: recurrenceID)
        }
    }
}
