// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Technologies AG and Proton Calendar.
//
// Proton Calendar is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Calendar is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Calendar. If not, see https://www.gnu.org/licenses/.

import Combine
import EventKit
import ProtonInboxICal
import ProtonCoreFeatures
import ProtonCoreServices

public struct AnswerInvitationOrganizerNotifier {
    private let icsTimeZonesDecorator: InvitationICSTimeZonesDecorator
    private let invitationEmailSender: InvitationEmailSender
    private let emailSubjectFormatter: AnswerEventEmailSubjectFormatter
    private let emailBodyFormatter: AnswerInvitationEmailBodyFormatter
    private let recipientProvider: RecipientProviding

    public init(
        emailSender: EmailSending,
        localization: L10nProviding,
        dateFormatterProvider: DateFormatterProviding,
        vTimeZonesInfoProvider: VTimeZonesInfoProviding,
        userPreContactsProvider: UserPreContactsProviding,
        recipientProvider: RecipientProviding
    ) {
        icsTimeZonesDecorator = .init(vTimeZonesInfoProvider: vTimeZonesInfoProvider)
        invitationEmailSender = .init(
            emailSender: emailSender,
            userPreContactsProvider: userPreContactsProvider
        )
        emailSubjectFormatter = .init(
            localization: localization,
            dateFormatterProvider: dateFormatterProvider
        )
        emailBodyFormatter = .init(localization: localization)
        self.recipientProvider = recipientProvider
    }

    public func notifyOrganizer(
        of event: ICalEvent,
        context: AnswerInvitationUseCase.Context,
        keyPackage: AddressKeyPackage
    ) -> AnyPublisher<Void, Error> {
        let updatedAttendee = context.validatedAnswer.invitedParticipant.attendee
            .copy(withStatus: context.answer.participantStatus)
            .copy(withToken: nil)
        let updatedEvent = event.copy(withParticipants: [updatedAttendee])
        let icsMethod: ICSMethod = .reply

        return icsTimeZonesDecorator
            .build(for: icsMethod, event: updatedEvent, timestamp: context.currentDate)
            .flatMap { ics in
                recipientProvider
                    .recipient(email: context.validatedAnswer.organizer.user.email)
                    .map { organizer in (ics, organizer) }
            }
            .flatMap { ics, organizer in
                invitationEmailSender.send(
                    content: .init(
                        subject: emailSubjectFormatter.string(for: event, userID: keyPackage.passphraseInfo.user.ID),
                        body: emailBodyFormatter.string(
                            from: event,
                            with: context.answer,
                            attendeeEmail: context.validatedAnswer.invitedParticipant.attendee.user.email
                        ),
                        ics: .init(value: ics, method: icsMethod)
                    ),
                    toRecipients: [organizer],
                    senderParticipant: context.validatedAnswer.invitedParticipant,
                    addressKeyPackage: keyPackage
                )
            }
            .eraseToAnyPublisher()
    }
}

private extension ICalEvent {

    func copy(withParticipants participants: [ICalAttendee]) -> Self {
        var updatedEvent = self
        updatedEvent.participants = participants
        return updatedEvent
    }

}

private extension AttendeeStatusDisplay {

    var participantStatus: EKParticipantStatus {
        switch self {
        case .maybe:
            return .tentative
        case .no:
            return .declined
        case .yes:
            return .accepted
        }
    }

}
