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

import InboxCoreUI
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

struct RSVPView: View {
    let event: RsvpEventDetails
    @State var areParticipantsExpanded: Bool
    @State var answerStatus: RsvpAttendeeStatus

    init(event: RsvpEventDetails, areParticipantsExpanded: Bool) {
        self.event = event
        self.areParticipantsExpanded = areParticipantsExpanded
        self.answerStatus = event.attendees[safe: Int(event.userAttendeeIdx)]?.status ?? .unanswered
    }

    var body: some View {
        content()
            .background(DS.Color.Background.norm)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.extraLarge))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.extraLarge)
                    .stroke(DS.Color.Border.norm, lineWidth: 1)
            )
            .frame(maxWidth: .infinity)
            .padding(.horizontal, DS.Spacing.large)
    }

    // MARK: - Private

    @ViewBuilder
    private func content() -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            headerBanner
            VStack(alignment: .leading, spacing: DS.Spacing.large) {
                eventHeader
                    .padding(.horizontal, DS.Spacing.extraLarge)
                if case .answerableInvite = event.state {
                    answerSection
                        .padding(.bottom, DS.Spacing.small)
                        .padding(.horizontal, DS.Spacing.extraLarge)
                }
                eventDetails
                    .padding(.horizontal, DS.Spacing.large)
            }
            .padding(.top, DS.Spacing.extraLarge)
            .padding(.bottom, DS.Spacing.large)
        }
    }

    @ViewBuilder
    private var headerBanner: some View {
        switch event.state {
        case .answerableInvite(let progress, _), .reminder(let progress):
            switch progress {
            case .pending:
                EmptyView()
            case .ongoing:
                RSVPHeaderView(
                    style: .now,
                    regular: L10n.Header.happening,
                    bold: L10n.Header.now
                )
            case .ended:
                RSVPHeaderView(
                    style: .ended,
                    regular: L10n.Header.event,
                    bold: L10n.Header.ended
                )
            }
        case .unanswerableInvite(let reason):
            switch reason {
            case .inviteIsOutdated:
                RSVPHeaderView(
                    style: .generic,
                    regular: L10n.Header.inviteIsOutdated,
                    bold: String.empty.stringResource
                )
            case .inviteHasUnknownRecency:
                RSVPHeaderView(
                    style: .generic,
                    regular: L10n.Header.offlineWarning,
                    bold: String.empty.stringResource
                )
            }
        case .cancelledInvite(let isOutdated):
            if isOutdated {
                RSVPHeaderView(
                    style: .cancelled,
                    regular: L10n.Header.cancelledAndOutdated,
                    bold: String.empty.stringResource
                )
            } else {
                RSVPHeaderView(
                    style: .cancelled,
                    regular: L10n.Header.event,
                    bold: L10n.Header.canceled
                )
            }
        case .cancelledReminder:
            EmptyView()
        }
    }

    @ViewBuilder
    private var eventHeader: some View {
        HStack(alignment: .top, spacing: DS.Spacing.standard) {
            VStack(alignment: .leading, spacing: DS.Spacing.standard) {
                Text(event.summary ?? L10n.noEventTitlePlacholder.string)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Color.Text.norm)
                Text(RSVPDateFormatter.string(from: event.startsAt, to: event.endsAt, occurrence: event.occurrence))
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundStyle(DS.Color.Text.norm)
                    .minimumScaleFactor(0.75)
                if case let .answerableInvite(_, attendance) = event.state, attendance == .optional {
                    Text(L10n.attendanceOptional)
                        .font(.footnote)
                        .fontWeight(.regular)
                        .foregroundStyle(DS.Color.Text.weak)
                }
            }
            Spacer(minLength: 0)
            Image(DS.Images.protonCalendar)
                .square(size: 52)
        }
    }

    private var answerSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.mediumLight) {
            Text(L10n.Answer.attending)
                .font(.footnote)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.Text.weak)
            HStack(spacing: DS.Spacing.small) {
                switch answerStatus.answer {
                case .some(let answerState):
                    RSVPAnswerMenuButton(state: answerState) { newState in
                        answerStatus = newState.attendeeStatus
                    }
                case .none:
                    RSVPAnswerButton(text: Answer.yes.humanReadable) {
                        answerStatus = .yes
                    }
                    RSVPAnswerButton(text: Answer.maybe.humanReadable) {
                        answerStatus = .maybe
                    }
                    RSVPAnswerButton(text: Answer.no.humanReadable) {
                        answerStatus = .no
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var eventDetails: some View {
        VStack(alignment: .leading, spacing: .zero) {
            if let calendar = event.calendar {
                RSVPDetailsRow(
                    icon: DS.Icon.icCircleFilled,
                    iconColor: Color(hex: calendar.color),
                    text: calendar.name
                )
            }
            if let recurrence = event.recurrence {
                RSVPDetailsRow(icon: DS.Icon.icArrowsRotate, text: recurrence)
            }
            if let location = event.location {
                RSVPDetailsRow(icon: DS.Icon.icMapPin, text: location)
            }
            RSVPDetailsRowMenu<RSVPOrganizerOption>(
                icon: DS.Icon.icUser,
                text: event.organizer.email,
                action: { _ in }
            )
            if event.attendees.count >= 2 {
                RSVPDetailsParticipantsButton(count: event.attendees.count, isExpanded: $areParticipantsExpanded) {
                    areParticipantsExpanded.toggle()
                }
                if areParticipantsExpanded {
                    LazyVStack(alignment: .leading, spacing: .zero) {
                        ForEachEnumerated(event.attendees, id: \.element.email) { attendee, index in
                            RSVPDetailsRow(
                                icon: attendee.status.details.icon,
                                iconColor: attendee.status.details.color,
                                text: event.userAttendeeIdx == index ? L10n.Details.you(email: attendee.email).string : attendee.email
                            )
                        }
                    }
                    .compositingGroup()
                }
            } else if let attendee = event.attendees.first {
                RSVPDetailsRow(
                    icon: attendee.status.details.icon,
                    iconColor: attendee.status.details.color,
                    text: event.userAttendeeIdx == 0 ? L10n.Details.you(email: attendee.email).string : attendee.email
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ScrollView(.vertical, showsIndicators: false) {
        VStack(spacing: 16) {
            RSVPView(
                event: .init(
                    summary: "Quick Sync",
                    location: "Huddle Room",
                    description: "A brief check-in.",
                    recurrence: nil,
                    startsAt: UInt64(0),
                    endsAt: UInt64(0),
                    occurrence: .dateTime,
                    organizer: RsvpOrganizer(email: "organizer1@example.com"),
                    attendees: [
                        .init(email: "user1@example.com", status: .unanswered),
                        .init(email: "user2@example.com", status: .yes),
                        .init(email: "user3@example.com", status: .maybe),
                        .init(email: "user4@example.com", status: .no),
                    ],
                    userAttendeeIdx: 0,
                    calendar: RsvpCalendar(name: "Personal", color: "#F5A623"),
                    state: .answerableInvite(progress: .ended, attendance: .optional)
                ),
                areParticipantsExpanded: false
            )
        }
    }
}

private extension Collection {

    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

}

extension Answer {
    var humanReadable: String {
        switch self {
        case .yes:
            L10n.Answer.yes.string
        case .maybe:
            L10n.Answer.maybe.string
        case .no:
            L10n.Answer.no.string
        }
    }

    var humanReadableLong: LocalizedStringResource {
        switch self {
        case .yes:
            L10n.Answer.yesLong
        case .maybe:
            L10n.Answer.maybeLong
        case .no:
            L10n.Answer.noLong
        }
    }

    var attendeeStatus: RsvpAttendeeStatus {
        switch self {
        case .yes:
            .yes
        case .maybe:
            .maybe
        case .no:
            .no
        }
    }
}

private extension RsvpAttendeeStatus {
    var answer: Answer? {
        switch self {
        case .unanswered:
            nil
        case .maybe:
            .maybe
        case .no:
            .no
        case .yes:
            .yes
        }
    }

    var details: (icon: ImageResource, color: Color) {
        switch self {
        case .unanswered:
            (DS.Icon.icCircleRadioEmpty, DS.Color.Shade.shade40)
        case .maybe:
            (DS.Icon.icQuestionCircle, DS.Color.Notification.error)
        case .no:
            (DS.Icon.icCrossCircle, DS.Color.Notification.error)
        case .yes:
            (DS.Icon.icCheckmarkCircle, DS.Color.Notification.success)
        }
    }
}
