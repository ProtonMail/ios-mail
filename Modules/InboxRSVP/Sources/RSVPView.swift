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
    @State var event: RSVPEvent
    @State var areParticipantsExpanded: Bool

    init(event details: RsvpEventDetails, areParticipantsExpanded: Bool) {
        self.event = RSVPEventMapper.map(from: details)
        self.areParticipantsExpanded = areParticipantsExpanded
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
                if case .visible = event.answerButtons {
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
        if let banner = event.banner {
            RSVPHeaderView(style: banner.style, regular: banner.regularText, bold: banner.boldText)
        }
    }

    @ViewBuilder
    private var eventHeader: some View {
        HStack(alignment: .top, spacing: DS.Spacing.standard) {
            VStack(alignment: .leading, spacing: DS.Spacing.standard) {
                Text(event.title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Color.Text.norm)
                Text(event.formattedDate)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundStyle(DS.Color.Text.norm)
                    .minimumScaleFactor(0.75)
                if case let .visible(attendance) = event.answerButtons, attendance == .optional {
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
                switch event.participants[event.userParticipantIndex].status.answer {
                case .none:
                    ForEach(Answer.allCases, id: \.self) { answer in
                        RSVPAnswerButton(text: answer.humanReadable.short) {
                            updateStatus(with: answer.attendeeStatus)
                        }
                    }
                case .some(let answer):
                    RSVPAnswerMenuButton(state: answer) { selectedAnswer in
                        updateStatus(with: selectedAnswer.attendeeStatus)
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
            RSVPDetailsRowMenu<RSVPOrganizerOption>(icon: DS.Icon.icUser, text: event.organizer.email) { _ in }
            if event.participants.count >= 2 {
                RSVPDetailsParticipantsButton(count: event.participants.count, isExpanded: $areParticipantsExpanded) {
                    areParticipantsExpanded.toggle()
                }
                if areParticipantsExpanded {
                    LazyVStack(alignment: .leading, spacing: .zero) {
                        ForEachEnumerated(event.participants, id: \.element.displayName) { participant, index in
                            participantRow(participant)
                        }
                    }
                    .compositingGroup()
                }
            } else if let participant = event.participants.first {
                participantRow(participant)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func participantRow(_ participant: RSVPEvent.Participant) -> some View {
        RSVPDetailsRow(
            icon: participant.status.details.icon,
            iconColor: participant.status.details.color,
            text: participant.displayName
        )
    }

    private func updateStatus(with status: RsvpAttendeeStatus) {
        let updateIndex = event.userParticipantIndex
        var updatedParticipants = event.participants

        updatedParticipants[updateIndex] =
            event
            .participants[updateIndex]
            .copy(\.status, to: status)

        event = event.copy(\.participants, to: updatedParticipants)
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

extension Answer {
    var humanReadable: (short: LocalizedStringResource, long: LocalizedStringResource) {
        switch self {
        case .yes:
            (L10n.Answer.yes, L10n.Answer.yesLong)
        case .maybe:
            (L10n.Answer.maybe, L10n.Answer.maybeLong)
        case .no:
            (L10n.Answer.no, L10n.Answer.noLong)
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
