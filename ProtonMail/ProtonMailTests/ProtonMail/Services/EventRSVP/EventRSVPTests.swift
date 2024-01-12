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
import ProtonCoreTestingToolkit
import XCTest

@testable import ProtonMail

final class EventRSVPTests: XCTestCase {
    private var sut: EventRSVP!
    private var apiService: APIServiceMock!
    private var user: UserManager!

    private let stubbedBasicEventInfo = BasicEventInfo(eventUID: "foo", recurrenceID: nil)

    private let summaryEvent = #"""
BEGIN:VCALENDAR
BEGIN:VEVENT
SUMMARY:Team Collaboration Workshop
END:VEVENT
END:VCALENDAR
"""#

    private let locationEvent = #"""
BEGIN:VCALENDAR
BEGIN:VEVENT
LOCATION:Zoom call
END:VEVENT
END:VCALENDAR
"""#

    private let organizerEvent = #"""
BEGIN:VCALENDAR
BEGIN:VEVENT
ORGANIZER;CN=boss:mailto:boss@example.com
END:VEVENT
END:VCALENDAR
"""#

    private let attendeeEvent = #"""
BEGIN:VCALENDAR
BEGIN:VEVENT
ATTENDEE;CN=employee1;ROLE=REQ-PARTICIPANT;RSVP=TRUE;X-PM-TOKEN=45
 6566bd0697f7f4539f7dcf1d39427c0582339b:mailto:employee1@example.com
END:VEVENT
END:VCALENDAR
"""#

    private var memberID, passphraseID: String!

    private var expectedEventDetails: EventDetails!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let testContainer = TestContainer()

        apiService = .init()
        user = try .prepareUser(apiMock: apiService, globalContainer: testContainer)
        sut = LocalEventRSVP(dependencies: user.container)

        memberID = UUID().uuidString
        passphraseID = UUID().uuidString

        expectedEventDetails = .init(
            title: "Team Collaboration Workshop",
            startDate: Date(timeIntervalSince1970: .random(in: 0...(.greatestFiniteMagnitude))),
            endDate: Date(timeIntervalSince1970: .random(in: 0...(.greatestFiniteMagnitude))),
            calendar: .init(name: "My Calendar", iconColor: "#FFEEEE"),
            location: .init(name: "Zoom call"),
            participants: [
                .init(email: "boss@example.com", isOrganizer: true, status: .attending),
                .init(email: "participant.1@proton.me", isOrganizer: false, status: .attending),
                .init(email: "participant.2@proton.me", isOrganizer: false, status: .attending),
                .init(email: "participant.3@proton.me", isOrganizer: false, status: .attending)
            ], 
            calendarAppDeepLink: URL(string: "ProtonCalendar://events/foo")!
        )
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
        let eventDetails = try await sut.fetchEventDetails(basicEventInfo: stubbedBasicEventInfo)
        XCTAssertEqual(eventDetails, expectedEventDetails)
    }

    func testWhenEventIsEncryptedWithAddressKeys_decryptsSuccessfully() async throws {
        try prepareAddressKeyPacketVariant()
        let eventDetails = try await sut.fetchEventDetails(basicEventInfo: stubbedBasicEventInfo)
        XCTAssertEqual(eventDetails, expectedEventDetails)
    }
}

extension EventRSVPTests {
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
                .init(flags: .active, passphraseID: passphraseID, privateKey: calendarKeyPair.privateKey)
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

        let sharedEvents: [EventElement] = try [summaryEvent, locationEvent].map { icsString in
            try makeEncryptedEvent(icsString: icsString, cryptoSessionKey: cryptoSessionKey)
        }

        let attendeesEvents: [EventElement] = try [organizerEvent, attendeeEvent].map { icsString in
            try makeEncryptedEvent(icsString: icsString, cryptoSessionKey: cryptoSessionKey)
        }

        let keyPacket = try Encryptor.encryptSession(publicKey: .init(value: publicKey), sessionKey: sessionKey).value

        return FullEventTransformer(
            addressID: nil,
            addressKeyPacket: setAddressKeyPacketInsteadOfSharedOne ? keyPacket : nil,
            attendees: [],
            attendeesEvents: attendeesEvents,
            calendarID: UUID().uuidString,
            startTime: expectedEventDetails.startDate.timeIntervalSince1970,
            endTime: expectedEventDetails.endDate.timeIntervalSince1970,
            fullDay: 0,
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
        apiService.requestDecodableStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, completion in
            switch path {
            case "/calendar/v1/events":
                let response: CalendarEventsResponse = .init(events: [event])
                completion(nil, .success(response))
            case "/calendar/v1/\(event.calendarID)/bootstrap":
                completion(nil, .success(bootstrap))
            default:
                XCTFail("Unexpected path")
                completion(nil, .failure(.badParameter(path)))
            }
        }
    }
}

