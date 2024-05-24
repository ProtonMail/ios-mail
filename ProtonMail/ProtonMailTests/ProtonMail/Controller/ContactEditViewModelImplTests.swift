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
import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail
import VCard
import XCTest

final class ContactEditViewModelImplTests: XCTestCase {

    private var sut: ContactEditViewModel!
    private var fakeCoreDataService: CoreDataService!
    private var mockUser: UserManager!
    private var mockApi: APIServiceMock!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockApi = .init()
        mockUser = .init(api: mockApi)
        fakeCoreDataService = CoreDataService(
            container: MockCoreDataStore.testPersistentContainer
        )
        mockUser.userInfo.userKeys.append(
            .init(
                keyID: "1",
                privateKey: ContactParserTestData.privateKey.value
            )
        )
        mockUser.authCredential.mailboxpassword = ContactParserTestData.passphrase.value
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        fakeCoreDataService = nil
        mockUser = nil
        mockApi = nil
    }

    func testPrepareCardDatas_vCardHasNoNote_willNotCreateNewNoteField() throws {
        let vCardData = "BEGIN:VCARD\nVERSION:4.0\nN:lastName;firstName\nEND:VCARD"
        let cardData = try XCTUnwrap(try generateTestData(vcard: vCardData))
        sut = .init(
            contactEntity: .make(cardData: cardData),
            dependencies: .init(
                user: mockUser,
                contextProvider: fakeCoreDataService,
                contactService: mockUser.contactService
            )
        )

        wait(self.sut.structuredName != nil)

        let result = try sut.prepareCardDatas()

        XCTAssertFalse(result.isEmpty)

        let type3vCard = try XCTUnwrap(
            result.first(where: { $0.type == .SignAndEncrypt })
        )
        let decrypted = try type3vCard.data.decryptMessageWithSingleKeyNonOptional(
            ContactParserTestData.privateKey,
            passphrase: ContactParserTestData.passphrase
        )
        let vCard = try XCTUnwrap(PMNIEzvcard.parseFirst(decrypted))
        XCTAssertTrue(vCard.getNotes().isEmpty)
    }

    func testPrepareCardDatas_vCardHasMultipleNotes_willStillHaveSameAmountOfNotes() throws {
        let vCardData = "BEGIN:VCARD\nVERSION:4.0\nNOTE:The first note\nNOTE:The second note\nEND:VCARD"
        let cardData = try XCTUnwrap(try generateTestData(vcard: vCardData))
        sut = .init(
            contactEntity: .make(cardData: cardData),
            dependencies: .init(
                user: mockUser,
                contextProvider: fakeCoreDataService,
                contactService: mockUser.contactService
            )
        )
        wait(self.sut.notes.isEmpty == false)

        let result = try sut.prepareCardDatas()

        XCTAssertFalse(result.isEmpty)
        let type3vCard = try XCTUnwrap(
            result.first(where: { $0.type == .SignAndEncrypt })
        )
        let decrypted = try type3vCard.data.decryptMessageWithSingleKeyNonOptional(
            ContactParserTestData.privateKey,
            passphrase: ContactParserTestData.passphrase
        )
        let vCard = try XCTUnwrap(PMNIEzvcard.parseFirst(decrypted))
        XCTAssertEqual(vCard.getNotes().count, 2)
    }

    func testDisplayNameValidation_whenCreation_allNameFieldsOnlyHaveSpace_shouldThrowError() {
        sut = .init(
            contactEntity: nil,
            dependencies: .init(
                user: mockUser,
                contextProvider: fakeCoreDataService,
                contactService: mockUser.contactService
            )
        )
        sut.getProfile().newDisplayName = "    "
        sut.setFirstName("   ")
        sut.setLastName("      ")
        let ex = expectation(description: "done closure is called")
        sut.done { error in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, -372)
            ex.fulfill()
        }
        wait(for: [ex], timeout: 5)
    }
    
    func testDisplayNameValidation_whenCreation_displayNameHasValue_shouldKeepTheValue() {
        sut = .init(
            contactEntity: nil,
            dependencies: .init(
                user: mockUser,
                contextProvider: fakeCoreDataService,
                contactService: mockUser.contactService
            )
        )
        let displayName = String.randomString(7)
        sut.getProfile().newDisplayName = displayName
        sut.setFirstName(String.randomString(3))
        sut.setLastName(String.randomString(7))
        
        let ex = expectation(description: "done closure is called")
        sut.done { error in
            XCTAssertNil(error)
            XCTAssertEqual(self.sut.getProfile().newDisplayName, displayName)
            ex.fulfill()
        }
        wait(for: [ex], timeout: 5)
    }
    
    func testDisplayNameValidation_whenCreation_displayNameIsEmpty_firstNameHasValue_shouldUseFirstName() {
        sut = .init(
            contactEntity: nil,
            dependencies: .init(
                user: mockUser,
                contextProvider: fakeCoreDataService,
                contactService: mockUser.contactService
            )
        )
        let firstName = String.randomString(7)
        sut.getProfile().newDisplayName = ""
        sut.setFirstName(firstName)
        sut.setLastName("")
        
        let ex = expectation(description: "done closure is called")
        sut.done { error in
            XCTAssertNil(error)
            XCTAssertEqual(self.sut.getProfile().newDisplayName, firstName)
            ex.fulfill()
        }
        wait(for: [ex], timeout: 5)
    }
    
    func testDisplayNameValidation_whenCreation_displayNameIsEmpty_lastNameHasValue_shouldUseLastName() {
        sut = .init(
            contactEntity: nil,
            dependencies: .init(
                user: mockUser,
                contextProvider: fakeCoreDataService,
                contactService: mockUser.contactService
            )
        )
        let lastName = String.randomString(7)
        sut.getProfile().newDisplayName = ""
        sut.setFirstName("")
        sut.setLastName(lastName)
        
        let ex = expectation(description: "done closure is called")
        sut.done { error in
            XCTAssertNil(error)
            XCTAssertEqual(self.sut.getProfile().newDisplayName, lastName)
            ex.fulfill()
        }
        wait(for: [ex], timeout: 5)
    }
    
    func testDisplayNameValidation_whenCreation_displayNameHasSpaceOnly_nameFilesHasValue_shouldConcatNames() {
        sut = .init(
            contactEntity: nil,
            dependencies: .init(
                user: mockUser,
                contextProvider: fakeCoreDataService,
                contactService: mockUser.contactService
            )
        )
        let firstName = String.randomString(4)
        let lastName = String.randomString(7)
        sut.getProfile().newDisplayName = "    "
        sut.setFirstName(firstName)
        sut.setLastName(lastName)
        
        let ex = expectation(description: "done closure is called")
        sut.done { error in
            XCTAssertNil(error)
            XCTAssertEqual(self.sut.getProfile().newDisplayName, "\(firstName) \(lastName)")
            ex.fulfill()
        }
        wait(for: [ex], timeout: 5)
    }
    
    func testDisplayNameValidation_whenEdit_newDisplayNameIsEmpty_shouldThrowError() throws {
        let firstName = String.randomString(4)
        let lastName = String.randomString(4)
        let displayName = String.randomString(5)
        let vCardData = "BEGIN:VCARD\nVERSION:4.0\nN:\(lastName);\(firstName)\n\nEND:VCARD"
        let cardData = try XCTUnwrap(try generateTestData(vcard: vCardData))
        sut = .init(
            contactEntity: .make(name: displayName, cardData: cardData),
            dependencies: .init(
                user: mockUser,
                contextProvider: fakeCoreDataService,
                contactService: mockUser.contactService
            )
        )
        sut.getProfile().newDisplayName = "   "
        let ex = expectation(description: "done closure is called")
        sut.done { error in
            XCTAssertNotNil(error)
            ex.fulfill()
        }
        wait(for: [ex], timeout: 5)
    }

    private func generateTestData(vcard: String) throws -> String? {
        let key = ContactParserTestData.privateKey
        let encrypted = try vcard.encryptNonOptional(
            withPubKey: key.armoredPublicKey,
            privateKey: "",
            passphrase: ""
        )
        let signature = try Sign.signDetached(
            signingKey: .init(
                privateKey: key,
                passphrase: ContactParserTestData.passphrase
            ),
            plainText: vcard
        )
        let jsonDict: [String: Any] = [
            "Type": CardDataType.SignAndEncrypt.rawValue,
            "Data": encrypted,
            "Signature": signature.value
        ]
        return [jsonDict].toJSONString()
    }
}
