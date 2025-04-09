// Copyright (c) 2024 Proton Technologies AG
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

import ProtonCoreCrypto
import ProtonCoreCryptoGoInterface
import ProtonCoreDataModel
import ProtonInboxICal
import ProtonInboxRSVP

// sourcery: mock
protocol FetchEventDetails {
    func execute(basicEventInfo: BasicEventInfo) async throws -> (EventDetails, AnsweringContext?)
}

struct FetchEventDetailsImpl: FetchEventDetails {
    typealias Dependencies = AnyObject & HasAPIService & HasEmailAddressStorage & HasUserManager

    private let answerToEventPermissionValidator: AnswerToEventPermissionValidator
    private let iCalReader: ICalReader
    private let iCalRecurrenceFormatter = ICalRecurrenceFormatter()
    private let timeZoneProvider = TimeZoneProvider()
    private unowned let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies

        answerToEventPermissionValidator = .init(emailAddressStorage: dependencies.emailAddressStorage)

        let iCalWriter = ICalWriter(timestamp: Date.init)

        iCalReader = ICalReader(
            timeZoneProvider: timeZoneProvider,
            currentDateProvider: Date.init,
            icsUIDProvider: { "\(UUID().uuidString)@proton.me" },
            iCalWriter: iCalWriter
        )
    }

    func execute(basicEventInfo: BasicEventInfo) async throws -> (EventDetails, AnsweringContext?) {
        let apiEvents = try await fetchEvents(uid: basicEventInfo.eventUID)

        guard
            let apiEvent = apiEvents.first(where: { $0.recurrenceID == basicEventInfo.recurrenceID }) ?? apiEvents.first
        else {
            throw EventRSVPError.noEventsReturnedFromAPI
        }

        let calendarBootstrapResponse = try await fetchCalendarBootstrapData(calendarID: apiEvent.calendarID)

        guard let member = calendarBootstrapResponse.members.first else {
            throw EventRSVPError.noMembersInBootstrapResponse
        }

        let decryptionKit = makeDecryptionKit(calendarBootstrapResponse: calendarBootstrapResponse, memberID: member.ID)

        let iCalEvent = try decrypt(apiEvent: apiEvent, decryptionKit: decryptionKit)

        let invitees: [EventDetails.Participant] = iCalEvent.participants
            .filter { $0.user != iCalEvent.organizer?.user }
            .map { .init(attendeeModel: $0) }

        let dateInterval = calculateDateInterval(iCalEvent: iCalEvent, occurrence: basicEventInfo.occurrence)

        let eventIdentificationData = EventIdentificationData(
            id: apiEvent.ID,
            calendarID: apiEvent.calendarID,
            startDate: dateInterval.start
        )

        let answeringAllowed = !basicEventInfo.isReminder

        let answeringContext: AnsweringContext?
        if answeringAllowed {
            answeringContext = try prepareAnsweringContext(
                iCalEvent: iCalEvent,
                apiEvents: apiEvents,
                attendeeTransformers: apiEvent.attendees,
                decryptionKit: decryptionKit,
                eventIdentificationData: eventIdentificationData,
                keyTransformers: calendarBootstrapResponse.keys,
                member: member
            )
        } else {
            answeringContext = nil
        }

        let currentUserAmongInvitees = answeringContext.map {
            EventDetails.Participant(attendeeModel: $0.validated.invitedParticipant.attendee)
        }

        let eventDetails = EventDetails(
            title: iCalEvent.title,
            startDate: dateInterval.start,
            endDate: dateInterval.end,
            isAllDay: iCalEvent.isAllDay,
            recurrence: iCalRecurrenceFormatter.string(from: iCalEvent.recurrence, startDate: iCalEvent.startDate),
            calendar: .init(name: member.name, iconColor: member.color),
            location: (iCalEvent.location?.title).map { .init(name: $0) },
            organizer: iCalEvent.organizer.map { .init(attendeeModel: $0) },
            invitees: invitees,
            currentUserAmongInvitees: currentUserAmongInvitees,
            status: iCalEvent.status.flatMap { EventDetails.EventStatus(rawValue: $0.lowercased()) },
            calendarAppDeepLink: .ProtonCalendar.eventDetails(for: eventIdentificationData)
        )

        return (eventDetails, answeringContext)
    }

    private func fetchEvents(uid: String) async throws -> [FullEventTransformer] {
        let calendarEventsRequest = CalendarEventsRequest(uid: uid)

        let calendarEventsResponse: CalendarEventsResponse = try await dependencies.apiService.perform(
            request: calendarEventsRequest
        ).1

        return calendarEventsResponse.events
    }

    private func fetchCalendarBootstrapData(calendarID: String) async throws -> CalendarBootstrapResponse {
        let calendarBootstrapRequest = CalendarBootstrapRequest(calendarID: calendarID)
        return try await dependencies.apiService.perform(request: calendarBootstrapRequest).1
    }

    private func makeDecryptionKit(
        calendarBootstrapResponse: CalendarBootstrapResponse,
        memberID: String
    ) -> DecryptionKit {
        let addressKeys = MailCrypto.decryptionKeys(
            basedOn: dependencies.user.userInfo.addressKeys,
            mailboxPassword: dependencies.user.mailboxPassword,
            userKeys: dependencies.user.userInfo.userPrivateKeys
        )

        return DecryptionKit(
            addressKeys: addressKeys,
            calendarBootstrapResponse: calendarBootstrapResponse,
            memberID: memberID
        )
    }

    private func decrypt(apiEvent: FullEventTransformer, decryptionKit: DecryptionKit) throws -> ICalEvent {
        let sessionKey = try obtainSessionKey(apiEvent: apiEvent, decryptionKit: decryptionKit)
        let relevantEvents = apiEvent.sharedEvents + apiEvent.attendeesEvents
        let decryptedEvents = try decryptIfNeeded(events: relevantEvents, using: sessionKey)
        let unencryptedCalendarEventsData = apiEvent.calendarEvents.filter { !$0.type.contains(.encrypted) }.map(\.data)
        let icsComponents: [String] = decryptedEvents + unencryptedCalendarEventsData
        let combinedICS = try combineICS(components: icsComponents)
        return parseICS(combinedICS, withAuxilliaryInfo: apiEvent)
    }

    private func obtainSessionKey(apiEvent: FullEventTransformer, decryptionKit: DecryptionKit) throws -> SessionKey? {
        let keyPacket: String
        let decryptionKeys: [DecryptionKey]

        if let sharedKeyPacket = apiEvent.sharedKeyPacket {
            keyPacket = sharedKeyPacket

            guard let memberPassphrase = decryptionKit.calendarBootstrapResponse.passphrase.memberPassphrases.first(
                where: { $0.memberID == decryptionKit.memberID }
            ) else {
                throw EventRSVPError.noPassphraseForGivenMember
            }

            let encryptedCalendarPassphrase = memberPassphrase.passphrase

            let decryptedCalendarPassphrase: String = try Decryptor.decrypt(
                decryptionKeys: decryptionKit.addressKeys,
                encrypted: ArmoredMessage(value: encryptedCalendarPassphrase)
            )

            decryptionKeys = decryptionKit.calendarBootstrapResponse.keys
                .filter {
                    $0.flags.contains(.active)
                    &&
                    $0.passphraseID == decryptionKit.calendarBootstrapResponse.passphrase.ID
                }
                .map { calendarKey in
                    DecryptionKey(
                        privateKey: ArmoredKey(value: calendarKey.privateKey),
                        passphrase: .init(value: decryptedCalendarPassphrase)
                    )
                }
        } else if let addressKeyPacket = apiEvent.addressKeyPacket {
            keyPacket = addressKeyPacket
            decryptionKeys = decryptionKit.addressKeys
        } else {
            return nil
        }

        guard let keyPacketData = Data(base64Encoded: keyPacket) else {
            throw EventRSVPError.keyPacketIsNotValidBase64
        }

        return try Decryptor.decryptSessionKey(decryptionKeys: decryptionKeys, keyPacket: keyPacketData)
    }

    private func decryptIfNeeded(events: [EventElement], using sessionKey: SessionKey?) throws -> [String] {
        try events.map { event in
            if event.type.contains(.encrypted) {
                guard let sessionKey else {
                    throw EventRSVPError.encryptedDataFoundButSessionKeyMissing
                }

                guard let ciphertext = Data(base64Encoded: event.data) else {
                    throw EventRSVPError.encryptedDataIsNotValidBase64
                }

                guard let cryptoSessionKey = CryptoGo.CryptoNewSessionKeyFromToken(
                    sessionKey.sessionKey,
                    sessionKey.algo.value
                ) else {
                    throw EventRSVPError.sessionKeyDecryptionFailed
                }

                let plaintext = try cryptoSessionKey.decrypt(ciphertext)
                return plaintext.getString()
            } else {
                return event.data
            }
        }
    }

    private func combineICS(components: [String]) throws -> String {
        guard let firstComponent = components.first else {
            throw EventRSVPError.noICSComponents
        }

        let remainingComponents = components.dropFirst()

        return remainingComponents.reduce(firstComponent) { combinedICS, icsComponent in
            iCalReader.parse_and_merge_event_ics(old: combinedICS, new: icsComponent)
        }
    }

    private func parseICS(_ ics: String, withAuxilliaryInfo apiEvent: FullEventTransformer) -> ICalEvent {
        let addresses: [ICalAddress] = dependencies.emailAddressStorage.currentUserAddresses().map {
            .init(id: $0.id, email: $0.email, order: $0.order, send: $0.send)
        }

        let dependecies = ICalReaderDependecies(
            startDate: Date(timeIntervalSince1970: apiEvent.startTime),
            startDateTimeZone: timeZoneProvider.timeZone(identifier: apiEvent.startTimezone),
            startDateTimeZoneIdentifier: apiEvent.startTimezone,
            endDate: Date(timeIntervalSince1970: apiEvent.endTime),
            endDateTimeZoneIdentifier: apiEvent.endTimezone,
            endDateTimeZone: timeZoneProvider.timeZone(identifier: apiEvent.endTimezone),
            calendarID: apiEvent.calendarID,
            localEventID: "",
            addresses: addresses,
            ics: ics,
            apiEventID: apiEvent.ID,
            startDateCalendar: .autoupdatingCurrent,
            addressKeyPacket: apiEvent.addressKeyPacket,
            sharedEventID: apiEvent.sharedEventID,
            sharedKeyPacket: apiEvent.sharedKeyPacket,
            calendarKeyPacket: apiEvent.calendarKeyPacket,
            isOrganizer: apiEvent.isOrganizer == 1,
            isProtonToProtonInvitation: apiEvent.isProtonProtonInvite == 1,
            notifications: nil,
            lastModifiedInCoreData: nil,
            color: apiEvent.color
        )

        let attendeeData: [ICalAttendeeData] = apiEvent.attendees.map {
            .init(eventID: apiEvent.ID, status: $0.status.rawValue, token: $0.token, comment: nil)
        }

        return iCalReader.parse_single_event_ics(dependecies: dependecies, attendeeData: attendeeData)
    }

    private func calculateDateInterval(iCalEvent: ICalEvent, occurrence: Int?) -> DateInterval {
        if let occurrence {
            let startDateOfThisSpecificOccurrence = Date(timeIntervalSince1970: TimeInterval(occurrence))
            let duration = iCalEvent.endDate.timeIntervalSince(iCalEvent.startDate)
            return DateInterval(start: startDateOfThisSpecificOccurrence, duration: duration)
        } else {
            return DateInterval(start: iCalEvent.startDate, end: iCalEvent.endDate)
        }
    }

    private func prepareAnsweringContext(
        iCalEvent: ICalEvent,
        apiEvents: [FullEventTransformer],
        attendeeTransformers: [AttendeeTransformer],
        decryptionKit: DecryptionKit,
        eventIdentificationData: EventIdentificationData,
        keyTransformers: [KeyTransformer],
        member: MemberTransformer
    ) throws -> AnsweringContext? {
        let calendarInfo = CalendarInfo(member: member)
        let validationResult = answerToEventPermissionValidator.canAnswer(for: iCalEvent, with: calendarInfo)

        switch validationResult {
        case .canAnswer(let validatedContext):
            let eventType = try calculateEventType(
                iCalEvent: iCalEvent,
                apiEvents: apiEvents,
                decryptionKit: decryptionKit
            )

            return .init(
                attendeeTransformers: attendeeTransformers,
                calendarInfo: calendarInfo,
                event: eventIdentificationData,
                eventType: eventType,
                keyTransformers: keyTransformers,
                iCalEvent: iCalEvent,
                validated: validatedContext
            )
        case .canNotAnswer:
            return nil
        }
    }

    private func calculateEventType(
        iCalEvent: ICalEvent,
        apiEvents: [FullEventTransformer],
        decryptionKit: DecryptionKit
    ) throws -> EventType {
        let isSingleEdit = iCalEvent.recurrenceID != nil

        if isSingleEdit {
            let mainOccurrenceExists = apiEvents.contains { $0.recurrenceID == nil }
            let unusedEditInfo = EventType.SingleEdit.EditInfo(editCount: .one, deletionCount: 0)
            return .singleEdit(mainOccurrenceExists ? .regular(editInfo: unusedEditInfo) : .orphan)
        } else {
            if iCalEvent.recurrence.doesRepeat {
                let singleEdits = try apiEvents
                    .filter { $0.recurrenceID != nil }
                    .map { try decrypt(apiEvent: $0, decryptionKit: decryptionKit) }

                return .recurring(.init(mainOccurrence: iCalEvent, singleEdits: singleEdits))
            } else {
                return .nonRecurring
            }
        }
    }
}

private struct DecryptionKit {
    let addressKeys: [DecryptionKey]
    let calendarBootstrapResponse: CalendarBootstrapResponse
    let memberID: String
}
