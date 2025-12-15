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

import Foundation
import InboxCore
import InboxTesting
import Testing
import proton_app_uniffi

@testable import InboxRSVP

final class EventMapperTests {
    @Test(
        arguments: [
            (summary: String?("Amazing Apple event!"), expected: "Amazing Apple event!"),
            (summary: String?(nil), expected: L10n.noEventTitlePlacholder.string),
        ]
    )
    func testTitleMapping(summary: String?, expectedTitle: String) {
        let details = RsvpEvent.testData(summary: summary)
        let given = EventMapper.map(from: details)

        #expect(given.title == expectedTitle)
    }

    @Test(
        arguments: zip(
            [RsvpEvent]([
                RsvpEvent.testData(
                    userAttendeeIdx: 1,
                    state: .answerableInvite(progress: .pending, attendance: .optional)
                ),
                .testData(
                    userAttendeeIdx: 2,
                    state: .answerableInvite(progress: .pending, attendance: .required)
                ),
                .testData(
                    userAttendeeIdx: .none,
                    state: .answerableInvite(progress: .pending, attendance: .required)
                ),
                .testData(state: .reminder(progress: .ongoing)),
                .testData(state: .cancelledInvite(isOutdated: true)),
            ]),
            [
                Event.AnswerButtonsState.visible(attendance: .optional, attendeeIndex: 1),
                Event.AnswerButtonsState.visible(attendance: .required, attendeeIndex: 2),
                Event.AnswerButtonsState.hidden,
                Event.AnswerButtonsState.hidden,
                Event.AnswerButtonsState.hidden,
            ]
        )
    )
    func testAnswerButtonsMapping(given event: RsvpEvent, expected: Event.AnswerButtonsState) {
        let given = EventMapper.map(from: event)

        #expect(given.answerButtons == expected)
    }

    @Test(
        arguments: zip(
            [
                RsvpState.answerableInvite(progress: .pending, attendance: .required),
                RsvpState.answerableInvite(progress: .ongoing, attendance: .required),
                RsvpState.answerableInvite(progress: .ended, attendance: .required),
                RsvpState.reminder(progress: .pending),
                RsvpState.reminder(progress: .ongoing),
                RsvpState.reminder(progress: .ended),
                RsvpState.unanswerableInvite(reason: .inviteIsOutdated),
                RsvpState.unanswerableInvite(reason: .networkFailure),
                RsvpState.unanswerableInvite(reason: .eventDoesNotExist),
                RsvpState.unanswerableInvite(reason: .addressIsIncorrect),
                RsvpState.unanswerableInvite(reason: .userIsOrganizer),
                RsvpState.cancelledInvite(isOutdated: true),
                RsvpState.cancelledInvite(isOutdated: false),
                RsvpState.cancelledReminder,
            ],
            [
                Event.Banner?(nil),
                Event.Banner(style: .now, regularText: L10n.Header.happening, boldText: L10n.Header.now),
                .init(style: .ended, regularText: L10n.Header.event, boldText: L10n.Header.ended),
                nil,
                .init(style: .now, regularText: L10n.Header.happening, boldText: L10n.Header.now),
                .init(style: .ended, regularText: L10n.Header.event, boldText: L10n.Header.ended),
                .init(style: .generic, regularText: L10n.Header.inviteIsOutdated, boldText: .empty),
                .init(style: .generic, regularText: L10n.Header.offlineWarning, boldText: .empty),
                .init(style: .generic, regularText: L10n.Header.eventDoesNotExist, boldText: .empty),
                .init(style: .generic, regularText: L10n.Header.addressIsIncorrect, boldText: .empty),
                .init(style: .generic, regularText: L10n.Header.userIsOrganizer, boldText: .empty),
                .init(style: .cancelled, regularText: L10n.Header.cancelledAndOutdated, boldText: .empty),
                .init(style: .cancelled, regularText: L10n.Header.event, boldText: L10n.Header.cancelled),
                nil,
            ]
        )
    )
    func testBannerMapping(given state: RsvpState, expectedBanner: Event.Banner?) {
        let details = RsvpEvent.testData(state: state)
        let given = EventMapper.map(from: details)

        #expect(given.banner == expectedBanner)
    }

    @Test(
        arguments: zip(
            [
                RsvpOrganizer(name: "Samantha Peterson", email: "samantha.peterson@pm.me"),
                RsvpOrganizer(name: .none, email: "john.wick@proton.me"),
            ],
            [
                Event.Organizer(email: "samantha.peterson@pm.me", displayName: "Samantha Peterson (Organizer)"),
                Event.Organizer(email: "john.wick@proton.me", displayName: "john.wick@proton.me (Organizer)"),
            ]
        )
    )
    func testOrganizerMapping(givenOrganizer: RsvpOrganizer, expected: Event.Organizer) {
        let details = RsvpEvent.testData(organizer: givenOrganizer)
        let given = EventMapper.map(from: details)

        #expect(given.organizer == expected)
    }

    @Test(arguments: [
        (
            userAttendeeIndex: UInt32?(1),
            expected: [Event.Participant]([
                .init(email: "alice@proton.me", displayName: "Alice Sherington • alice@proton.me", status: .yes),
                .init(email: "bob@outlook.com", displayName: "You • bob@outlook.com", status: .no, ),
                .init(email: "cyril@gmail.com", displayName: "cyril@gmail.com", status: .maybe, ),
                .init(email: "donatan@pm.me", displayName: "Donatan Chelsea • donatan@pm.me", status: .unanswered),
            ])
        ),
        (
            userAttendeeIndex: Optional<UInt32>.none,
            expected: [Event.Participant]([
                .init(email: "alice@proton.me", displayName: "Alice Sherington • alice@proton.me", status: .yes),
                .init(email: "bob@outlook.com", displayName: "Bob Charlton • bob@outlook.com", status: .no),
                .init(email: "cyril@gmail.com", displayName: "cyril@gmail.com", status: .maybe, ),
                .init(email: "donatan@pm.me", displayName: "Donatan Chelsea • donatan@pm.me", status: .unanswered),
            ])
        ),
    ])
    func testParticipantsMapping(userAttendeeIndex: UInt32?, expectedParticipants: [Event.Participant]) {
        let attendees = [
            RsvpAttendee(name: "Alice Sherington", email: "alice@proton.me", status: .yes),
            RsvpAttendee(name: "Bob Charlton", email: "bob@outlook.com", status: .no),
            RsvpAttendee(name: .none, email: "cyril@gmail.com", status: .maybe),
            RsvpAttendee(name: "Donatan Chelsea", email: "donatan@pm.me", status: .unanswered),
        ]
        let details = RsvpEvent.testData(attendees: attendees, userAttendeeIdx: userAttendeeIndex)
        let given = EventMapper.map(from: details)

        #expect(given.participants == expectedParticipants)
    }
}

private extension LocalizedStringResource {
    static var empty: Self {
        "".notLocalized.stringResource
    }
}
