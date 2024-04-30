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
import ProtonCoreTestingToolkit
import XCTest

@testable import ProtonMail

final class FetchEventDetailsTests: XCTestCase {
    private var sut: FetchEventDetailsImpl!
    private var apiService: APIServiceMock!
    private var user: UserManager!

    private let summaryEvent = #"""
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:FOO
SUMMARY:Team Collaboration Workshop
END:VEVENT
END:VCALENDAR
"""#

    private let timeEvent = #"""
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:FOO
DTSTART:20240117T131800Z
END:VEVENT
END:VCALENDAR
"""#

    private let locationEvent = #"""
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:FOO
LOCATION:Zoom call
END:VEVENT
END:VCALENDAR
"""#

    private let organizerEvent = #"""
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:FOO
ORGANIZER;CN=boss:mailto:boss@example.com
END:VEVENT
END:VCALENDAR
"""#

    private let attendeeEvent = #"""
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:FOO
ATTENDEE;CN=employee1;X-PM-TOKEN=foo:mailto:employee1@example.com
ATTENDEE;CN=employee2;X-PM-TOKEN=bar:mailto:employee2@example.com
ATTENDEE;CN=employee3;X-PM-TOKEN=xyz:mailto:employee3@example.com
END:VEVENT
END:VCALENDAR
"""#

    private let calendarEvent = #"""
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:FOO
STATUS:CONFIRMED
END:VEVENT
END:VCALENDAR
"""#

    private var calendarID, eventUID, memberID, passphraseID: String!
    private var stubbedBasicEventInfo: BasicEventInfo!
    private var expectedEventDetails: EventDetails!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let testContainer = TestContainer()

        apiService = .init()
        user = try .prepareUser(apiMock: apiService, globalContainer: testContainer)
        sut = .init(dependencies: user.container)

        calendarID = UUID().uuidString
        eventUID = UUID().uuidString
        memberID = UUID().uuidString
        passphraseID = UUID().uuidString

        stubbedBasicEventInfo = BasicEventInfo(eventUID: eventUID, recurrenceID: nil)
        expectedEventDetails = .make(deepLinkComponents: (eventUID: eventUID, calendarID: calendarID))
    }

    override func tearDownWithError() throws {
        sut = nil
        apiService = nil
        user = nil

        memberID = nil
        passphraseID = nil
        expectedEventDetails = nil

        try super.tearDownWithError()
    }

    func testWhenEventIsEncryptedWithCalendarKeys_decryptsSuccessfully() async throws {
        try prepareSharedKeyPacketVariant()
        let eventDetails = try await sut.execute(basicEventInfo: stubbedBasicEventInfo)
        XCTAssertEqual(eventDetails, expectedEventDetails)
    }

    func testWhenEventIsEncryptedWithAddressKeys_decryptsSuccessfully() async throws {
        try prepareAddressKeyPacketVariant()
        let eventDetails = try await sut.execute(basicEventInfo: stubbedBasicEventInfo)
        XCTAssertEqual(eventDetails, expectedEventDetails)
    }
}

extension FetchEventDetailsTests {
    private func prepareSharedKeyPacketVariant() throws {
        let calendarKeyPair = try CryptoKeyHelper.makeKeyPair()

        let calendarPublicKey = calendarKeyPair.publicKey

        let fullEventTransformer = try makeEventResponse(
            encryptingSessionKeyWith: calendarPublicKey,
            setAddressKeyPacketInsteadOfSharedOne: false
        )

        let encryptedCalendarPassphrase = try Encryptor.encrypt(
            publicKey: .init(value: user.userInfo.addressKeys[0].publicKey),
            cleartext: calendarKeyPair.passphrase
        )

        let bootstrap = makeBootstrapResponse(
            keys: [
                .init(
                    ID: "",
                    calendarID: calendarID,
                    flags: .active,
                    passphraseID: passphraseID,
                    privateKey: calendarKeyPair.privateKey
                )
            ],
            memberPassphrases: [
                .init(memberID: memberID, passphrase: encryptedCalendarPassphrase.value)
            ]
        )

        setupAPIResponses(event: fullEventTransformer, bootstrap: bootstrap)
    }

    private func prepareAddressKeyPacketVariant() throws {
        let fullEventTransformer = try makeEventResponse(
            encryptingSessionKeyWith: user.userInfo.addressKeys[0].publicKey,
            setAddressKeyPacketInsteadOfSharedOne: true
        )

        let bootstrap = makeBootstrapResponse(keys: [], memberPassphrases: [])

        setupAPIResponses(event: fullEventTransformer, bootstrap: bootstrap)
    }

    private func makeEventResponse(
        encryptingSessionKeyWith publicKey: String,
        setAddressKeyPacketInsteadOfSharedOne: Bool
    ) throws -> FullEventTransformer {
        let sessionKeyBytes = try Crypto.random(byte: 32)
        let sessionKey = SessionKey(sessionKey: sessionKeyBytes, algo: .AES256)

        let cryptoSessionKey = try XCTUnwrap(CryptoGo.CryptoNewSessionKeyFromToken(
            sessionKey.sessionKey,
            sessionKey.algo.value
        ))

        let sharedEvents: [EventElement] = try [summaryEvent, timeEvent, locationEvent].map { icsString in
            try makeEncryptedEvent(icsString: icsString, cryptoSessionKey: cryptoSessionKey)
        }

        let attendeesEvents: [EventElement] = try [organizerEvent, attendeeEvent].map { icsString in
            try makeEncryptedEvent(icsString: icsString, cryptoSessionKey: cryptoSessionKey)
        }

        let calendarEvents: [EventElement] = [calendarEvent].map { icsString in
            EventElement(author: "", data: icsString, type: [])
        }

        let keyPacket = try Encryptor.encryptSession(publicKey: .init(value: publicKey), sessionKey: sessionKey).value

        let timeZoneIdentifier = TimeZone.autoupdatingCurrent.identifier

        let attendees: [AttendeeTransformer] = [
            AttendeeTransformer(ID: "", status: .unanswered, token: "foo"),
            AttendeeTransformer(ID: "", status: .yes, token: "bar"),
            AttendeeTransformer(ID: "", status: .unanswered, token: "xyz")
        ]

        return FullEventTransformer(
            ID: eventUID,
            addressID: nil,
            addressKeyPacket: setAddressKeyPacketInsteadOfSharedOne ? keyPacket : nil,
            attendees: attendees,
            attendeesEvents: attendeesEvents,
            calendarEvents: calendarEvents,
            calendarID: calendarID,
            calendarKeyPacket: nil,
            startTime: expectedEventDetails.startDate.timeIntervalSince1970,
            startTimezone: timeZoneIdentifier,
            endTime: expectedEventDetails.endDate.timeIntervalSince1970,
            endTimezone: timeZoneIdentifier,
            fullDay: 0,
            isOrganizer: 0,
            isProtonProtonInvite: 0,
            sharedEventID: UUID().uuidString,
            sharedKeyPacket: setAddressKeyPacketInsteadOfSharedOne ? nil : keyPacket,
            sharedEvents: sharedEvents
        )
    }

    private func makeEncryptedEvent(icsString: String, cryptoSessionKey: CryptoSessionKey) throws -> EventElement {
        let plaintext = CryptoGo.CryptoNewPlainMessageFromString(icsString)
        let ciphertext = try cryptoSessionKey.encrypt(plaintext).base64EncodedString()
        return EventElement(author: "", data: ciphertext, type: .encrypted)
    }

    private func makeBootstrapResponse(
        keys: [KeyTransformer],
        memberPassphrases: [MemberPassphraseTransformer]
    ) -> CalendarBootstrapResponse {
        CalendarBootstrapResponse(
            keys: keys,
            members: [
                .init(
                    ID: memberID,
                    color: expectedEventDetails.calendar.iconColor,
                    name: expectedEventDetails.calendar.name
                )
            ],
            passphrase: .init(ID: passphraseID, memberPassphrases: memberPassphrases)
        )
    }

    private func setupAPIResponses(event: FullEventTransformer, bootstrap: CalendarBootstrapResponse) {
        apiService.requestDecodableStub.bodyIs { _, _, path, anyParams, _, _, _, _, _, _, _, completion in
            switch path {
            case "/calendar/v1/events":
                guard
                    let params = anyParams as? [String: Any],
                    params["UID"] as? String == self.eventUID
                else {
                    XCTFail("Unexpected parameters: \(anyParams ?? [:])")
                    completion(nil, .failure(.badParameter(anyParams)))
                    return
                }

                let response: CalendarEventsResponse = .init(events: [event])
                completion(nil, .success(response))
            case "/calendar/v1/\(self.calendarID!)/bootstrap":
                completion(nil, .success(bootstrap))
            default:
                XCTFail("Unexpected path: \(path)")
                completion(nil, .failure(.badParameter(path)))
            }
        }
    }
}
