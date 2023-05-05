// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import CoreData
import ProtonCore_DataModel
import ProtonCore_TestingToolkit
@testable import ProtonMail
import XCTest

final class ComposeViewModelTests: XCTestCase {
    private var mockCoreDataService: MockCoreDataContextProvider!
    private var apiMock: APIServiceMock!
    private var message: Message!
    private var testContext: NSManagedObjectContext!
    private var fakeUserManager: UserManager!
    private var sut: ComposeViewModel!
    private var contactProvider: MockContactProvider!

    override func setUp() {
        super.setUp()

        self.mockCoreDataService = MockCoreDataContextProvider()
        self.apiMock = APIServiceMock()

        testContext = MockCoreDataStore.testPersistentContainer.viewContext
        fakeUserManager = mockUserManager()
        contactProvider = .init(coreDataContextProvider: mockCoreDataService)

        let copyMessage = MockCopyMessageUseCase()

        copyMessage.executeStub.bodyIs { [unowned self] _, _ in
            (message, nil)
        }

        let helperDependencies = ComposerMessageHelper.Dependencies(
            messageDataService: fakeUserManager.messageService,
            cacheService: fakeUserManager.cacheService,
            contextProvider: mockCoreDataService,
            copyMessage: copyMessage
        )

        let dependencies = ComposeViewModel.Dependencies(
            fetchAndVerifyContacts: .init(),
            internetStatusProvider: .init(),
            fetchAttachment: .init(),
            contactProvider: contactProvider,
            helperDependencies: helperDependencies
        )

        self.message = testContext.performAndWait {
            Message(context: testContext)
        }

        sut = ComposeViewModel(
            msg: message,
            action: .openDraft,
            msgService: fakeUserManager.messageService,
            user: fakeUserManager,
            coreDataContextProvider: mockCoreDataService,
            internetStatusProvider: .init(),
            dependencies: dependencies
        )
    }

    override func tearDown() {
        self.sut = nil
        self.mockCoreDataService = nil
        self.apiMock = nil
        self.message = nil
        self.testContext = nil

        super.tearDown()
    }

    func testGetAttachment() {
        let attachment1 = Attachment(context: testContext)
        attachment1.order = 0
        attachment1.message = message
        let attachment2 = Attachment(context: testContext)
        attachment2.order = 1
        attachment2.message = message
        let attachmentSoftDeleted = Attachment(context: testContext)
        attachmentSoftDeleted.order = 3
        attachmentSoftDeleted.isSoftDeleted = true
        attachmentSoftDeleted.message = message

        let result = sut.getAttachments()
        // TODO: fix this test and uncomment this line, or replace the test, it's not meaningful
        // XCTAssertNotEqual(result, [])
        for index in result.indices {
            XCTAssertEqual(result[index].order, index)
        }
    }

// MARK: isEmptyDraft tests

// The body decryption part and numAttachment are missing, seems no way to test

    func testIsEmptyDraft_messageInit() throws {
        sut.initialize(message: message, action: .openDraft)
        XCTAssertTrue(sut.isEmptyDraft())
    }

    func testIsEmptyDraft_subjectField() throws {
        message.title = "abc"
        sut.initialize(message: message, action: .openDraft)
        XCTAssertFalse(sut.isEmptyDraft())
    }

    func testIsEmptyDraft_recipientField() throws {
        message.toList = "[]"
        message.ccList = "[]"
        message.bccList = "[]"
        sut.initialize(message: message, action: .openDraft)
        XCTAssertTrue(sut.isEmptyDraft())

        message.toList = "eee"
        message.ccList = "abc"
        message.bccList = "fsx"
        sut.initialize(message: message, action: .openDraft)
        XCTAssertFalse(sut.isEmptyDraft())
    }

    func testDecodingRecipients_prefersMatchingLocalContactName() throws {
        let email = CoreDataService.shared.read { context in
            let email = Email(context: context)
            let contact = Contact(context: context)
            contact.name = "My friend I don't like"
            email.contact = contact
            return EmailEntity(email: email)
        }

        contactProvider.getEmailsByAddressStub.bodyIs { _, _, _ in
            [email]
        }

        let backendResponse = "[{\"Address\": \"friend@example.com\", \"Name\": \"My friend\", \"Group\": \"\"}]"

        let contacts = sut.toContacts(backendResponse)
        let contact = try XCTUnwrap(contacts.first)
        XCTAssertEqual(contact.displayName, "My friend I don't like")
    }

    func testDecodingRecipients_usesBackendName_ifNoLocalContact() throws {
        let backendResponse = "[{\"Address\": \"friend@example.com\", \"Name\": \"My friend\", \"Group\": \"\"}]"

        let contacts = sut.toContacts(backendResponse)
        let contact = try XCTUnwrap(contacts.first)
        XCTAssertEqual(contact.displayName, "My friend")
    }

    func testDecodingRecipients_usesEmailAsDisplayName_ifNothingElseIsFound() throws {
        let backendResponsesWithoutProperName: [String] = [
            "[{\"Address\": \"friend@example.com\", \"Name\": \" \", \"Group\": \"\"}]",
            "[{\"Address\": \"friend@example.com\", \"Name\": \"\", \"Group\": \"\"}]",
            "[{\"Address\": \"friend@example.com\", \"Group\": \"\"}]"
        ]

        for backendResponse in backendResponsesWithoutProperName {
            let contacts = sut.toContacts(backendResponse)
            let contact = try XCTUnwrap(contacts.first)
            XCTAssertEqual(contact.displayName, "friend@example.com")
        }
    }
}

extension ComposeViewModelTests {
    private func mockUserManager() -> UserManager {
        let userInfo = UserInfo.getDefault()
        userInfo.defaultSignature = "Hi"
        let key = Key(keyID: "keyID", privateKey: KeyTestData.privateKey1)
        let address = Address(addressID: UUID().uuidString,
                              domainID: "",
                              email: "",
                              send: .active,
                              receive: .active,
                              status: .enabled,
                              type: .protonDomain,
                              order: 0,
                              displayName: "the name",
                              signature: "Hello",
                              hasKeys: 1,
                              keys: [key])
        userInfo.set(addresses: [address])
        return UserManager(api: self.apiMock, role: .owner, userInfo: userInfo)
    }
}
