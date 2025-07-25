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
    let progress: RsvpProgress
    @State var isParticipantsExpanded: Bool = false
    @State var answerStatus: RsvpAttendeeStatus = .unanswered

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
        VStack(alignment: .leading, spacing: 0) {
            headerBanner
            VStack(alignment: .leading, spacing: DS.Spacing.large) {
                eventHeader
                answerSection
                eventDetails
            }
            .padding(.all, DS.Spacing.extraLarge)
        }
    }

    @ViewBuilder
    private var headerBanner: some View {
        switch progress {
        case .pending:
            EmptyView()
        case .ongoing:
            RSVPHeaderView(regular: "Happening", bold: " now")
        case .ended:
            RSVPHeaderView(regular: "Event", bold: " ended")
        case .cancelled:
            RSVPHeaderView(regular: "Event", bold: " canceled")
        }
    }

    @ViewBuilder
    private var eventHeader: some View {
        HStack(alignment: .top, spacing: DS.Spacing.medium) {
            VStack(alignment: .leading, spacing: DS.Spacing.standard) {
                Text("Whispers of Tomorrow: An Evening of Unexpected Wonders")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Color.Text.norm)
                Text("Thu, 15 Jul • 14:30 - 15:30 ")
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundStyle(DS.Color.Text.norm)
                Text("(Attendance optional)")
                    .font(.footnote)
                    .fontWeight(.regular)
                    .foregroundStyle(DS.Color.Text.weak)
            }
            Spacer()
            Image(DS.Images.protonCalendar)
                .square(size: 52)
        }
        .background(Color.green.opacity(0.3))
    }

    private var answerSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.mediumLight) {
            Text("Attending?")
                .font(.footnote)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.Text.weak)
            HStack(spacing: DS.Spacing.small) {
                switch answerStatus.answer {
                case .some(let answerState):
                    RSVPAnswerButtonBig(state: answerState) { newState in
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
        .padding(.bottom, DS.Spacing.small)
        .background(Color.yellow.opacity(0.3))
    }

    @ViewBuilder
    private var eventDetails: some View {
        VStack(alignment: .leading, spacing: .zero) {
            RSVPDetailsRow(icon: Image(symbol: .circle), iconColor: .pink, text: "Work")
            RSVPDetailsRow(icon: Image(symbol: .occurence), text: "Weekly on Monday")
            RSVPDetailsRow(icon: Image(DS.Icon.icMapPin), text: "Zoom meeting")
            RSVPDetailsRow(icon: Image(symbol: .person), text: "Samantha Peterson (Organizer)")
            ParticipantsRow(isParticipantsExpanded: $isParticipantsExpanded) {
                isParticipantsExpanded.toggle()
            }
            if isParticipantsExpanded {
                VStack(alignment: .leading, spacing: .zero) {
                    RSVPDetailsRow(
                        icon: Image(symbol: .checkmark),
                        iconColor: DS.Color.Notification.success,
                        text: "You • email@protonmail.ch"
                    )
                    RSVPDetailsRow(
                        icon: Image(symbol: .questionmark),
                        iconColor: DS.Color.Notification.success,
                        text: "Anthony Rivera • email@protonmail.ch"
                    )
                    RSVPDetailsRow(
                        icon: Image(symbol: .xmark),
                        iconColor: DS.Color.Notification.error,
                        text: "nic.butker@protonmail.com"
                    )
                }
                .compositingGroup()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.3))
    }
}

struct ParticipantsRow: View {
    @Binding var isParticipantsExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RSVPDetailsRow(
                icon: Image(symbol: .participants),
                text: "3 Participants",
                trailingIcon: isParticipantsExpanded ? DS.Icon.icChevronUpFilled : DS.Icon.icChevronDownFilled
            )
        }
    }
}

struct RSVPDetailsRow: View {
    let icon: Image
    let iconColor: Color
    let text: String
    let trailingIcon: ImageResource?

    init(
        icon: Image,
        iconColor: Color = DS.Color.Text.weak,
        text: String,
        trailingIcon: ImageResource? = .none
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.text = text
        self.trailingIcon = trailingIcon
    }

    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.medium) {
            icon
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 20)
            HStack(alignment: .center, spacing: DS.Spacing.small) {
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundStyle(DS.Color.Text.weak)
                    .background(Color.pink)
                if let trailingIcon {
                    Image(trailingIcon)
                        .square(size: 16)
                }
                Spacer()
            }
        }
        .background(Color.cyan)
        .padding(.vertical, DS.Spacing.standard)
    }
}

struct RSVPHeaderView: View {
    let regular: String
    let bold: String

    var body: some View {
        (Text(regular) + Text(bold).fontWeight(.bold))
            .font(.subheadline)
            .padding([.top, .horizontal], DS.Spacing.extraLarge)
            .padding(.bottom, DS.Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.Background.secondary)
    }
}

struct RSVPAnswerButtonBig: View {
    let state: Answer
    let action: (Answer) -> Void

    var body: some View {
        Menu(
            content: {
                ForEach(Answer.allCases, id: \.self) { answer in
                    Button(action: { action(answer) }) {
                        Text(answer.humanReadableLong)
                            .font(.body)
                            .fontWeight(.regular)
                            .foregroundStyle(DS.Color.Text.norm)
                    }
                }
            },
            label: {
                RSVPAnswerButton(text: state.humanReadableLong) {}
            }
        )
    }
}

struct RSVPAnswerButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.Brand.plus30)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(RSVPAnswerButtonStyle())
    }
}

struct RSVPAnswerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.all, 12)
            .background(configuration.isPressed ? DS.Color.InteractionBrandWeak.pressed : DS.Color.InteractionBrandWeak.norm)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.massive))
    }
}

#Preview {
    ScrollView(.vertical, showsIndicators: false) {
        VStack(spacing: 16) {
            RSVPView(progress: .pending(.fresh))
            RSVPView(progress: .ongoing(.fresh))
            RSVPView(progress: .ended(.fresh))
            RSVPView(progress: .cancelled(.fresh))
        }
    }
}

// FIXME: Temporary Rust interface to remove

enum Answer: CaseIterable, Equatable {
    case yes
    case maybe
    case no

    var humanReadable: String {
        switch self {
        case .yes:
            "Yes"
        case .maybe:
            "Maybe"
        case .no:
            "No"
        }
    }

    var humanReadableLong: String {
        switch self {
        case .yes:
            "Yes, I'll attend"
        case .maybe:
            "Maybe, I'll attend"
        case .no:
            "No, I won't attend"
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

extension RsvpAttendeeStatus {
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
}

public enum RsvpProgress {
    case pending(RsvpRecency)
    case ongoing(RsvpRecency)
    case ended(RsvpRecency)
    case cancelled(RsvpRecency)
}

public enum RsvpRecency {
    case fresh
    case outdated
    case unknown
}

public struct RsvpEventDetails {
    public var summary: String?
    public var location: String?
    public var description: String?
    public var recurrence: String?
    public var startsAt: UnixTimestamp
    public var endsAt: UnixTimestamp
    public var occurrence: RsvpOccurrence
    public var organizer: RsvpOrganizer
    public var attendees: [RsvpAttendee]
    public var userAttendeeIdx: UInt32
    public var progress: RsvpProgress
    public var calendar: RsvpCalendar?
    public var intent: RsvpIntent
    public var canBeAnswered: Bool

    public init(
        summary: String?,
        location: String?,
        description: String?,
        recurrence: String?,
        startsAt: UnixTimestamp,
        endsAt: UnixTimestamp,
        occurrence: RsvpOccurrence,
        organizer: RsvpOrganizer,
        attendees: [RsvpAttendee],
        userAttendeeIdx: UInt32,
        progress: RsvpProgress,
        calendar: RsvpCalendar?,
        intent: RsvpIntent,
        canBeAnswered: Bool
    ) {
        self.summary = summary
        self.location = location
        self.description = description
        self.recurrence = recurrence
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.occurrence = occurrence
        self.organizer = organizer
        self.attendees = attendees
        self.userAttendeeIdx = userAttendeeIdx
        self.progress = progress
        self.calendar = calendar
        self.intent = intent
        self.canBeAnswered = canBeAnswered
    }
}

public enum RsvpOccurrence {
    case date
    case dateTime
}

public struct RsvpOrganizer {
    public var email: String

    public init(email: String) {
        self.email = email
    }
}

public struct RsvpAttendee {
    public var email: String
    public var status: RsvpAttendeeStatus?

    public init(email: String, status: RsvpAttendeeStatus?) {
        self.email = email
        self.status = status
    }
}

public enum RsvpAttendeeStatus {
    case unanswered
    case maybe
    case no
    case yes
}

public struct RsvpCalendar {
    public var name: String
    public var color: String

    public init(name: String, color: String) {
        self.name = name
        self.color = color
    }
}

public enum RsvpIntent {
    case invite
    case reminder
}
