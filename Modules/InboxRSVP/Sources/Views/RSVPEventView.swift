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

struct RSVPEventView: View {
    private let event: Event
    private let isAnswering: Bool
    private let onAnswerSelected: (RsvpAnswer) -> Void
    @State private var areParticipantsExpanded: Bool

    init(
        event: RsvpEvent,
        isAnswering: Bool,
        onAnswerSelected: @escaping (RsvpAnswer) -> Void,
        areParticipantsExpanded: Bool = false,
    ) {
        self.event = EventMapper.map(from: event)
        self.isAnswering = isAnswering
        self.onAnswerSelected = onAnswerSelected
        self.areParticipantsExpanded = areParticipantsExpanded
    }

    var body: some View {
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
                eventDetailsSection
                    .padding(.horizontal, DS.Spacing.large)
            }
            .padding(.top, DS.Spacing.extraLarge)
            .padding(.bottom, DS.Spacing.large)
        }
        .cardStyle()
    }

    // MARK: - Private

    @ViewBuilder
    private var headerBanner: some View {
        if let banner = event.banner {
            EventBannerView(style: banner.style, regular: banner.regularText, bold: banner.boldText)
        }
    }

    @ViewBuilder
    private var eventHeader: some View {
        EventHeader(title: event.title, formattedDate: event.formattedDate, answerButtons: event.answerButtons)
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
                    ForEach(RsvpAnswer.allCases, id: \.self) { answer in
                        AnswerButton(text: answer.humanReadable.short) {
                            onAnswerSelected(answer)
                        }
                    }
                case .some(let answer):
                    AnswerMenuButton(state: answer, isAnswering: isAnswering) { selectedAnswer in
                        onAnswerSelected(selectedAnswer)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: .zero) {
            if let calendar = event.calendar {
                EventDetailsRow(icon: DS.Icon.icCircleFilled, iconColor: Color(hex: calendar.color), text: calendar.name)
            }
            if let recurrence = event.recurrence {
                EventDetailsRow(icon: DS.Icon.icArrowsRotate, text: recurrence)
            }
            if let location = event.location {
                EventDetailsRow(icon: DS.Icon.icMapPin, text: location)
            }
            EventDetailsRowMenu<MenuOrganizerOption>(icon: DS.Icon.icUser, text: event.organizer.displayName) { _ in }
            if event.participants.count >= 2 {
                EventParticipantsRowButton(count: event.participants.count, isExpanded: $areParticipantsExpanded) {
                    areParticipantsExpanded.toggle()
                }
            }
            if areParticipantsExpanded || event.participants.count == 1 {
                LazyVStack(alignment: .leading, spacing: .zero) {
                    ForEach(event.participants, id: \.displayName) { participant in
                        EventDetailsRow(
                            icon: participant.status.details.icon,
                            iconColor: participant.status.details.color,
                            text: participant.displayName
                        )
                    }
                }
                .compositingGroup()
            }
        }
    }
}

#Preview {
    let event = RsvpEvent(
        id: .none,
        summary: "Quick Sync",
        location: "Huddle Room",
        description: "A brief check-in.",
        recurrence: nil,
        startsAt: 1754042400,  // Aug 1, 2025 10:00 AM UTC
        endsAt: 1754044200,  // Aug 1, 2025 10:30 AM UTC
        occurrence: .dateTime,
        organizer: RsvpOrganizer(name: .none, email: "organizer1@example.com"),
        attendees: [
            .init(name: .none, email: "user1@example.com", status: .unanswered),
            .init(name: "User 2", email: "user2@example.com", status: .yes),
            .init(name: "User 3", email: "user3@example.com", status: .maybe),
            .init(name: "User 4", email: "user4@example.com", status: .no),
        ],
        userAttendeeIdx: 0,
        calendar: RsvpCalendar(id: "<calendar_id>", name: "Personal", color: "#F5A623"),
        state: .answerableInvite(progress: .ended, attendance: .optional)
    )

    ScrollView(.vertical, showsIndicators: false) {
        VStack(spacing: 16) {
            RSVPEventView(
                event: event,
                isAnswering: true,
                onAnswerSelected: { _ in },
                areParticipantsExpanded: false
            )
        }
        .padding()
    }
}

private extension RsvpAttendeeStatus {
    var answer: RsvpAnswer? {
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
            (DS.Icon.icQuestionCircle, DS.Color.Notification.warning)
        case .no:
            (DS.Icon.icCrossCircle, DS.Color.Notification.error)
        case .yes:
            (DS.Icon.icCheckmarkCircle, DS.Color.Notification.success)
        }
    }
}
