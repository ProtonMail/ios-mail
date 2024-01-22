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

    private unowned let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
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
        return BasicEventInfo(eventUID: uid, recurrenceID: nil)
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

        // temporary until we have a complete ICS parser

        let unencryptedCalendarEventsData = apiEvent.calendarEvents.filter { !$0.type.contains(.encrypted) }.map(\.data)
        let icsComponents: [String] = decryptedEvents + unencryptedCalendarEventsData
        let combinedICS = String(icsComponents.flatMap { $0 })

        let summary = combinedICS.preg_match(resultInGroup: 1, #"SUMMARY:([^\n]+)"#) ?? "missing summary"

        var participants: [EventDetails.Participant] = []

        if let organizerEmail = combinedICS.preg_match(resultInGroup: 1, #"ORGANIZER;CN=[^:]+:mailto:([^\n]+)"#) {
            participants.append(.init(email: organizerEmail, isOrganizer: true, status: .attending))
        } else if let organizerName = combinedICS.preg_match(resultInGroup: 1, #"ORGANIZER;CN=([^:]+)"#) {
            participants.append(.init(email: organizerName, isOrganizer: true, status: .attending))
        } else {
            participants.append(.init(email: "aubrey.thompson@proton.me", isOrganizer: true, status: .attending))
        }

        participants += (1...3).map {
            .init(email: "participant.\($0)@proton.me", isOrganizer: false, status: .attending)
        }

        let status: EventDetails.EventStatus?

        if let rawStatus = combinedICS.preg_match(resultInGroup: 1, #"STATUS:([^\r\n]+)"#) {
            status = .init(rawValue: rawStatus.lowercased())
        } else {
            status = nil
        }

        return .init(
            title: summary,
            startDate: Date(timeIntervalSince1970: apiEvent.startTime),
            endDate: Date(timeIntervalSince1970: apiEvent.endTime),
            calendar: .init(
                name: member.name,
                iconColor: member.color
            ),
            location: .init(
                name: "Zoom call"
            ),
            participants: participants,
            status: status,
            calendarAppDeepLink: .ProtonCalendar.showEvent(eventUID: basicEventInfo.eventUID)
        )
    }

    private func fetchEvent(basicEventInfo: BasicEventInfo) async throws -> FullEventTransformer {
        let calendarEventsRequest = CalendarEventsRequest(uid: basicEventInfo.eventUID)

        let calendarEventsResponse: CalendarEventsResponse = try await dependencies.apiService.perform(
            request: calendarEventsRequest
        ).1

        // TODO: instead of `first`, we might need to add filtering by RecurrenceID (not supported by current parser)
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
}

enum EventRSVPError: Error {
    case encryptedDataFoundButSessionKeyMissing
    case encryptedDataIsNotValidBase64
    case icsDataDoesNotContainUID
    case icsDataIsNotValidUTF8String
    case keyPacketIsNotValidBase64
    case noEventsReturnedFromAPI
    case noMembersInBootstrapResponse
    case noPassphraseForGivenMember
    case sessionKeyDecryptionFailed
}
