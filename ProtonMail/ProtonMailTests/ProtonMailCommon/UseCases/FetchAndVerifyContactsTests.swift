// Copyright (c) 2022 Proton AG
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
import ProtonCore_DataModel
import ProtonCore_TestingToolkit
import XCTest

@testable import ProtonMail

final class FetchAndVerifyContactsTests: XCTestCase {
    var sut: FetchAndVerifyContacts!
    private var mockApiService: APIServiceMock!
    private var mockApiServiceShouldReturnError: Bool!
    private var mockContactProvider: MockContactProvider!
    private var mockContext: NSManagedObjectContext!

    private static let mockValidCardData = CardData(
        t: .SignedOnly,
        d: ContactParserTestData.signedOnlyData,
        s: ContactParserTestData.signedOnlySignature
    )
    private let mockInvalidCardData = CardData(
        t: .SignedOnly,
        d: ContactParserTestData.signedOnlyData,
        s: "invalid signature"
    )
    private let emailUsedInSignedCardData = ContactParserTestData.emailUsedInSignedData

    override func setUp() {
        super.setUp()

        let coreDataContextProvider = MockCoreDataContextProvider()
        mockContactProvider = MockContactProvider(coreDataContextProvider: coreDataContextProvider)
        mockApiService = makeMockApiService()
        mockApiServiceShouldReturnError = false
        mockContext = coreDataContextProvider.rootSavingContext
        sut = makeSUT()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockApiService = nil
        mockContactProvider = nil
        mockContext = nil
    }

    func testExecute_whenNoEmailsPassed_returnsEmptyArray() async {
        let emptyEmails = [String]()
        let result = await withCheckedContinuation { continuation in
            self.sut.execute(emailAddresses: emptyEmails, callback: continuation.resume(returning:))
        }
        XCTAssertTrue(result.isEmpty)
    }

    func testExecute_whenEmailExistsInContactsAndHasSendPreferences_returnsThePreContact() async {
        let dummyEmails = [emailUsedInSignedCardData]
        sutUpdateMockContactProvider(with: dummyEmails, hasSendPreferences: true, isContactDownloaded: false)

        let result = await withCheckedContinuation { continuation in
            self.sut.execute(emailAddresses: dummyEmails, callback: continuation.resume(returning:))
        }
        let preContact = result.first
        XCTAssertTrue(preContact!.email == emailUsedInSignedCardData)
        XCTAssertTrue(mockApiService.requestStub.callCounter == 1)
    }

    func testExecute_whenEmailExistsInContactsButFetchContactFails_returnsThePreContact() async {
        let dummyEmails = [emailUsedInSignedCardData]
        sutUpdateMockContactProvider(with: dummyEmails, hasSendPreferences: true, isContactDownloaded: false)
        mockApiServiceShouldReturnError = true

        let result = await withCheckedContinuation { continuation in
            self.sut.execute(emailAddresses: dummyEmails, callback: continuation.resume(returning:))
        }
        let preContact = result.first
        XCTAssertTrue(preContact!.email == emailUsedInSignedCardData)
        XCTAssertTrue(mockApiService.requestStub.callCounter == 1)
    }

    func testExecute_whenEmailExistsInContactsAndCardDataHasInvalidSignature_returnsEmptyArray() async {
        let dummyEmails = [emailUsedInSignedCardData]
        sutUpdateMockContactProvider(
            with: dummyEmails,
            mockCardData: mockInvalidCardData,
            hasSendPreferences: true,
            isContactDownloaded: false
        )

        let result = await withCheckedContinuation { continuation in
            self.sut.execute(emailAddresses: dummyEmails, callback: continuation.resume(returning:))
        }
        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(mockApiService.requestStub.callCounter == 1)
    }

    func testExecute_whenEmailExistsInContactsAndHasNotSendPreferences_returnsThePreContact() async {
        let dummyEmails = [emailUsedInSignedCardData]
        sutUpdateMockContactProvider(with: dummyEmails, hasSendPreferences: false, isContactDownloaded: false)

        let result = await withCheckedContinuation { continuation in
            self.sut.execute(emailAddresses: dummyEmails, callback: continuation.resume(returning:))
        }
        let preContact = result.first
        XCTAssertTrue(preContact!.email == emailUsedInSignedCardData)
        XCTAssertTrue(mockApiService.requestStub.callCounter == 0)
    }

    func testExecute_whenEmailDoesNotExistInContacts_returnsEmptyArray() async {
        let dummyEmails = [emailUsedInSignedCardData]
        sutUpdateMockContactProvider(with: dummyEmails, existsInContacts: false)

        let result = await withCheckedContinuation { continuation in
            self.sut.execute(emailAddresses: dummyEmails, callback: continuation.resume(returning:))
        }
        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(mockApiService.requestStub.callCounter == 0)
    }
}

extension FetchAndVerifyContactsTests {

    private func makeSUT() -> FetchAndVerifyContacts {
        let params = FetchAndVerifyContacts.Parameters(
            currentUser: "",
            currentUserKeys: [Key(keyID: "", privateKey: ContactParserTestData.privateKey)]
        )
        let dependencies = FetchAndVerifyContacts.Dependencies(
            apiService: mockApiService,
            cacheService: makeMockCacheService(),
            contactProvider: mockContactProvider
        )
        return FetchAndVerifyContacts(params: params, dependencies: dependencies)
    }

    private func makeMockApiService() -> APIServiceMock {
        let mockApiService = APIServiceMock()
        mockApiService.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains("/contacts") {
                if self.mockApiServiceShouldReturnError {
                    completion?(nil, nil, NSError(domain: "", code: -10))
                } else {
                    completion?(nil, ContactResponseTestData.jsonResponse(), nil)
                }
            } else {
                XCTFail("wrong request")
            }
        }
        return mockApiService
    }

    private func makeMockCacheService() -> MockCacheService {
        let mockCacheService = MockCacheService()
        mockCacheService.contactToReturn = Contact(context: mockContext)
        return mockCacheService
    }

    private func sutUpdateMockContactProvider(
        with emails: [String],
        existsInContacts: Bool = true,
        mockCardData: CardData = mockValidCardData,
        hasSendPreferences: Bool = true,
        isContactDownloaded: Bool = false
    ) {
        mockContactProvider.allEmailsToReturn = makeMockEmails(
            emails,
            hasSendPreferences: existsInContacts && hasSendPreferences,
            isContactDownloaded: existsInContacts && isContactDownloaded
        )
        if existsInContacts {
            mockContactProvider.allContactsToReturn = makeMockContacts(
                with: mockContactProvider.allEmailsToReturn,
                mockCardData: mockCardData
            )
        }
    }

    private func makeMockEmails(_ emails: [String], hasSendPreferences: Bool, isContactDownloaded: Bool) -> [Email] {
        mockContext.performAndWait {
            emails.map { email in
                let newEmail = Email(context: mockContext)
                newEmail.email = email
                newEmail.contactID = String.randomString(10)
                newEmail.defaults = hasSendPreferences ? 0 : 1
                newEmail.contact.isDownloaded = isContactDownloaded
                return newEmail
            }
        }
    }

    private func makeMockContacts(with emails: [Email], mockCardData: CardData) -> [ContactEntity] {
        mockContext.performAndWait {
            emails.map { email in
                let newContact = Contact(context: mockContext)
                newContact.contactID = email.contactID
                newContact.emails = [email]
                newContact.cardData = try! [mockCardData].toJSONString()
                return newContact
            }
            .map(ContactEntity.init)
        }
    }
}
