// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCoreNetworking
import ProtonInboxRSVP

// MARK: requests and responses

enum CalendarAPI {
    static let prefix = "/calendar/v1"
}

struct CalendarEventsRequest: Request {
    let uid: String

    var path: String {
        "\(CalendarAPI.prefix)/events"
    }

    var parameters: [String: Any]? {
        [
            "UID": uid
        ]
    }
}

struct CalendarEventsResponse: Decodable {
    let events: [FullEventTransformer]
}

struct CalendarBootstrapRequest: Request {
    let calendarID: String

    var path: String {
        "\(CalendarAPI.prefix)/\(calendarID)/bootstrap"
    }
}

struct CalendarBootstrapResponse: Decodable {
    let keys: [KeyTransformer]
    let members: [MemberTransformer]
    let passphrase: PassphraseTransformer
}

struct UpdateParticipationStatusRequest: Request {
    let attendeeID: String
    let calendarID: String
    let eventID: String
    let status: AttendeeTransformer.Status
    let updateTime: Date

    var method: HTTPMethod {
        .put
    }

    var path: String {
        "\(CalendarAPI.prefix)/\(calendarID)/events/\(eventID)/attendees/\(attendeeID)"
    }

    var parameters: [String: Any]? {
        [
            "Status": status.rawValue,
            "UpdateTime": Int(updateTime.timeIntervalSince1970)
        ]
    }
}

struct UpdatePersonalPartRequest: Request {
    let calendarID: String
    let eventID: String
    let notifications: [EventNotification]?

    var method: HTTPMethod {
        .put
    }

    var path: String {
        "\(CalendarAPI.prefix)/\(calendarID)/events/\(eventID)/personal"
    }

    var parameters: [String: Any]? {
        if let notifications {
            return [
                "Notifications": notifications
            ]
        } else {
            return nil
        }
    }
}

struct UpdateProtonToProtonInvitationRequest: Request {
    let calendarID: String
    let eventID: String
    let sharedKeyPacket: String

    var method: HTTPMethod {
        .put
    }

    var path: String {
        "\(CalendarAPI.prefix)/\(calendarID)/events/\(eventID)/upgrade"
    }

    var parameters: [String: Any]? {
        [
            "SharedKeyPacket": sharedKeyPacket
        ]
    }
}

struct VTimeZonesRequest: Request {
    let timeZoneIDs: [String]

    var path: String {
        "\(CalendarAPI.prefix)/vtimezones"
    }

    var parameters: [String: Any]? {
        [
            "Timezones": timeZoneIDs
        ]
    }
}

struct VTimeZoneResponse: Decodable {
    let timezones: [String: String]
}

// MARK: models

struct AttendeeTransformer: Decodable {
    enum Status: Int, Codable {
        case unanswered = 0
        case maybe = 1
        case no = 2
        case yes = 3
    }

    let ID: String
    let status: Status
    let token: String
}

struct CalendarFlags: OptionSet, Decodable {
    let rawValue: UInt16

    static let disabledCalendar = CalendarFlags(rawValue: 1 << 5)
    static let superOwnerDisabledCalendar = CalendarFlags(rawValue: 1 << 6)
}

struct EventElement: Decodable {
    let data: String
    let type: SecurityFlags
}

struct EventNotification: Codable, Hashable {
    enum NotificationType: Int, CaseIterable, Codable {
        case email
        case push
    }

    let type: NotificationType
    let trigger: String
}

struct FullEventTransformer: Decodable {
    let ID: String
    let addressID: String?
    let addressKeyPacket: String?
    let attendees: [AttendeeTransformer]
    let attendeesEvents: [EventElement]
    let calendarEvents: [EventElement]
    let calendarID: String
    let calendarKeyPacket: String?
    let color: String?
    let recurrenceID: Int?
    let startTime: TimeInterval
    let startTimezone: String
    let endTime: TimeInterval
    let endTimezone: String
    let isOrganizer: Int
    let isProtonProtonInvite: Int
    let sharedEventID: String
    let sharedKeyPacket: String?
    let sharedEvents: [EventElement]
}

struct KeyTransformer: Decodable {
    struct Flags: OptionSet, Decodable {
        let rawValue: Int

        static let active = Self(rawValue: 1 << 0)
        static let primary = Self(rawValue: 1 << 1)
    }

    let ID: String
    let calendarID: String
    let flags: Flags
    let passphraseID: String
    let privateKey: String
}

struct MemberPassphraseTransformer: Decodable {
    let memberID: String
    let passphrase: String
}

struct MemberTransformer: Decodable {
    struct Permissions: OptionSet, Decodable {
        public let rawValue: UInt16

        static let superowner = Permissions(rawValue: 1 << 0)
    }

    let calendarID: String
    let color: String
    let flags: CalendarFlags
    let ID: String
    let name: String
    let permissions: Permissions
}

struct PassphraseTransformer: Decodable {
    let ID: String
    let memberPassphrases: [MemberPassphraseTransformer]
}

struct SecurityFlags: OptionSet, Codable, Equatable {
    let rawValue: UInt

    static let encrypted = SecurityFlags(rawValue: 1 << 0)
}
