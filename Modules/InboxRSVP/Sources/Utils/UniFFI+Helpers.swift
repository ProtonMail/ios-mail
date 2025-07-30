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
extension RsvpEvent: Copying {}

extension RsvpEventService: Equatable {

    static func == (lhs: RsvpEventService, rhs: RsvpEventService) -> Bool {
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
    case addressIsIncorrect
}

enum RsvpState: Hashable {
    case answerableInvite(progress: RsvpEventProgress, attendance: RsvpAttendance)
    case unanswerableInvite(reason: RsvpUnanswerableReason)
    case cancelledInvite(isOutdated: Bool)
    case reminder(progress: RsvpEventProgress)
    case cancelledReminder
}

struct RsvpEvent: Hashable {
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

enum RsvpEventGetResult {
    case ok(RsvpEvent)
    case error
}

protocol RsvpEventServiceProviderProtocol {
    func eventService() async -> RsvpEventService?
}

class RsvpEventServiceProvider: RsvpEventServiceProviderProtocol, @unchecked Sendable {
    func eventService() async -> RsvpEventService? {
        nil
    }
}

protocol RsvpEventServiceProtocol: AnyObject, Sendable {
    func answer(answer: RsvpAnswer) async -> VoidAnswerRsvpResult
    func get() -> RsvpEventGetResult
}

class RsvpEventService: RsvpEventServiceProtocol, @unchecked Sendable {
    func answer(answer: RsvpAnswer) async -> VoidAnswerRsvpResult {
        .ok
    }

    func get() -> RsvpEventGetResult {
        .error
    }
}
