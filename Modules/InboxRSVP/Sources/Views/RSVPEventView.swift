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
import SwiftUI
import proton_app_uniffi

struct RSVPEventView: View {
    enum Action {
        case answerSelected(RsvpAnswer)
        case calendarIconTapped
        case participantOptionSelected(option: EventMenuParticipantOption, forEmail: String)
    }

    private let event: Event
    private let isAnswering: Bool
    private let action: (Action) -> Void
    @State private var areParticipantsExpanded: Bool

    init(
        event: RsvpEvent,
        isAnswering: Bool,
        action: @escaping (Action) -> Void,
        areParticipantsExpanded: Bool = false,
    ) {
        self.event = EventMapper.map(from: event)
        self.isAnswering = isAnswering
        self.action = action
        self.areParticipantsExpanded = areParticipantsExpanded
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            headerBanner
            VStack(alignment: .leading, spacing: DS.Spacing.large) {
                eventHeader
                    .padding(.horizontal, DS.Spacing.extraLarge)
                if case let .visible(_, userParticipantIndex) = event.answerButtons {
                    answerSection(userParticipantIndex: userParticipantIndex)
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
        EventHeader(
            title: event.title,
            formattedDate: event.formattedDate,
            answerButtons: event.answerButtons,
            calendarButtonAction: { action(.calendarIconTapped) }
        )
    }

    @Namespace private var answerButtonAnimation

    private func answerSection(userParticipantIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.mediumLight) {
            Text(L10n.Answer.attending)
                .font(.footnote)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.Text.norm)
            HStack(spacing: DS.Spacing.small) {
                switch event.participants[userParticipantIndex].status.answer {
                case .none:
                    ForEach(RsvpAnswer.allCases, id: \.self) { answer in
                        AnswerButton(text: answer.humanReadable.short) {
                            action(.answerSelected(answer))
                        }
                        .matchedGeometryEffect(id: answer, in: answerButtonAnimation)
                    }
                case .some(let answer):
                    AnswerMenuButton(state: answer, isAnswering: isAnswering) { selectedAnswer in
                        action(.answerSelected(selectedAnswer))
                    }
                    .matchedGeometryEffect(id: answer, in: answerButtonAnimation)
                }
            }
        }
        .animation(.default, value: event.participants[userParticipantIndex].status)
    }

    @ViewBuilder
    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: .zero) {
            if let calendar = event.calendar {
                EventDetailsRow(
                    icon: DS.Icon.icCircleFilled,
                    iconColor: Color(hex: calendar.color),
                    text: calendar.name
                )
            }
            if let recurrence = event.recurrence {
                EventDetailsRow(icon: DS.Icon.icArrowsRotate, text: recurrence)
            }
            if let location = event.location {
                EventDetailsRow(icon: DS.Icon.icMapPin, text: location)
            }
            EventDetailsRowMenu<EventMenuParticipantOption>(
                icon: DS.Icon.icUser,
                text: event.organizer.displayName,
                action: { option in
                    action(.participantOptionSelected(option: option, forEmail: event.organizer.email))
                }
            )
            EventParticipantsView(
                participants: event.participants,
                action: { option, email in action(.participantOptionSelected(option: option, forEmail: email)) },
                areParticipantsExpanded: $areParticipantsExpanded
            )
        }
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
            .init(name: "User 5", email: "user5@example.com", status: .no),
            .init(name: "User 6", email: "user6@example.com", status: .no),
            .init(name: "User 7", email: "user7@example.com", status: .no),
            .init(name: "User 8", email: "user8@example.com", status: .no),
            .init(name: "User 9", email: "user9@example.com", status: .no),
            .init(name: "User 10", email: "user10@example.com", status: .no),
            .init(name: "User 11", email: "user11@example.com", status: .no),
            .init(name: "User 12", email: "user12@example.com", status: .no),
            .init(name: "User 13", email: "user13@example.com", status: .no),
            .init(name: "User 14", email: "user14@example.com", status: .no),
            .init(name: "User 15", email: "user15@example.com", status: .no),
        ],
        userAttendeeIdx: 0,
        calendar: RsvpCalendar(id: "<calendar_id>", name: "Personal", color: "#F5A623"),
        state: .answerableInvite(progress: .ended, attendance: .optional)
    )

    ScrollView(.vertical, showsIndicators: false) {
        RSVPEventView(
            event: event,
            isAnswering: true,
            action: { _ in },
            areParticipantsExpanded: false
        )
    }
}
