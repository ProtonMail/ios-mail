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

import CoreData
import ProtonCoreDataModel
import ProtonCoreCrypto
import ProtonCoreTestingToolkit
@testable import ProtonMail
import XCTest

final class ImportDeviceContactsTests: XCTestCase {
    private var sut: ImportDeviceContacts!
    private var sutDelegate: SUTDelegate!
    private var sutParams: ImportDeviceContacts.Params!

    private var mockUser: UserManager!
    private var userContainer: UserContainer!
    private var testContainer: TestContainer!
    private var mockDeviceContacts: MockDeviceContactsProvider!
    private var mockQueueManager: QueueManager!
    private var mockMiscPersistentQueue: PMPersistentQueue!

    private let dummyUserID = UserID(rawValue: "dummy_user_id")
    private let dummyHistoryToken: Data = Data("dummy_history_token".utf8)
    private let expectationTimeout = 3.0

    override func setUp() {
        super.setUp()
        mockDeviceContacts = .init()
        let messageQueue = PMPersistentQueue(queueName: String.randomString(6))
        mockMiscPersistentQueue = PMPersistentQueue(queueName: String.randomString(6))
        mockQueueManager = QueueManager(messageQueue: messageQueue, miscQueue: mockMiscPersistentQueue)

        let userInfo = UserInfo()
        userInfo.userId = dummyUserID.rawValue
        mockUser = .init(api: APIServiceMock(), userInfo: userInfo, globalContainer: testContainer)

        testContainer = .init()
        testContainer.deviceContactsFactory.register { self.mockDeviceContacts }
        testContainer.queueManagerFactory.register { self.mockQueueManager }
        userContainer = UserContainer(userManager: mockUser, globalContainer: testContainer)

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
        mockQueueManager = nil
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

    func testExecute_whenNoHistoryToken_itImportsAllContacts() throws {
        // when no history token and all device contacts are new contacts
        testContainer.userDefaults[.contactsHistoryTokenPerUser] = [:]
        prepareDeviceContacts(dummyIdentifiers_toCreateAndUpdate)

        sut.execute(params: sutParams)
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)

        let storedContacts = try readStoredContacts()
        let storedEmails = try readStoredEmails()
        XCTAssertEqual(storedContacts.count, 3)
        XCTAssertEqual(storedEmails.count, 4)
        XCTAssertEqual(Set(storedEmails.map(\.email)), Set(dummyIdentifiers_toCreateAndUpdate.flatMap(\.emails)))
    }

    func testExecute_whenImportsContacts_normalisesTheirUuid() throws {
        // when no history token and all device contacts are new contacts
        testContainer.userDefaults[.contactsHistoryTokenPerUser] = [:]
        prepareDeviceContacts(dummyIdentifiers_toCreateAndUpdate)

        sut.execute(params: sutParams)
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)

        let expectedUuidPrefix = "protonmail-ios-autoimport-"
        let storedContacts = try readStoredContacts()
        XCTAssertEqual(storedContacts.count, 3)
        for contact in storedContacts {
            let contactPrefix = String(contact.uuid.prefix(expectedUuidPrefix.count))
            XCTAssertEqual(contactPrefix, expectedUuidPrefix)
        }
    }

    func testExecute_whenHistoryToken_andUuidMatch_itImportsModifiedContacts() throws {
        // when history token and all device contacts are to update an existing one matching by uuid
        testContainer.userDefaults[.contactsHistoryTokenPerUser] = [dummyUserID.rawValue: Data("someToken".utf8)]
        prepareContactInCoreData(dummyContactExistingInCoreData)
        prepareDeviceContacts(dummyIdentifiers_toUpdateExistingContacts_uuidMatch)

        sut.execute(params: sutParams)
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)

        // TODO:
        // ImportDeviceContacts reuses the current updateContact action which will store the changes
        // after the endpoint request. Therefore this can't be tested checking CoreData yet.

//        let storedContacts = try readStoredContacts()
//        let storedEmails = try readStoredEmails()
//        XCTAssertEqual(storedContacts.count, 1)
//        XCTAssertEqual(storedEmails.count, 2)
//        XCTAssertEqual(Set(storedEmails.map(\.email)), Set(["kathy@pm.me", "kate-bell@mac.com"]))

        // Temporarily we check the queue
        XCTAssertEqual(mockMiscPersistentQueue.count, 1)
    }

    func testExecute_whenHistoryToken_andEmailMatch_itImportsModifiedContacts() throws {
        // when history token and all device contacts are to update an existing one matching by email
        testContainer.userDefaults[.contactsHistoryTokenPerUser] = [dummyUserID.rawValue: Data("someToken".utf8)]
        prepareContactInCoreData(dummyContactExistingInCoreData)
        prepareDeviceContacts(dummyIdentifiers_toUpdateExistingContacts_emailMatch)

        sut.execute(params: sutParams)
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)

        // TODO:
        // ImportDeviceContacts reuses the current updateContact action which will store the changes
        // after the endpoint request. Therefore this can't be tested checking CoreData yet.

//        let storedContacts = try readStoredContacts()
//        let storedEmails = try readStoredEmails()
//        XCTAssertEqual(storedContacts.count, 1)
//        XCTAssertEqual(storedEmails.count, 2)
//        XCTAssertEqual(Set(storedEmails.map(\.email)), Set(["kathy@pm.me", "kate-bell@mac.com"]))

        // Temporarily we check the queue
        XCTAssertEqual(mockMiscPersistentQueue.count, 1)
    }

    func testExecute_whenThereAreNoContactsToImport_itFinishesTheUseCase() {
        testContainer.userDefaults[.contactsHistoryTokenPerUser] = [dummyUserID.rawValue: Data("someToken".utf8)]
        mockDeviceContacts.fetchEventsContactIdentifiersStub.bodyIs { _, token in
            (self.dummyHistoryToken, [])
        }

        sut.execute(params: sutParams)
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)
    }

    func testCancel_whenThereAreOnlyContactsToBeCreated_itFinishesWithoutImporting() throws {
        testContainer.userDefaults[.contactsHistoryTokenPerUser] = [:]
        prepareDeviceContacts(dummyIdentifiers_toCreateAndUpdate)

        sut.execute(params: sutParams)
        sut.cancel()
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)

        let savedContacts = try readStoredContacts()
        let savedEmails = try readStoredEmails()
        XCTAssertEqual(savedContacts.count, 0)
        XCTAssertEqual(savedEmails.count, 0)
    }

    func testCancel_whenThereAreOnlyContactsToBeUpdated_itFinishesWithoutImporting() throws {
        testContainer.userDefaults[.contactsHistoryTokenPerUser] = [dummyUserID.rawValue: Data("someToken".utf8)]
        prepareContactInCoreData(dummyContactExistingInCoreData)
        prepareDeviceContacts(dummyIdentifiers_toUpdateExistingContacts_uuidMatch)

        sut.execute(params: sutParams)
        sut.cancel()
        wait(for: [sutDelegate.finishExpectation], timeout: expectationTimeout)

        // TODO:
        // For the same reason explained above, temporarily we use the queue

//        let storedEmails = try readStoredEmails()
//        XCTAssertEqual(storedEmails.count, 1)

        XCTAssertEqual(mockMiscPersistentQueue.count, 0)
    }
}

// MARK: helper functions

extension ImportDeviceContactsTests {

    private func prepareContactInCoreData(_ : (uuid: String, email: String)) {
        try! testContainer.contextProvider.write { context in
            let contact = Contact(context: context)
            contact.contactID = UUID().uuidString
            contact.userID = self.dummyUserID.rawValue
            contact.uuid = self.dummyContactExistingInCoreData.uuid
            contact.cardData = SyncContactTestUtils.contactCardData

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

    private func readStoredEmails() throws -> [Email] {
        try testContainer.contextProvider.read { context in
            let fetchEmails = NSFetchRequest<Email>(entityName: Email.entityName)
            return try context.fetch(fetchEmails)
        }
    }

    private func readStoredContacts() throws -> [Contact] {
        try testContainer.contextProvider.read { context in
            let savedContacts = NSFetchRequest<Contact>(entityName: Contact.entityName)
            return try context.fetch(savedContacts)
        }
    }
}

// MARK: test data

extension ImportDeviceContactsTests {

    private var dummyContactExistingInCoreData: (uuid: String, email: String) {
        (uuid: "uuid-1", email: "kate-bell@mac.com")
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
