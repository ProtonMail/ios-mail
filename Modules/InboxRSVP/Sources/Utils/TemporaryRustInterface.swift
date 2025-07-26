// FIXME: Temporary Rust interface to remove

typealias UnixTimestamp = UInt64

enum Answer: CaseIterable, Equatable {
    case yes
    case maybe
    case no
}

enum RsvpEventProgress {
    case pending
    case ongoing
    case ended
}

enum RsvpUnanswerableReason {
    case inviteIsOutdated
    case inviteHasUnknownRecency
}

enum RsvpState {
    case answerableInvite(progress: RsvpEventProgress, attendance: Attendance)
    case unanswerableInvite(RsvpUnanswerableReason)
    case cancelledInvite(isOutdated: Bool)
    case reminder(RsvpEventProgress)
    case cancelledReminder
}

struct RsvpEventDetails {
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

enum Attendance {
    case optional
    case required
}

enum RsvpOccurrence {
    case date
    case dateTime
}

enum RsvpAttendeeStatus {
    case unanswered
    case maybe
    case no
    case yes
}

struct RsvpOrganizer {
    var email: String
}

struct RsvpAttendee {
    var email: String
    var status: RsvpAttendeeStatus
}

struct RsvpCalendar {
    var name: String
    var color: String
}
