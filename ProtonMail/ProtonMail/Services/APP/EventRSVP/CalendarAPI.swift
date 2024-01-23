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

// MARK: requests and responses

enum CalendarAPI {
    static let prefix = "/calendar/v1"
}

struct CalendarEventsRequest: Request {
    let uid: String
    let recurrenceID: Int?

    var path: String {
        "\(CalendarAPI.prefix)/events"
    }

    var parameters: [String: Any]? {
        var params: [String: Any] = [
            "UID": uid
        ]
        params["RecurrenceID"] = recurrenceID
        return params
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

// MARK: models

struct AttendeeTransformer: Decodable {
    enum Status: Int, Decodable {
        case unanswered
        case maybe
        case no
        case yes
    }

    let status: Status?
}

struct EventElement: Decodable {
    let author: String
    let data: String
    let type: SecurityFlags
}

struct FullEventTransformer: Decodable {
    let addressID: String?
    let addressKeyPacket: String?
    let attendees: [AttendeeTransformer]
    let attendeesEvents: [EventElement]
    let calendarEvents: [EventElement]
    let calendarID: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let fullDay: Int
    let sharedKeyPacket: String?
    let sharedEvents: [EventElement]
}

struct KeyTransformer: Decodable {
    enum Flags: UInt8, Decodable {
        case inactive = 0
        case active = 1
        case activeAndPrimary = 3
    }

    let flags: Flags
    let passphraseID: String
    let privateKey: String
}

struct MemberPassphraseTransformer: Decodable {
    let memberID: String
    let passphrase: String
}

struct MemberTransformer: Decodable {
    let ID: String
    let color: String
    let name: String
}

struct PassphraseTransformer: Decodable {
    let ID: String
    let memberPassphrases: [MemberPassphraseTransformer]
}

public struct SecurityFlags: OptionSet, Codable, Equatable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let encrypted = SecurityFlags(rawValue: 1 << 0)
    public static let signed = SecurityFlags(rawValue: 1 << 1)
    public static let encryptedAndSigned: SecurityFlags = [.encrypted, .signed]
}
