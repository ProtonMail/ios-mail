// FIXME: Temporary Rust interface to remove

import InboxCore

extension RsvpEventDetails: Copying {}
extension RsvpAttendee: Copying {}

typealias UnixTimestamp = UInt64

enum RsvpAnswer: CaseIterable, Hashable {
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
