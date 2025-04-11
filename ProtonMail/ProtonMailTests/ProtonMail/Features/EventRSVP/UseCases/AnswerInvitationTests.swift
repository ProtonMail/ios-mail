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

import ProtonCoreDataModel
import ProtonCoreTestingToolkitUnitTestsServices
import ProtonInboxICal
import ProtonInboxRSVP
import XCTest

@testable import ProtonMail

final class AnswerInvitationTests: XCTestCase {
    private var sut: AnswerInvitationWrapper!
    private var user: UserManager!

    private var apiEventID, calendarID: String!

    override func setUpWithError() throws {
        try super.setUpWithError()

        apiEventID = UUID().uuidString
        calendarID = UUID().uuidString

        let testContainer = TestContainer()
        let apiService = APIServiceMock()
        let fetchAndVerifyContacts = MockFetchAndVerifyContactsUseCase()

        user = try .prepareUser(apiMock: apiService, globalContainer: testContainer)

        user.container.reset()
        user.container.fetchAndVerifyContactsFactory.register {
            fetchAndVerifyContacts
        }

        sut = .init(dependencies: user.container)

        apiService.requestDecodableStub.bodyIs { [unowned self] _, method, path, _, _, _, _, _, _, _, _, completion in
            switch (method, path) {
            case
                (.put, "/calendar/v1/\(calendarID!)/events/\(apiEventID!)/attendees/"),
                (.put, "/calendar/v1/\(calendarID!)/events/\(apiEventID!)/personal"),
                (.put, "/calendar/v1/\(calendarID!)/events/\(apiEventID!)/upgrade"):
                let response = OptionalErrorResponse(code: 1000, error: nil)
                completion(nil, .success(response))
            default:
                fatalError("Unexpected request: \(method) \(path)")
            }
        }

        apiService.requestJSONStub.bodyIs { _, method, path, _, _, _, _, _, _, _, _, _, completion in
            switch (method, path) {
            case (.get, "/keys"):
                let response = PublicKeysResponseTestData.successTestResponse(
                    flags: Key.Flags.notObsolete.rawValue,
                    publicKey: OpenPGPDefines.publicKey.replacingOccurrences(of: "\n", with: "\\n")
                )

                completion(nil, .success(response))
            case (.post, "/mail/v4/messages/send/direct"):
                completion(nil, .success([:]))
            default:
                fatalError("Unexpected request: \(method) \(path)")
            }
        }

        fetchAndVerifyContacts.executionBlockStub.bodyIs { _, _, completion in
            let preContact = PreContact(
                email: "",
                pubKeys: [],
                sign: .signingFlagNotFound,
                encrypt: true,
                scheme: nil,
                mimeType: nil
            )
            completion(.success([preContact]))
        }
    }

    override func tearDownWithError() throws {
        sut = nil
        user = nil

        apiEventID = nil
        calendarID = nil

        try super.tearDownWithError()
    }

    func testExecutesWithoutFailure() async throws {
        let attendeeToken = UUID().uuidString
        let startDate = Date(timeIntervalSince1970: .random(in: 0...Date.distantFuture.timeIntervalSince1970))

        let attendeeTransformer = AttendeeTransformer(ID: "", status: .unanswered, token: attendeeToken)

        let calendarInfo = CalendarInfo(id: calendarID, isPersonal: true, areMemberAddressesDisabled: false)

        let eventIdentificationData = EventIdentificationData(
            id: apiEventID,
            calendarID: calendarID,
            startDate: startDate
        )

        let address = user.addresses[0].toAddress_v2
        let addressKey = address.keys[0]

        let addressKeyPacket = try CryptoUtils
            .randomSessionKeyAndKeyPacket(publicKey: addressKey.privateKey.publicKey)
            .1

        let timeZone = TimeZone.gmt

        let iCalEvent = ICalEvent(
            calendarId: calendarID,
            apiEventId: apiEventID,
            isProtonToProtonInvitation: true,
            rawNotications: nil,
            addressKeyPacket: addressKeyPacket,
            icsUID: "",
            createdTime: .now,
            startDate: startDate,
            startDateTimeZone: timeZone,
            startDateTimeZoneIdentifier: timeZone.identifier,
            endDate: .distantFuture,
            endDateTimeZoneIdentifier: timeZone.identifier,
            endDateTimeZone: timeZone,
            color: nil
        )

        let key = KeyTransformer(
            ID: "",
            calendarID: calendarID,
            flags: [.active, .primary],
            passphraseID: "",
            privateKey: addressKey.privateKey
        )

        let organizer = ICalAttendee(
            calendarId: calendarID,
            localEventId: "",
            user: .init(name: nil, email: ""),
            role: .required,
            status: .pending,
            token: nil,
            comment: nil
        )

        let attendee = ICalAttendee(
            calendarId: calendarID,
            localEventId: "",
            user: .init(name: nil, email: ""),
            role: .required,
            status: .pending,
            token: attendeeToken,
            comment: nil
        )

        let participant = Participant(attendee: attendee, address: address)

        let answeringContext = AnsweringContext(
            attendeeTransformers: [attendeeTransformer],
            calendarInfo: calendarInfo,
            event: eventIdentificationData,
            eventType: .nonRecurring,
            keyTransformers: [key],
            iCalEvent: iCalEvent,
            validated: .init(organizer: organizer, invitedParticipant: participant)
        )

        try await sut.execute(parameters: .init(answer: .yes, context: answeringContext))
    }
}
