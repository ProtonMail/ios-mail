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

import ProtonCoreDataModel
import ProtonCoreCrypto
import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail
import XCTest

final class ImportDeviceContactsTests: XCTestCase {
    private var sut: ImportDeviceContacts!
    private var sutDelegate: SUTDelegate!
    private var sutParams: ImportDeviceContacts.Params!

    private var mockApiService: APIServiceMock!
    private var mockUser: UserManager!
    private var userContainer: UserContainer!
    private var testContainer: TestContainer!
    private var mockDeviceContacts: MockDeviceContactsProvider!
    private var mockContactsQueueSync: MockContactsSyncQueueProtocol!

    private let dummyUserID = UserID(rawValue: "dummy_user_id")
    private let dummyHistoryToken: Data = Data("dummy_history_token".utf8)
    private let expectationTimeout = 3.0

    private let autoImportUuidPrefix = "protonmail-ios-autoimport-"

    override func setUp() {
        super.setUp()
        mockDeviceContacts = .init()
        mockContactsQueueSync = MockContactsSyncQueueProtocol()

        let userInfo = UserInfo()
        userInfo.userId = dummyUserID.rawValue
        mockApiService = APIServiceMock()
        mockUser = .init(api: mockApiService, userInfo: userInfo, globalContainer: testContainer)

        testContainer = .init()
        testContainer.deviceContactsFactory.register { self.mockDeviceContacts }
        userContainer = UserContainer(userManager: mockUser, globalContainer: testContainer)
        userContainer.contactSyncQueueFactory.register { self.mockContactsQueueSync }

        sut = .init(userID: dummyUserID, dependencies: userContainer)
        sutDelegate = .init(expectation: expectation(description: "delegate onFinish is called"))
        sut.delegate = sutDelegate

        sutParams = .init(
            userKeys: [Key(keyID: "1", privateKey: SyncContactTestUtils.privateKey)],
            mailboxPassphrase: SyncContactTestUtils.passphrase
        )
    }

    override func tearDown() {
        super.tearDown()
        mockDeviceContacts = nil
        mockContactsQueueSync = nil
        mockApiService = nil
        mockUser = nil
        testContainer = nil
        userContainer = nil
        sutParams = nil
        sutDelegate = nil
        sut = nil
    }

    func testExecute_whenNoHistoryToken_itStoresTheNewToken() throws {
        testContainer.userDefaults[.contactsHistoryTokenPerUser] = [:]
        prepareDeviceContacts(dummyIdentifiers_toCreateAndUpdate)

        sut.execute(params: sutParams)
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)

        let historyTokens = testContainer.userDefaults[.contactsHistoryTokenPerUser]
        XCTAssertEqual(historyTokens[dummyUserID.rawValue], dummyHistoryToken)
    }

    func testExecute_whenNoHistoryToken_itEnqueuesAllContacts() throws {
        // when no history token and all device contacts are new contacts
        testContainer.userDefaults[.contactsHistoryTokenPerUser] = [:]
        prepareDeviceContacts(dummyIdentifiers_toCreateAndUpdate)

        sut.execute(params: sutParams)
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)

        let taskEnqueued = mockContactsQueueSync.addTaskStub.lastArguments?.a1
        XCTAssertEqual(taskEnqueued?.numContacts, 3)
        XCTAssertEqual(taskEnqueued?.action, .create)
    }

    func testExecute_whenImportsContacts_normalisesTheirUuid() throws {
        // when no history token and all device contacts are new contacts
        testContainer.userDefaults[.contactsHistoryTokenPerUser] = [:]
        prepareDeviceContacts(dummyIdentifiers_toCreateAndUpdate)

        sut.execute(params: sutParams)
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)

        let taskEnqueued = mockContactsQueueSync.addTaskStub.lastArguments?.a1
        XCTAssertEqual(taskEnqueued?.numContacts, 3)
        XCTAssertEqual(taskEnqueued?.action, .create)

        for contactVCards in taskEnqueued!.contactsVCards {
            for card in contactVCards {
                if case .SignedOnly = card.type {
                    XCTAssertTrue(card.data.contains("UID:\(autoImportUuidPrefix)"))
                }
            }
        }
    }

    func testExecute_whenHistoryToken_andUuidMatch_itEnqueuesModifiedContacts() throws {
        // when history token and all device contacts are to update an existing one matching by uuid
        testContainer.userDefaults[.contactsHistoryTokenPerUser] = [dummyUserID.rawValue: Data("someToken".utf8)]
        prepareContactInCoreData(dummyContactExistingInCoreData)
        prepareDeviceContacts(dummyIdentifiers_toUpdateExistingContacts_uuidMatch)

        sut.execute(params: sutParams)
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)

        let taskEnqueued = mockContactsQueueSync.addTaskStub.lastArguments?.a1
        XCTAssertEqual(taskEnqueued?.numContacts, 1)
        XCTAssertEqual(taskEnqueued?.action, .update)
    }

    func testExecute_whenHistoryToken_andEmailMatch_itEnqueuesModifiedContacts() throws {
        // when history token and all device contacts are to update an existing one matching by email
        testContainer.userDefaults[.contactsHistoryTokenPerUser] = [dummyUserID.rawValue: Data("someToken".utf8)]
        prepareContactInCoreData(dummyContactExistingInCoreData)
        prepareDeviceContacts(dummyIdentifiers_toUpdateExistingContacts_emailMatch)

        sut.execute(params: sutParams)
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)

        let taskEnqueued = mockContactsQueueSync.addTaskStub.lastArguments?.a1
        XCTAssertEqual(taskEnqueued?.numContacts, 1)
        XCTAssertEqual(taskEnqueued?.action, .update)
    }

    func testExecute_whenThereAreNoContactsToImport_itFinishesTheUseCase() {
        testContainer.userDefaults[.contactsHistoryTokenPerUser] = [dummyUserID.rawValue: Data("someToken".utf8)]
        mockDeviceContacts.fetchEventsContactIdentifiersStub.bodyIs { _, token in
            (self.dummyHistoryToken, [])
        }

        sut.execute(params: sutParams)
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)
    }

    // MARK: tests for the operation queue state

    func testExecute_itSetsUpTheQueue() throws {
        prepareDeviceContacts([])

        sut.execute(params: sutParams)
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)

        XCTAssertEqual(mockContactsQueueSync.setupStub.callCounter, 1)
    }

    func testExecute_whenChangesToImport_itStartsTheQueue() throws {
        testContainer.userDefaults[.contactsHistoryTokenPerUser] = [:]
        prepareDeviceContacts(dummyIdentifiers_toCreateAndUpdate)

        sut.execute(params: sutParams)
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)

        let taskEnqueued = mockContactsQueueSync.addTaskStub.lastArguments?.a1
        XCTAssertEqual(taskEnqueued?.numContacts, 3)
        XCTAssertEqual(taskEnqueued?.action, .create)

        XCTAssertEqual(mockContactsQueueSync.startStub.callCounter, 1)
    }

    func testExecute_whenNoChangesToImport_itStartsTheQueueForPotentialPreviouslyPersistedOperations() throws {
        prepareDeviceContacts([])

        sut.execute(params: sutParams)
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)

        XCTAssertEqual(mockContactsQueueSync.addTaskStub.callCounter, 0)
        XCTAssertEqual(mockContactsQueueSync.startStub.callCounter, 1)
    }

    func testExecute_whenChangesToImport_itSavesTheQueue() throws {
        testContainer.userDefaults[.contactsHistoryTokenPerUser] = [:]
        prepareDeviceContacts(dummyIdentifiers_toCreateAndUpdate)

        sut.execute(params: sutParams)
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)

        let taskEnqueued = mockContactsQueueSync.addTaskStub.lastArguments?.a1
        XCTAssertEqual(taskEnqueued?.numContacts, 3)
        XCTAssertEqual(taskEnqueued?.action, .create)

        XCTAssertTrue(mockContactsQueueSync.saveQueueToDiskStub.wasCalled)
    }

    // MARK: tests for downloading contact details

    func testExecute_whenNoHistoryToken_andMissingVCard_itDoesNotDownloadContactDetails() throws {
        prepareDownloadContactDetailConditions(existingVCard: Bool.random())

        sut.execute(params: sutParams)
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)

        XCTAssertEqual(mockApiService.requestJSONStub.callCounter, 0)
    }

    func testExecute_whenHistoryToken_andUuidMatch_andMissingVCard_itDownloadsContactDetails() throws {
        testContainer.userDefaults[.contactsHistoryTokenPerUser] = [dummyUserID.rawValue: Data("someToken".utf8)]
        prepareDownloadContactDetailConditions(existingVCard: false)

        sut.execute(params: sutParams)
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)

        XCTAssertEqual(mockApiService.requestJSONStub.callCounter, 1)
    }

    func testExecute_whenHistoryToken_andUuidMatch_andExistingVCard_itDoesNotDownloadsContactDetails() throws {
        testContainer.userDefaults[.contactsHistoryTokenPerUser] = [dummyUserID.rawValue: Data("someToken".utf8)]
        prepareDownloadContactDetailConditions(existingVCard: true)

        sut.execute(params: sutParams)
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)

        XCTAssertEqual(mockApiService.requestJSONStub.callCounter, 0)
    }

    // MARK: tests for cancel

    func testCancel_whenThereAreOnlyContactsToBeCreated_itFinishesWithoutEnqueuingTasks() throws {
        testContainer.userDefaults[.contactsHistoryTokenPerUser] = [:]
        prepareDeviceContacts(dummyIdentifiers_toCreateAndUpdate)

        sut.execute(params: sutParams)
        sut.cancel()
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)

        XCTAssertEqual(mockContactsQueueSync.addTaskStub.callCounter, 0)
    }

    func testCancel_whenThereAreOnlyContactsToBeUpdated_itFinishesWithoutEnqueuingTasks() throws {
        testContainer.userDefaults[.contactsHistoryTokenPerUser] = [dummyUserID.rawValue: Data("someToken".utf8)]
        prepareContactInCoreData(dummyContactExistingInCoreData)
        prepareDeviceContacts(dummyIdentifiers_toUpdateExistingContacts_uuidMatch)

        sut.execute(params: sutParams)
        sut.cancel()
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)

        XCTAssertEqual(mockContactsQueueSync.addTaskStub.callCounter, 0)
    }
}

// MARK: helper functions

extension ImportDeviceContactsTests {

    private func prepareContactInCoreData(
        _ : (uuid: String, email: String),
        cardData: String = SyncContactTestUtils.contactCardData
    ) {
        try! testContainer.contextProvider.write { context in
            let contact = Contact(context: context)
            contact.contactID = UUID().uuidString
            contact.userID = self.dummyUserID.rawValue
            contact.uuid = self.dummyContactExistingInCoreData.uuid
            contact.cardData = cardData

            let mail = Email(context: context)
            mail.userID = self.dummyUserID.rawValue
            mail.contactID = contact.contactID
            mail.contact = contact
            mail.emailID = UUID().uuidString
            mail.email = self.dummyContactExistingInCoreData.email
        }
    }

    private func prepareDeviceContacts(_ deviceContactIdentifiers: [DeviceContactIdentifier]) {
        mockDeviceContacts.fetchAllContactIdentifiersStub.bodyIs { _ in
            (self.dummyHistoryToken, deviceContactIdentifiers)
        }
        mockDeviceContacts.fetchContactBatchStub.bodyIs { _, param in
            deviceContactIdentifiers.map { identifier in
                DeviceContact(identifier: identifier, fullName: "", vCard: self.dummyDeviceContactVCards[identifier.uuidInDevice]!)
            }
        }
        mockDeviceContacts.fetchEventsContactIdentifiersStub.bodyIs { _, token in
            (self.dummyHistoryToken, deviceContactIdentifiers)
        }
    }

    private func prepareDownloadContactDetailConditions(existingVCard: Bool) {
        if existingVCard {
            prepareContactInCoreData(dummyContactExistingInCoreData)
        } else {
            prepareContactInCoreData(dummyContactExistingInCoreData, cardData: "")
        }
        prepareDeviceContacts(dummyIdentifiers_toUpdateExistingContacts_uuidMatch)
        mockApiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, _, completion in
            if path.contains("/contacts/v4/contacts/") {
                completion(nil, .success([:]))
            } else {
                XCTFail("Unexpected path")
            }
        }
    }
}

// MARK: test data

extension ImportDeviceContactsTests {

    private var dummyContactExistingInCoreData: (uuid: String, email: String) {
        (uuid: "\(autoImportUuidPrefix)uuid-1", email: "kate-bell@mac.com")
    }

    // returns identifiers that matches the UUID of `dummyContactStoredInCoreData`
    private var dummyIdentifiers_toUpdateExistingContacts_uuidMatch: [DeviceContactIdentifier] {
        [DeviceContactIdentifier(uuidInDevice: "uuid-1", emails: ["kathy@pm.me"])]
    }

    // returns identifiers that matches an EMAIL of `dummyContactStoredInCoreData`
    private var dummyIdentifiers_toUpdateExistingContacts_emailMatch: [DeviceContactIdentifier] {
        [DeviceContactIdentifier(uuidInDevice: "uuid-no-match", emails: ["kathy@pm.me", "kate-bell@mac.com"])]
    }

    // returns identifiers that do not match stored contacts
    private var dummyIdentifiers_toCreateNewContacts: [DeviceContactIdentifier] {
        [
            DeviceContactIdentifier(uuidInDevice: "uuid-2", emails: ["d-higgins@mac.com", "higgs@pm.me"]),
            DeviceContactIdentifier(uuidInDevice: "uuid-3", emails: ["John-Appleseed@mac.com"])
        ]
    }

    private var dummyIdentifiers_toCreateAndUpdate: [DeviceContactIdentifier] {
        dummyIdentifiers_toUpdateExistingContacts_uuidMatch + dummyIdentifiers_toCreateNewContacts
    }

    private var dummyDeviceContactVCards: [String: String] {
        [
            "uuid-no-match": """
                      BEGIN:VCARD
                      VERSION:3.0
                      PRODID:-//Apple Inc.//iPhone OS 17.0//EN
                      N:Bell;Kate;;;
                      FN:Kate Bell
                      ORG:Creative Consulting;
                      TITLE:Producer
                      EMAIL;type=INTERNET;type=WORK;type=pref:kathy@pm.me
                      TEL;type=MAIN;type=pref:(415) 555-3695
                      TEL;type=CELL;type=VOICE:(555) 564-8583
                      item1.ADR;type=WORK;type=pref:;;165 Davis Street;Hillsborough;CA;94010;
                      item1.X-ABADR:us
                      item2.URL;type=pref:www.icloud.com
                      item2.X-ABLabel:_$!<HomePage>!$_
                      BDAY:1978-01-20
                      END:VCARD
                      """,
            "uuid-1": """
                      BEGIN:VCARD
                      VERSION:3.0
                      PRODID:-//Apple Inc.//iPhone OS 17.0//EN
                      N:Bell;Kate;;;
                      FN:Kate Bell
                      ORG:Creative Consulting;
                      TITLE:Producer
                      EMAIL;type=INTERNET;type=WORK;type=pref:kathy@pm.me
                      TEL;type=MAIN;type=pref:(415) 555-3695
                      TEL;type=CELL;type=VOICE:(555) 564-8583
                      item1.ADR;type=WORK;type=pref:;;165 Davis Street;Hillsborough;CA;94010;
                      item1.X-ABADR:us
                      item2.URL;type=pref:www.icloud.com
                      item2.X-ABLabel:_$!<HomePage>!$_
                      BDAY:1978-01-20
                      END:VCARD
                      """,
            "uuid-2": """
                      BEGIN:VCARD
                      VERSION:3.0
                      PRODID:-//Apple Inc.//iPhone OS 17.0//EN
                      N:Higgins;Daniel;;;Jr.
                      FN:Daniel Higgins Jr.
                      EMAIL;type=INTERNET;type=HOME;type=pref:d-higgins@mac.com
                      EMAIL;type=INTERNET;type=WORK;type=pref:higgs@pm.me
                      TEL;type=HOME;type=FAX;type=pref:(408) 555-3514
                      TEL;type=HOME;type=VOICE:555-478-7672
                      TEL;type=CELL;type=VOICE:(408) 555-5270
                      item1.ADR;type=HOME;type=pref:;;332 Laguna Street;Corte Madera;CA;94925;USA
                      item1.X-ABADR:us
                      NOTE:Sister: Emily
                      END:VCARD
                      """,
            "uuid-3": """
                      BEGIN:VCARD
                      VERSION:3.0
                      PRODID:-//Apple Inc.//iPhone OS 17.0//EN
                      N:Appleseed;John;;;
                      FN:John Appleseed
                      EMAIL;type=INTERNET;type=WORK;type=pref:John-Appleseed@mac.com
                      TEL;type=HOME;type=VOICE;type=pref:888-555-1212
                      TEL;type=CELL;type=VOICE:888-555-5512
                      item1.ADR;type=HOME;type=pref:;;1234 Laurel Street;Atlanta;GA;30303;USA
                      item1.X-ABADR:us
                      item2.ADR;type=WORK:;;3494 Kuhl Avenue;Atlanta;GA;30303;USA
                      item2.X-ABADR:us
                      NOTE:College roommate
                      BDAY:1980-06-22
                      END:VCARD
                      """
        ]
    }
}

private final class SUTDelegate: ImportDeviceContactsDelegate {
    let finishExpectation: XCTestExpectation
    init(expectation: XCTestExpectation) {
        self.finishExpectation = expectation
    }

    func onProgressUpdate(count: Int, total: Int) {}

    func onFinish() {
        finishExpectation.fulfill()
    }
}

private extension ProtonMail.ContactTask {

    var contactsVCards: [[CardData]] {
        switch self.command {
        case let .create(contactObjects):
            return contactObjects.map(\.vCards)
        case let .update(_, vCards):
            return [vCards]
        }
    }
}
