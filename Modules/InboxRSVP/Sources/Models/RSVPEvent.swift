import Foundation
import InboxCoreUI

struct RSVPEvent {
    enum AnswerButtonsState {
        case visible(Attendance)
        case hidden
    }

    struct Banner {
        let style: RSVPHeaderView.Style
        let regularText: LocalizedStringResource
        let boldText: LocalizedStringResource

        init(
            style: RSVPHeaderView.Style,
            regularText: LocalizedStringResource,
            boldText: LocalizedStringResource = "".notLocalized.stringResource
        ) {
            self.style = style
            self.regularText = regularText
            self.boldText = boldText
        }
    }

    struct Participant {
        let displayName: String
        let status: RsvpAttendeeStatus
    }

    let title: String
    let banner: Banner?
    let formattedDate: String
    let answerButtons: AnswerButtonsState
    let initialStatus: RsvpAttendeeStatus
    let calendar: RsvpCalendar?
    let recurrence: String?
    let location: String?
    let organizer: RsvpOrganizer
    let participants: [Participant]
}

enum RsvpEventDetailsMapper {
    static func map(_ details: RsvpEventDetails) -> RSVPEvent {
        let formattedDate = RSVPDateFormatter.string(
            from: details.startsAt,
            to: details.endsAt,
            occurrence: details.occurrence
        )
        let initialStatus = details.attendees[Int(details.userAttendeeIdx)].status
        let participants = details.attendees.enumerated().map { index, attendee in
            let isCurrentUser = index == details.userAttendeeIdx
            let displayName = isCurrentUser ? L10n.Details.you(email: attendee.email).string : attendee.email

            return RSVPEvent.Participant(displayName: displayName, status: attendee.status)
        }

        return RSVPEvent(
            title: details.summary ?? L10n.noEventTitlePlacholder.string,
            banner: banner(from: details.state),
            formattedDate: formattedDate,
            answerButtons: answerButtonsState(from: details.state),
            initialStatus: initialStatus,
            calendar: details.calendar,
            recurrence: details.recurrence,
            location: details.location,
            organizer: details.organizer,
            participants: participants
        )
    }

    // MARK: - Private

    private static func answerButtonsState(from state: RsvpState) -> RSVPEvent.AnswerButtonsState {
        let buttonsState: RSVPEvent.AnswerButtonsState

        if case let .answerableInvite(_, attendance) = state {
            buttonsState = .visible(attendance)
        } else {
            buttonsState = .hidden
        }

        return buttonsState
    }

    private static func banner(from state: RsvpState) -> RSVPEvent.Banner? {
        switch state {
        case let .answerableInvite(progress, _), let .reminder(progress):
            switch progress {
            case .pending:
                return nil
            case .ongoing:
                return .init(style: .now, regularText: L10n.Header.happening, boldText: L10n.Header.now)
            case .ended:
                return .init(style: .ended, regularText: L10n.Header.event, boldText: L10n.Header.ended)
            }
        case .unanswerableInvite(let reason):
            let regular: LocalizedStringResource
            switch reason {
            case .inviteIsOutdated:
                regular = L10n.Header.inviteIsOutdated
            case .inviteHasUnknownRecency:
                regular = L10n.Header.offlineWarning
            }
            return .init(style: .generic, regularText: regular)
        case .cancelledInvite(let isOutdated):
            if isOutdated {
                return .init(style: .cancelled, regularText: L10n.Header.cancelledAndOutdated)
            } else {
                return .init(style: .cancelled, regularText: L10n.Header.event, boldText: L10n.Header.canceled)
            }
        case .cancelledReminder:
            return nil
        }
    }
}
