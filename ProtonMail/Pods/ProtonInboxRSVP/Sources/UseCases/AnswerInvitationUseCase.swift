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
import ProtonInboxICal
import protocol ProtonCoreServices.APIService

public struct AnswerInvitationUseCase {

    public struct Context {
        public let answer: AttendeeStatusDisplay
        public let validatedAnswer: AnswerToEvent.ValidatedContext
        public let currentDate: Date

        public init(answer: AttendeeStatusDisplay, validatedAnswer: AnswerToEvent.ValidatedContext, currentDate: Date) {
            self.answer = answer
            self.validatedAnswer = validatedAnswer
            self.currentDate = currentDate
        }
    }

    private let currentDateProvider: CurrentDateProviding
    private let dataValidator: AnswerToEventDataValidator
    private let eventsToResetRepository: EventsToResetAnswerRepository
    private let autoAddedKeyPacketUploader: AutoAddedEventKeyPacketUploader
    private let statusUpdater: AnswerInvitationAttendeeStatusUpdater
    private let personalPartUpdater: EventPersonalPartUpdater
    private let organizerNotifier: AnswerInvitationOrganizerNotifier

    public init(
        emailSender: EmailSending,
        localization: L10nProviding,
        dateFormatterProvider: DateFormatterProviding,
        currentDateProvider: CurrentDateProviding,
        attendeeStorage: AttendeeStorage,
        calendarKeyStorage: CalendarKeyStorage,
        emailAddressStorage: EmailAddressStorage,
        eventStorage: EventStorage,
        passphraseStorage: UserPassphraseStorage,
        userStorage: CurrentUserStorage,
        eventKeyPacketUpdater: EventKeyPacketUpdating,
        eventParticipationStatusUpdater: EventParticipationStatusUpdating,
        eventPersonalPartUpdater: EventPersonalPartUpdating,
        userPreContactsProvider: UserPreContactsProviding,
        vTimeZonesInfoProvider: VTimeZonesInfoProviding,
        recipientProvider: RecipientProviding
    ) {
        self.currentDateProvider = currentDateProvider
        dataValidator = .init(
            userStorage: userStorage,
            eventStorage: eventStorage,
            passphraseStorage: passphraseStorage
        )
        eventsToResetRepository = .init(emailAddressStorage: emailAddressStorage)
        autoAddedKeyPacketUploader = .init(
            eventKeyPacketUpdater: eventKeyPacketUpdater,
            calendarKeyStorage: calendarKeyStorage
        )
        statusUpdater = .init(
            eventParticipationStatusUpdater: eventParticipationStatusUpdater,
            attendeeStatusStorage: attendeeStorage
        )
        personalPartUpdater = .init(eventPersonalPartUpdater: eventPersonalPartUpdater)
        organizerNotifier = .init(
            emailSender: emailSender,
            localization: localization,
            dateFormatterProvider: dateFormatterProvider,
            vTimeZonesInfoProvider: vTimeZonesInfoProvider,
            userPreContactsProvider: userPreContactsProvider,
            recipientProvider: recipientProvider
        )
    }

    public func execute(
        with answer: AttendeeStatusDisplay,
        for event: IdentifiableEvent,
        calendar: CalendarInfo,
        validatedContext: AnswerToEvent.ValidatedContext
    ) -> AnyPublisher<Void, Error> {
        let addressKeys = validatedContext.invitedParticipant.address.keys

        switch dataValidator.validationResult(for: event, addressKeys: addressKeys) {
        case .success(let validatedData):
            return answerEvent(answer, calendar, validatedData, validatedContext)
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    private func answerEvent(
        _ answer: AttendeeStatusDisplay,
        _ calendar: CalendarInfo,
        _ validatedData: AnswerToEventDataValidator.Data,
        _ validatedContext: AnswerToEvent.ValidatedContext
    ) -> AnyPublisher<Void, Error> {
        let calendarEvent = validatedData.calendarEvent
        let addressKeyPackage = validatedData.addressKeyPackage

        return updateAutoAddedEvent(calendarEvent.iCalEvent, addressKeyPackage)
            .flatMap { _ -> AnyPublisher<Void, Error> in
                let context = Context(
                    answer: answer,
                    validatedAnswer: validatedContext,
                    currentDate: currentDateProvider.currentDate()
                )

                switch calendarEvent.iCalEvent.isProtonToProtonInvitation {
                case true:
                    return answerProtonToProton(context, calendarEvent, addressKeyPackage)
                case false:
                    return answerProtonToExternal(context, calendarEvent, calendar, addressKeyPackage)
                }
            }
            .eraseToAnyPublisher()
    }

    private func answerProtonToProton(
        _ context: Context,
        _ calendarEvent: CalendarEvent,
        _ keyPackage: AddressKeyPackage
    ) -> AnyPublisher<Void, Error> {
        updateAttendeeStatusAndPersonalPart(context.updateAttendeeStatusContext, calendarEvent.iCalEvent, keyPackage)
            .flatMap {
                organizerNotifier.notifyOrganizer(
                    of: calendarEvent.iCalEvent.withoutWKST(),
                    context: context,
                    keyPackage: keyPackage
                )
            }
            .eraseToAnyPublisher()
    }

    private func answerProtonToExternal(
        _ context: Context,
        _ calendarEvent: CalendarEvent,
        _ calendar: CalendarInfo,
        _ keyPackage: AddressKeyPackage
    ) -> AnyPublisher<Void, Error> {
        organizerNotifier
            .notifyOrganizer(
                of: calendarEvent.iCalEvent.withoutWKST(),
                context: context,
                keyPackage: keyPackage
            )
            .flatMap {
                updateAttendeeStatusAndPersonalPart(
                    context.updateAttendeeStatusContext,
                    calendarEvent.iCalEvent,
                    keyPackage
                )
            }
            .flatMap {
                resetSingleEditsToUnanswered(
                    notMatchingWith: context.answer,
                    currentDate: context.currentDate,
                    calendarEvent: calendarEvent,
                    calendarDetails: calendar,
                    keyPackage: keyPackage
                )
            }
            .eraseToAnyPublisher()
    }

    private func updateAutoAddedEvent(
        _ calendarEvent: ICalEvent,
        _ keyPackage: AddressKeyPackage
    ) -> AnyPublisher<Void, Error> {
        guard let addressKeyPacket = calendarEvent.addressKeyPacket else {
            return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        return autoAddedKeyPacketUploader.uploadReEncryptedKeyPacket(
            addressKeyPacket: addressKeyPacket,
            for: calendarEvent.identificationData,
            decryptionPackage: keyPackage
        )
    }

    private func updateAttendeeStatusAndPersonalPart(
        _ context: AnswerInvitationAttendeeStatusUpdater.Context,
        _ calendarEvent: ICalEvent,
        _ keyPackage: AddressKeyPackage
    ) -> AnyPublisher<Void, Error> {
        statusUpdater
            .updateAttendeeStatus(at: calendarEvent.identificationData, with: context)
            .flatMap {
                personalPartUpdater
                    .updatePersonalPart(of: calendarEvent, for: context.answer)
                    .replaceError(with: ())
            }
            .eraseToAnyPublisher()
    }

    private func resetSingleEditsToUnanswered(
        notMatchingWith answer: AttendeeStatusDisplay,
        currentDate: Date,
        calendarEvent: CalendarEvent,
        calendarDetails: CalendarInfo,
        keyPackage: AddressKeyPackage
    ) -> AnyPublisher<Void, Error> {
        let singleEditsToReset = eventsToResetRepository.singleEditsToReset(
            notMatchingWith: answer,
            calendarEvent: calendarEvent,
            calendarDetails: calendarDetails
        )

        guard !singleEditsToReset.isEmpty else {
            return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        let unansweredContext = AnswerInvitationAttendeeStatusUpdater.Context.unanswered(currentDate: currentDate)

        return Publishers
            .MergeMany(
                singleEditsToReset.map { eventToReset in
                    updateAttendeeStatusAndPersonalPart(unansweredContext(eventToReset), eventToReset.model, keyPackage)
                }
            )
            .collect()
            .mapToVoid()
    }

}

private extension AttendeeAnswer {

    init(answer: AttendeeStatusDisplay) {
        switch answer {
        case .maybe:
            self = .maybe
        case .no:
            self = .no
        case .yes:
            self = .yes
        }
    }

}

private extension AnswerInvitationAttendeeStatusUpdater.Context {

    static func unanswered(currentDate: Date) -> (EventToAnswer) -> Self {
        return { eventToReset in
            .init(
                answer: .unanswered,
                attendee: eventToReset.validatedContext.invitedParticipant.attendee,
                currentDate: currentDate
            )
        }
    }

}

private extension ICalEvent {

    private struct EventIdentificationData: IdentifiableEvent {
        let id: String
        let startDate: Date
        let calendarID: String
    }

    var identificationData: IdentifiableEvent {
        EventIdentificationData(id: apiEventId.unsafelyUnwrapped, startDate: startDate, calendarID: calendarID)
    }

}

private extension AnswerInvitationUseCase.Context {

    var updateAttendeeStatusContext: AnswerInvitationAttendeeStatusUpdater.Context {
        .init(
            answer: .init(answer: answer),
            attendee: validatedAnswer.invitedParticipant.attendee,
            currentDate: currentDate
        )
    }

}
