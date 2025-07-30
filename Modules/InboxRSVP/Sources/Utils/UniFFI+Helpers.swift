// Copyright (c) 2025 Proton Technologies AG
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

import InboxCore

extension RsvpAttendee: Copying {}
extension RsvpEventDetails: Copying {}

extension RsvpEvent: Equatable {

    static func == (lhs: RsvpEvent, rhs: RsvpEvent) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

}

// FIXME: Temporary Rust interface to remove
typealias UnixTimestamp = UInt64

enum RsvpAnswer: Hashable {
    case yes
    case maybe
    case no
}

enum RsvpEventProgress: Hashable {
    case pending
    case ongoing
    case ended
}

enum RsvpUnanswerableReason: Hashable {
    case inviteIsOutdated
    case inviteHasUnknownRecency
}

enum RsvpState: Hashable {
    case answerableInvite(progress: RsvpEventProgress, attendance: RsvpAttendance)
    case unanswerableInvite(reason: RsvpUnanswerableReason)
    case cancelledInvite(isOutdated: Bool)
    case reminder(progress: RsvpEventProgress)
    case cancelledReminder
}

struct RsvpEventDetails: Hashable {
    var id: String?
    var summary: String?
    var location: String?
    var description: String?
    var recurrence: String?
    var startsAt: UnixTimestamp
    var endsAt: UnixTimestamp
    var occurrence: RsvpOccurrence
    var organizer: RsvpOrganizer
    var attendees: [RsvpAttendee]
    var userAttendeeIdx: UInt32
    var calendar: RsvpCalendar?
    var state: RsvpState
}

enum RsvpRecency {
    case fresh
    case outdated
    case unknown
}

enum RsvpAttendance: Hashable {
    case optional
    case required
}

enum RsvpOccurrence: Hashable {
    case date
    case dateTime
}

enum RsvpAttendeeStatus: Hashable {
    case unanswered
    case maybe
    case no
    case yes
}

struct RsvpOrganizer: Hashable {
    var name: String?
    var email: String
}

struct RsvpAttendee: Hashable {
    var name: String?
    var email: String
    var status: RsvpAttendeeStatus
}

struct RsvpCalendar: Hashable {
    var id: String
    var name: String
    var color: String
}

enum VoidAnswerRsvpResult {
    case ok
    case error
}

enum RsvpEventDetailsResult {
    case ok(RsvpEventDetails)
    case error
}

protocol RsvpEventIdProtocol {
    func fetch() async -> RsvpEvent?
}

class RsvpEventId: RsvpEventIdProtocol, @unchecked Sendable {
    func fetch() async -> RsvpEvent? {
        nil
    }
}

protocol RsvpEventProtocol: AnyObject, Sendable {
    func answer(answer: RsvpAnswer) async -> VoidAnswerRsvpResult
    func details() -> RsvpEventDetailsResult
}

class RsvpEvent: RsvpEventProtocol, @unchecked Sendable {
    func answer(answer: RsvpAnswer) async -> VoidAnswerRsvpResult {
        .ok
    }

    func details() -> RsvpEventDetailsResult {
        .error
    }
}
