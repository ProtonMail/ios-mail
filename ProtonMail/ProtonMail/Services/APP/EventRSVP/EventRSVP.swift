// Copyright (c) 2023 Proton Technologies AG
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
import ProtonCoreServices
import ProtonInboxICal

// sourcery: mock
protocol EventRSVP {
    func extractBasicEventInfo(icsData: Data) throws -> BasicEventInfo
    func fetchEventDetails(basicEventInfo: BasicEventInfo) async throws -> EventDetails
}

struct LocalEventRSVP: EventRSVP {
    typealias Dependencies = AnyObject & HasAPIService & HasUserManager

    private let iCalReader: ICalReader
    private let timeZoneProvider = TimeZoneProvider()
    private unowned let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies

        let iCalWriter = ICalWriter(timestamp: Date.init)

        iCalReader = ICalReader(
            timeZoneProvider: timeZoneProvider,
            currentDateProvider: Date.init,
            icsUIDProvider: { "\(UUID().uuidString)@proton.me" },
            iCalWriter: iCalWriter
        )
    }

    func extractBasicEventInfo(icsData: Data) throws -> BasicEventInfo {
        guard let icsString = String(data: icsData, encoding: .utf8) else {
            throw EventRSVPError.icsDataIsNotValidUTF8String
        }

        let component = icalparser_parse_string(icsString)

        defer {
            icalcomponent_free(component)
        }

        guard let uidComponent = icalcomponent_get_uid(component) else {
            throw EventRSVPError.icsDataDoesNotContainUID
        }

        let uid = String(cString: uidComponent)
        let recurrenceID = icalcomponent_get_recurrenceid(component).toUnixTimestamp()
        return BasicEventInfo(eventUID: uid, recurrenceID: recurrenceID)
    }

    func fetchEventDetails(basicEventInfo: BasicEventInfo) async throws -> EventDetails {
        let apiEvent = try await fetchEvent(basicEventInfo: basicEventInfo)
        let calendarBootstrapResponse = try await fetchCalendarBootstrapData(calendarID: apiEvent.calendarID)

        guard let member = calendarBootstrapResponse.members.first else {
            throw EventRSVPError.noMembersInBootstrapResponse
        }

        let sessionKey = try obtainSessionKey(
            apiEvent: apiEvent,
            calendarBootstrapResponse: calendarBootstrapResponse,
            memberID: member.ID
        )

        let relevantEvents = apiEvent.sharedEvents + apiEvent.attendeesEvents
        let decryptedEvents = try decryptIfNeeded(events: relevantEvents, using: sessionKey)
        let unencryptedCalendarEventsData = apiEvent.calendarEvents.filter { !$0.type.contains(.encrypted) }.map(\.data)
        let icsComponents: [String] = decryptedEvents + unencryptedCalendarEventsData
        let combinedICS = try combineICS(components: icsComponents)
        let iCalEvent = parseICS(combinedICS, withAuxilliaryInfo: apiEvent)

        let invitees: [EventDetails.Participant] = iCalEvent.participants
            .filter { $0.user != iCalEvent.organizer?.user }
            .map { .init(attendeeModel: $0) }

        return .init(
            title: iCalEvent.title,
            startDate: Date(timeIntervalSince1970: apiEvent.startTime),
            endDate: Date(timeIntervalSince1970: apiEvent.endTime),
            calendar: .init(name: member.name, iconColor: member.color),
            location: (iCalEvent.location?.title).map { .init(name: $0) },
            organizer: iCalEvent.organizer.map { .init(attendeeModel: $0) },
            invitees: invitees,
            status: iCalEvent.status.flatMap { EventDetails.EventStatus(rawValue: $0.lowercased()) },
            calendarAppDeepLink: .ProtonCalendar.showEvent(eventUID: basicEventInfo.eventUID)
        )
    }

    private func fetchEvent(basicEventInfo: BasicEventInfo) async throws -> FullEventTransformer {
        let calendarEventsRequest = CalendarEventsRequest(
            uid: basicEventInfo.eventUID,
            recurrenceID: basicEventInfo.recurrenceID
        )

        let calendarEventsResponse: CalendarEventsResponse = try await dependencies.apiService.perform(
            request: calendarEventsRequest
        ).1

        guard let apiEvent = calendarEventsResponse.events.first else {
            throw EventRSVPError.noEventsReturnedFromAPI
        }

        return apiEvent
    }

    private func fetchCalendarBootstrapData(calendarID: String) async throws -> CalendarBootstrapResponse {
        let calendarBootstrapRequest = CalendarBootstrapRequest(calendarID: calendarID)
        return try await dependencies.apiService.perform(request: calendarBootstrapRequest).1
    }

    private func obtainSessionKey(
        apiEvent: FullEventTransformer,
        calendarBootstrapResponse: CalendarBootstrapResponse,
        memberID: String
    ) throws -> SessionKey? {
        let addressKeys = MailCrypto.decryptionKeys(
            basedOn: dependencies.user.userInfo.addressKeys,
            mailboxPassword: dependencies.user.mailboxPassword,
            userKeys: dependencies.user.userInfo.userPrivateKeys
        )

        let keyPacket: String
        let decryptionKeys: [DecryptionKey]

        if let sharedKeyPacket = apiEvent.sharedKeyPacket {
            keyPacket = sharedKeyPacket

            guard let memberPassphrase = calendarBootstrapResponse.passphrase.memberPassphrases.first(
                where: { $0.memberID == memberID }
            ) else {
                throw EventRSVPError.noPassphraseForGivenMember
            }

            let encryptedCalendarPassphrase = memberPassphrase.passphrase

            let decryptedCalendarPassphrase: String = try Decryptor.decrypt(
                decryptionKeys: addressKeys,
                encrypted: ArmoredMessage(value: encryptedCalendarPassphrase)
            )

            decryptionKeys = calendarBootstrapResponse.keys
                .filter { $0.flags != .inactive && $0.passphraseID == calendarBootstrapResponse.passphrase.ID }
                .map { calendarKey in
                    DecryptionKey(
                        privateKey: ArmoredKey(value: calendarKey.privateKey),
                        passphrase: .init(value: decryptedCalendarPassphrase)
                    )
                }
        } else if let addressKeyPacket = apiEvent.addressKeyPacket {
            keyPacket = addressKeyPacket
            decryptionKeys = addressKeys
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

        return remainingComponents.reduce(firstComponent, iCalReader.parse_and_merge_event_ics)
    }

    private func parseICS(_ ics: String, withAuxilliaryInfo apiEvent: FullEventTransformer) -> ICalEvent {
        let canonizedUserEmailAddresses = dependencies.user.addresses.map { $0.email.canonicalizeEmail() }

        let dependecies = ICalReaderDependecies(
            startDate: Date(timeIntervalSince1970: apiEvent.startTime),
            startDateTimeZone: timeZoneProvider.timeZone(identifier: apiEvent.startTimezone),
            startDateTimeZoneIdentifier: apiEvent.startTimezone,
            endDate: Date(timeIntervalSince1970: apiEvent.endTime),
            endDateTimeZoneIdentifier: apiEvent.endTimezone,
            endDateTimeZone: timeZoneProvider.timeZone(identifier: apiEvent.endTimezone),
            calendarID: apiEvent.calendarID,
            localEventID: "",
            allEmailsCanonized: canonizedUserEmailAddresses,
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
            lastModifiedInCoreData: nil
        )

        let attendeeData: [ICalAttendeeData] = apiEvent.attendees.map {
            .init(eventID: apiEvent.ID, status: $0.status, token: $0.token)
        }

        return iCalReader.parse_single_event_ics(dependecies: dependecies, attendeeData: attendeeData)
    }
}

enum EventRSVPError: Error {
    case encryptedDataFoundButSessionKeyMissing
    case encryptedDataIsNotValidBase64
    case icsDataDoesNotContainUID
    case icsDataIsNotValidUTF8String
    case keyPacketIsNotValidBase64
    case noEventsReturnedFromAPI
    case noICSComponents
    case noMembersInBootstrapResponse
    case noPassphraseForGivenMember
    case sessionKeyDecryptionFailed
}

extension icaltimetype {
    func toUnixTimestamp() -> Int? {
        guard let cString = icaltime_as_ical_string(self) else {
            return nil
        }

        let string = String(cString: cString)

        guard let date = Date.getDateFrom(timeString: string)?.date else {
            return nil
        }

        return Int(date.timeIntervalSince1970)
    }
}
