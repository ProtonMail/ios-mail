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
                RSVPHeaderView(style: .now, regular: "Happening", bold: " now")
            case .ended:
                RSVPHeaderView(style: .ended, regular: "Event", bold: " ended")
            }
        case .unanswerableInvite(let reason):
            switch reason {
            case .inviteIsOutdated:
                RSVPHeaderView(
                    style: .generic,
                    regular: "This invitation is out of date. The event has been updated.",
                    bold: .empty
                )
            case .inviteHasUnknownRecency:
                RSVPHeaderView(
                    style: .generic,
                    regular: "You're offline. The displayed information may be out-of-date.",
                    bold: .empty
                )
            }
        case .cancelledInvite(let isOutdated):
            if isOutdated {
                RSVPHeaderView(
                    style: .cancelled,
                    regular: "Event cancelled. This invitation is out of date.",
                    bold: .empty
                )
            } else {
                RSVPHeaderView(style: .cancelled, regular: "Event", bold: " canceled")
            }
        case .cancelledReminder:
            EmptyView()
        }
    }

    @ViewBuilder
    private var eventHeader: some View {
        HStack(alignment: .top, spacing: DS.Spacing.medium) {
            VStack(alignment: .leading, spacing: DS.Spacing.standard) {
                Text(event.summary ?? "(no title)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Color.Text.norm)
                Text("FIXME: In next MR")
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundStyle(DS.Color.Text.norm)
                if case let .answerableInvite(_, attendance) = event.state, attendance == .optional {
                    Text("(Attendance optional)")
                        .font(.footnote)
                        .fontWeight(.regular)
                        .foregroundStyle(DS.Color.Text.weak)
                }
            }
            Spacer()
            Image(DS.Images.protonCalendar)
                .square(size: 52)
        }
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
                    VStack(alignment: .leading, spacing: .zero) {
                        ForEachEnumerated(event.attendees, id: \.element.email) { attendee, index in
                            RSVPDetailsRow(
                                icon: attendee.status.details.icon,
                                iconColor: attendee.status.details.color,
                                text: event.userAttendeeIdx == index ? "You • \(attendee.email)" : attendee.email
                            )
                        }
                    }
                    .compositingGroup()
                }
            } else if let attendee = event.attendees.first {
                RSVPDetailsRow(
                    icon: attendee.status.details.icon,
                    iconColor: attendee.status.details.color,
                    text: event.userAttendeeIdx == 0 ? "You • \(attendee.email)" : attendee.email
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

import InboxCore

enum RSVPOrganizerOption: RSVPMenuOption {
    case copyAddress
    case newMessage

    var displayName: String {
        switch self {
        case .copyAddress:
            "Copy address"
        case .newMessage:
            "Message"
        }
    }

    var trailingIcon: ImageResource {
        switch self {
        case .copyAddress:
            DS.Icon.icSquares
        case .newMessage:
            DS.Icon.icPenSquare
        }
    }
}

protocol RSVPMenuOption: CaseIterable, Hashable {
    var displayName: String { get }
    var trailingIcon: ImageResource { get }
}

struct RSVPDetailsRowMenu<Option: RSVPMenuOption>: View {
    let icon: ImageResource
    let text: String
    let action: (Option) -> Void

    var body: some View {
        Menu {
            ForEach(Array(Option.allCases), id: \.self) { option in
                RSVPMenuOptionButton(
                    text: option.displayName,
                    action: { action(option) },
                    trailingIcon: option.trailingIcon
                )
            }
        } label: {
            RSVPDetailsRow(icon: icon, text: text, trailingIcon: .none)
        }
        .buttonStyle(RSVPDetailsRowButtonStyle())
    }
}

struct RSVPDetailsParticipantsButton: View {
    let count: Int
    @Binding var isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RSVPDetailsRow(
                icon: DS.Icon.icUsers,
                text: "\(count) Participants",
                trailingIcon: isExpanded ? DS.Icon.icChevronUpFilled : DS.Icon.icChevronDownFilled
            )
        }
        .buttonStyle(RSVPDetailsRowButtonStyle())
    }
}

struct RSVPDetailsRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? DS.Color.InteractionWeak.pressed : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))
    }
}

struct RSVPDetailsRow: View {
    let icon: ImageResource
    let iconColor: Color
    let text: String
    let trailingIcon: ImageResource?

    init(
        icon: ImageResource,
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
            Image(icon)
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 20)
            HStack(alignment: .center, spacing: DS.Spacing.small) {
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundStyle(DS.Color.Text.weak)
                if let trailingIcon {
                    Image(trailingIcon)
                        .foregroundStyle(iconColor)
                        .square(size: 16)
                }
                Spacer()
            }
        }
        .padding(.all, DS.Spacing.standard)
    }
}

struct RSVPHeaderView: View {
    enum Style {
        case now
        case ended
        case cancelled
        case generic

        var color: (text: Color, background: Color) {
            switch self {
            case .now:
                (DS.Color.Notification.success900, DS.Color.Notification.success100)
            case .ended:
                (DS.Color.Notification.warning900, DS.Color.Notification.warning100)
            case .cancelled:
                (DS.Color.Notification.error900, DS.Color.Notification.error100)
            case .generic:
                (DS.Color.Text.norm, DS.Color.Background.deep)
            }
        }
    }

    let style: Style
    let regular: String
    let bold: String

    var body: some View {
        (Text(regular) + Text(bold).fontWeight(.bold))
            .font(.subheadline)
            .foregroundStyle(style.color.text)
            .padding(.vertical, DS.Spacing.moderatelyLarge)
            .padding(.horizontal, DS.Spacing.extraLarge)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(style.color.background)
    }
}

struct RSVPAnswerMenuButton: View {
    let state: Answer
    let action: (Answer) -> Void

    var body: some View {
        Menu(state.humanReadableLong) {
            ForEach(Answer.allCases.removing { $0 == state }, id: \.self) { answer in
                RSVPMenuOptionButton(
                    text: answer.humanReadableLong,
                    action: { action(answer) },
                    trailingIcon: .none
                )
            }
        }
        .buttonStyle(RSVPAnswerButtonStyle())
    }
}

struct RSVPMenuOptionButton: View {
    let text: String
    let action: () -> Void
    let trailingIcon: ImageResource?

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.tiny) {
                Text(text)
                    .font(.callout)
                    .fontWeight(.regular)
                    .foregroundStyle(DS.Color.Text.norm)
                if let trailingIcon {
                    Image(trailingIcon)
                        .foregroundStyle(DS.Color.Icon.norm)
                        .square(size: 20)
                }
            }
            .padding(.vertical, DS.Spacing.medium)
            .padding(.horizontal, DS.Spacing.large)
        }
    }
}

struct RSVPAnswerButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(text, action: action)
            .buttonStyle(RSVPAnswerButtonStyle())
    }
}

struct RSVPAnswerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.regular)
            .foregroundStyle(DS.Color.Brand.plus30)
            .padding(.all, 12)
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? DS.Color.InteractionBrandWeak.pressed : DS.Color.InteractionBrandWeak.norm)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.massive))
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
                        .init(email: "user1@example.com", status: .yes),
                        .init(email: "user2@example.com", status: .no),
                        .init(email: "user3@example.com", status: .maybe),
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

private extension Array {

    func removing(_ shouldBeExcluded: (Self.Element) throws -> Bool) rethrows -> [Self.Element] {
        try filter { item in try !shouldBeExcluded(item) }
    }

}

private extension Collection {

    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
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

public typealias UnixTimestamp = UInt64

public enum RsvpEventProgress {
    case pending
    case ongoing
    case ended
}

public enum RsvpUnanswerableReason {
    case inviteIsOutdated
    case inviteHasUnknownRecency
}

public enum RsvpState {
    case answerableInvite(progress: RsvpEventProgress, attendance: Attendance)
    case unanswerableInvite(RsvpUnanswerableReason)
    case cancelledInvite(isOutdated: Bool)
    case reminder(RsvpEventProgress)
    case cancelledReminder
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
    public var calendar: RsvpCalendar?
    public var state: RsvpState

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
        calendar: RsvpCalendar?,
        state: RsvpState
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
        self.calendar = calendar
        self.state = state
    }
}

public enum RsvpRecency {
    case fresh
    case outdated
    case unknown
}

public enum Attendance {
    case optional
    case required
}

public enum RsvpOccurrence {
    case date
    case dateTime
}

public enum RsvpAttendeeStatus {
    case unanswered
    case maybe
    case no
    case yes
}

public struct RsvpOrganizer {
    public var email: String
}

public struct RsvpAttendee {
    public var email: String
    public var status: RsvpAttendeeStatus
}

public struct RsvpCalendar {
    public var name: String
    public var color: String
}
