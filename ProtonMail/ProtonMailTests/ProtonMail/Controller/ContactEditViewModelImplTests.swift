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

import ProtonCore_Crypto
import ProtonCore_TestingToolkit
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
        mockUser = .init(api: mockApi, role: .none)
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
