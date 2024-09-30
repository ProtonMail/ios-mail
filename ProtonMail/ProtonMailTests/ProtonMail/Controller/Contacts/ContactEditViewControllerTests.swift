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
import ProtonCoreUIFoundations
@testable import ProtonMail
import VCard
import XCTest

final class ContactEditViewControllerTests: XCTestCase {
    private var sut: ContactEditViewController!
    private var viewModel: ContactEditViewModel!
    private var mockUser: UserManager!
    private var fakeCoreDataService: CoreDataService!
    private var mockContactService: MockContactDataServiceProtocol!
    private var userContainer: UserContainer!

    private let firstName = String.randomString(20)
    private let lastName = String.randomString(20)
    private let displayName = String.randomString(20)

    override func setUp() {
        super.setUp()
        mockUser = .init(api: APIServiceMock())
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
        mockContactService = .init()
        mockContactService.queueAddContactStub.bodyIs { _, _, _, _, _ in nil }

        let globalContainer = GlobalContainer()
        userContainer = UserContainer(userManager: mockUser, globalContainer: globalContainer)
    }

    override func tearDown() {
        sut = nil
        fakeCoreDataService = nil
        mockContactService = nil
        mockUser = nil
        userContainer = nil
        viewModel = nil

        super.tearDown()
    }

    func testCreateNewContact_noDisplayNameIsEntered_alertBannerShouldBeShown() {
        viewModel = .init(
            contactEntity: nil,
            dependencies: .init(
                user: mockUser,
                contextProvider: fakeCoreDataService,
                contactService: mockContactService
            )
        )
        sut = .init(viewModel: viewModel, dependencies: userContainer)
        sut.loadViewIfNeeded()

        clickDone()

        wait(self.sut.failureBanner(withErrorMessage: L10n.ContactEdit.emptyDisplayNameError) != nil)

        XCTAssertTrue(mockContactService.queueAddContactStub.wasNotCalled)
    }

    func testCreateNewContact_firstNameAndLastNameAreEntered_displayNameIsEmpty_displayNameShouldBeTheConcatenationOfFirstAndLastName() throws {
        setupNewContactSUT()
        sut.customView.firstNameField.simulateType(text: "FirstName")
        sut.customView.lastNameField.simulateType(text: "LastName")

        clickDone()

        wait(self.mockContactService.queueAddContactStub.wasCalled)

        let parameters = try XCTUnwrap(mockContactService.queueAddContactStub.lastArguments)
        XCTAssertEqual(parameters.a2, "FirstName LastName")
        XCTAssertFalse(parameters.a4)

        let cardDatas = parameters.a1
        let signedOnlyVCardData = cardDatas[1]
        let signedOnlyVCard = try parseAndVerify(cardData: signedOnlyVCardData)
        let displayName = try XCTUnwrap(signedOnlyVCard?.getFormattedName())
        XCTAssertEqual(displayName.getValue(), "FirstName LastName")

        let signedAndEncryptedVCardData = cardDatas[2]
        let signedAndEncryptedVCard = try parseAndVerify(cardData: signedAndEncryptedVCardData)
        let structuredName = try XCTUnwrap(signedAndEncryptedVCard?.getStructuredName())
        XCTAssertEqual(structuredName.getGiven(), "FirstName")
        XCTAssertEqual(structuredName.getFamily(), "LastName")
    }

    func testCreateNewContact_onlyFirstNameIsEntered_displayNameIsEmpty_displayNameIsTheSameAsFirstName() throws {
        setupNewContactSUT()
        sut.customView.firstNameField.simulateType(text: "FirstName")

        clickDone()

        wait(self.mockContactService.queueAddContactStub.wasCalled)

        let parameters = try XCTUnwrap(mockContactService.queueAddContactStub.lastArguments)
        XCTAssertEqual(parameters.a2, "FirstName")
        XCTAssertFalse(parameters.a4)

        let cardDatas = parameters.a1
        let signedOnlyVCardData = cardDatas[1]
        let signedOnlyVCard = try parseAndVerify(cardData: signedOnlyVCardData)
        let displayName = try XCTUnwrap(signedOnlyVCard?.getFormattedName())
        XCTAssertEqual(displayName.getValue(), "FirstName")

        let signedAndEncryptedVCardData = cardDatas[2]
        let signedAndEncryptedVCard = try parseAndVerify(cardData: signedAndEncryptedVCardData)
        let structuredName = try XCTUnwrap(signedAndEncryptedVCard?.getStructuredName())
        XCTAssertEqual(structuredName.getGiven(), "FirstName")
        XCTAssertEqual(structuredName.getFamily(), "")
    }

    func testCreateNewContact_onlyLastNameIsEntered_displayNameIsEmpty_displayNameIsTheSameAsLastName() throws {
        setupNewContactSUT()
        sut.customView.lastNameField.simulateType(text: "LastName")

        clickDone()

        wait(self.mockContactService.queueAddContactStub.wasCalled)

        let parameters = try XCTUnwrap(mockContactService.queueAddContactStub.lastArguments)
        XCTAssertEqual(parameters.a2, "LastName")
        XCTAssertFalse(parameters.a4)

        let cardDatas = parameters.a1
        let signedOnlyVCardData = cardDatas[1]
        let signedOnlyVCard = try parseAndVerify(cardData: signedOnlyVCardData)
        let displayName = try XCTUnwrap(signedOnlyVCard?.getFormattedName())
        XCTAssertEqual(displayName.getValue(), "LastName")

        let signedAndEncryptedVCardData = cardDatas[2]
        let signedAndEncryptedVCard = try parseAndVerify(cardData: signedAndEncryptedVCardData)
        let structuredName = try XCTUnwrap(signedAndEncryptedVCard?.getStructuredName())
        XCTAssertEqual(structuredName.getGiven(), "")
        XCTAssertEqual(structuredName.getFamily(), "LastName")
    }

    func testCreateNewContact_AllNamesAreEntered_vCardDatasAreCorrect() throws {
        setupNewContactSUT()
        sut.customView.lastNameField.simulateType(text: lastName)
        sut.customView.firstNameField.simulateType(text: firstName)
        sut.customView.displayNameField.simulateType(text: displayName)

        clickDone()

        wait(self.mockContactService.queueAddContactStub.wasCalled)

        let parameters = try XCTUnwrap(mockContactService.queueAddContactStub.lastArguments)
        XCTAssertEqual(parameters.a2, displayName)
        XCTAssertFalse(parameters.a4)

        let cardDatas = parameters.a1
        let signedOnlyVCardData = cardDatas[1]
        let signedOnlyVCard = try parseAndVerify(cardData: signedOnlyVCardData)
        let formattedName = try XCTUnwrap(signedOnlyVCard?.getFormattedName())
        XCTAssertEqual(formattedName.getValue(), displayName)

        let signedAndEncryptedVCardData = cardDatas[2]
        let signedAndEncryptedVCard = try parseAndVerify(cardData: signedAndEncryptedVCardData)
        let structuredName = try XCTUnwrap(signedAndEncryptedVCard?.getStructuredName())
        XCTAssertEqual(structuredName.getGiven(), firstName)
        XCTAssertEqual(structuredName.getFamily(), lastName)
    }

    func testEditContact_displayNameSetToEmpty_alertBannerShouldBeShown() throws {
        let displayName = String.randomString(20)
        let vCardSignedAndEncryptedData = "BEGIN:VCARD\nVERSION:4.0\nN:lastName;firstName\nEND:VCARD"
        let vCardSignedData = "BEGIN:VCARD\nVERSION:4.0\nFN:\(displayName)\nEND:VCARD"
        let data = try XCTUnwrap(
            try TestDataCreator.generateVCardTestData(
                vCardSignAndEncrypt: vCardSignedAndEncryptedData,
                vCardSign: vCardSignedData,
                vCard: ""
            )
        )
        viewModel = .init(
            contactEntity: .make(name: displayName, cardData: data),
            dependencies: .init(
                user: mockUser,
                contextProvider: fakeCoreDataService,
                contactService: mockContactService
            )
        )
        sut = .init(viewModel: viewModel, dependencies: userContainer)
        sut.loadViewIfNeeded()

        sut.customView.displayNameField.simulateType(text: "")

        clickDone()

        wait(self.sut.failureBanner(withErrorMessage: L10n.ContactEdit.emptyDisplayNameError) != nil)

        XCTAssertTrue(mockContactService.queueAddContactStub.wasNotCalled)
    }

    func testEditContact_ChangeAllField_vCardDatasAreCorrect() throws {
        let vCardData = "BEGIN:VCARD\r\nVERSION:4.0\r\nPRODID:pm-ez-vcard 0.0.1\r\nITEM1.CATEGORIES:\r\nEND:VCARD\r\n"
        let vCardSignedData = "BEGIN:VCARD\r\nVERSION:4.0\r\nPRODID:pm-ez-vcard 0.0.1\r\nFN:DisplayName\r\nItem1.EMAIL;TYPE=:test@pm.me\r\nEND:VCARD\r\n"
        let vCardSignedAndEncryptedData = "BEGIN:VCARD\r\nVERSION:4.0\r\nPRODID:pm-ez-vcard 0.0.1\r\nN:LastName;FirstName\r\nURL:www.proton.me\r\nBDAY;VALUE=text:1990-10-22\r\nGENDER:Gender\r\nTITLE:Title\r\nNICKNAME:NickName\r\nADR;TYPE=:;;Street;City;State;000;Country\r\nORG:Organization\r\nTEL:090000000\r\nORG:Organization2\r\nTITLE:Title2\r\nNICKNAME:NickName2\r\nANNIVERSARY:20231022\r\nEND:VCARD\r\n"

        let data = try XCTUnwrap(
            try TestDataCreator.generateVCardTestData(
                vCardSignAndEncrypt: vCardSignedAndEncryptedData,
                vCardSign: vCardSignedData,
                vCard: vCardData
            )
        )
        viewModel = .init(
            contactEntity: .make(name: "", cardData: data),
            dependencies: .init(
                user: mockUser,
                contextProvider: fakeCoreDataService,
                contactService: mockContactService
            )
        )
        sut = .init(viewModel: viewModel, dependencies: userContainer)
        sut.loadViewIfNeeded()

        // Enter random data
        let displayName = String.randomString(20)
        let firstName = String.randomString(20)
        let lastName = String.randomString(20)
        let email = "\(String.randomString(10))@pm.me"
        let cellPhone = "0999999999"
        let homeCountry = String.randomString(20)
        let url = String.randomString(20)
        let gender = "M"
        let title = String.randomString(20)
        let nickName = String.randomString(20)
        let birthday = "2023-01-01"
        let organization = String.randomString(20)
        let note = String.randomString(200)
        let anniversary = "20231122"

        sut.customView.displayNameField.simulateType(text: displayName)
        sut.customView.firstNameField.simulateType(text: firstName)
        sut.customView.lastNameField.simulateType(text: lastName)
        let emailEditCell = try XCTUnwrap(
            sut.tableView(sut.customView.tableView, cellForRowAt: .init(row: 0, section: 0)) as? ContactEditEmailCell
        )
        emailEditCell.valueField.simulateType(text: email)

        let cellPhoneCell = try XCTUnwrap(
            sut.tableView(sut.customView.tableView, cellForRowAt: .init(row: 0, section: 2)) as? ContactEditPhoneCell
        )
        cellPhoneCell.valueField.simulateType(text: cellPhone)

        let homeCell = try XCTUnwrap(
            sut.tableView(sut.customView.tableView, cellForRowAt: .init(row: 0, section: 3)) as? ContactEditAddressCell
        )
        homeCell.countyField.simulateType(text: homeCountry)

        let birthdayCell = try XCTUnwrap(
            sut.tableView(sut.customView.tableView, cellForRowAt: .init(row: 0, section: 4)) as? ContactEditInformationCell
        )
        birthdayCell.valueField.simulateType(text: birthday)

        let nickNameCell = try XCTUnwrap(
            sut.tableView(sut.customView.tableView, cellForRowAt: .init(row: 0, section: 5)) as? ContactEditInformationCell
        )
        nickNameCell.valueField.simulateType(text: nickName)

        let titleCell = try XCTUnwrap(
            sut.tableView(sut.customView.tableView, cellForRowAt: .init(row: 0, section: 6)) as? ContactEditInformationCell
        )
        titleCell.valueField.simulateType(text: title)

        let orgCell = try XCTUnwrap(
            sut.tableView(sut.customView.tableView, cellForRowAt: .init(row: 0, section: 7)) as? ContactEditInformationCell
        )
        orgCell.valueField.simulateType(text: organization)

        let urlCell = try XCTUnwrap(
            sut.tableView(sut.customView.tableView, cellForRowAt: .init(row: 0, section: 8)) as? ContactEditUrlCell
        )
        urlCell.valueField.simulateType(text: url)

        let anniversaryCell = try XCTUnwrap(
            sut.tableView(sut.customView.tableView, cellForRowAt: .init(row: 0, section: 9)) as? ContactEditInformationCell
        )
        anniversaryCell.valueField.simulateType(text: anniversary)

        let genderCell = try XCTUnwrap(
            sut.tableView(sut.customView.tableView, cellForRowAt: .init(row: 0, section: 10)) as? ContactEditInformationCell
        )
        genderCell.valueField.simulateType(text: gender)

        let noteCell = try XCTUnwrap(
            sut.tableView(sut.customView.tableView, cellForRowAt: .init(row: 0, section: 12)) as? ContactEditTextViewCell
        )
        noteCell.textView.simulate(textInput: note)

        clickDone()

        wait(self.mockContactService.queueUpdateStub.wasCalled)

        let parameters = try XCTUnwrap(mockContactService.queueUpdateStub.lastArguments)
        XCTAssertEqual(parameters.a3, displayName)

        let cardDatas = parameters.a2
        let signedOnlyVCardData = cardDatas[1]
        let signedOnlyVCard = try XCTUnwrap(try parseAndVerify(cardData: signedOnlyVCardData))
        let formattedName = try XCTUnwrap(signedOnlyVCard.getFormattedName())
        XCTAssertEqual(formattedName.getValue(), displayName)
        let emails = signedOnlyVCard.getEmails()
        XCTAssertEqual(emails.first?.getValue(), email)

        let signedAndEncryptedVCardData = cardDatas[2]
        let signedAndEncryptedVCard = try XCTUnwrap(try parseAndVerify(cardData: signedAndEncryptedVCardData))
        let structuredName = try XCTUnwrap(signedAndEncryptedVCard.getStructuredName())
        XCTAssertEqual(structuredName.getGiven(), firstName)
        XCTAssertEqual(structuredName.getFamily(), lastName)
        let phones = signedAndEncryptedVCard.getTelephoneNumbers()
        XCTAssertEqual(phones.first?.getText(), cellPhone)
        let homeAddresses = signedAndEncryptedVCard.getAddresses()
        XCTAssertEqual(homeAddresses.first?.getCountry(), homeCountry)
        let urls = signedAndEncryptedVCard.getUrls()
        XCTAssertEqual(urls.first?.getValue(), url)
        let rawOrgs = signedAndEncryptedVCard.getOrganizations()
        XCTAssertEqual(rawOrgs[0].getValue(), organization)
        XCTAssertEqual(rawOrgs[1].getValue(), "Organization2")
        let bdays = signedAndEncryptedVCard.getBirthdays()
        XCTAssertEqual(bdays.first?.getText(), birthday)
        let rawGender = signedAndEncryptedVCard.getGender()
        XCTAssertEqual(rawGender?.getGender(), gender)
        let rawTitles = signedAndEncryptedVCard.getTitles()
        XCTAssertEqual(rawTitles[0].getTitle(), title)
        XCTAssertEqual(rawTitles[1].getTitle(), "Title2")
        let rawNickNames = signedAndEncryptedVCard.getNicknames()
        XCTAssertEqual(rawNickNames[0].getNickname(), nickName)
        XCTAssertEqual(rawNickNames[1].getNickname(), "NickName2")
        let rawAnniversary = signedAndEncryptedVCard.getAnniversary()
        XCTAssertEqual(rawAnniversary?.getDate(), anniversary)
        let notes = signedAndEncryptedVCard.getNotes()
        XCTAssertEqual(notes.first?.getNote(), note)
    }

    func testEditContact_removeAllNoteText_removeTheNoteField() throws {
        let note = String.randomString(20)
        let vCardSignedAndEncryptedData = "BEGIN:VCARD\nVERSION:4.0\nN:lastName;firstName\nNOTE:\(note)\nEND:VCARD"
        let vCardSignedData = "BEGIN:VCARD\nVERSION:4.0\nFN:Name\nEND:VCARD"
        let data = try XCTUnwrap(
            try TestDataCreator.generateVCardTestData(
                vCardSignAndEncrypt: vCardSignedAndEncryptedData,
                vCardSign: vCardSignedData,
                vCard: ""
            )
        )
        viewModel = .init(
            contactEntity: .make(name: "Name", cardData: data),
            dependencies: .init(
                user: mockUser,
                contextProvider: fakeCoreDataService,
                contactService: mockContactService
            )
        )
        sut = .init(viewModel: viewModel, dependencies: userContainer)
        sut.loadViewIfNeeded()

        let noteCell = try XCTUnwrap(
            sut.tableView(sut.customView.tableView, cellForRowAt: .init(row: 0, section: 6)) as? ContactEditTextViewCell
        )
        noteCell.textView.simulate(textInput: "")

        clickDone()

        wait(self.mockContactService.queueUpdateStub.wasCalled)

        let parameters = try XCTUnwrap(mockContactService.queueUpdateStub.lastArguments)

        let cardDatas = parameters.a2
        let signedAndEncryptedVCardData = cardDatas[2]
        let signedAndEncryptedVCard = try parseAndVerify(cardData: signedAndEncryptedVCardData)
        XCTAssertNil(signedAndEncryptedVCard?.getNote())
    }
}

extension ContactEditViewControllerTests {
    private func setupNewContactSUT() {
        viewModel = .init(
            contactEntity: nil,
            dependencies: .init(
                user: mockUser,
                contextProvider: fakeCoreDataService,
                contactService: mockContactService
            )
        )
        sut = .init(viewModel: viewModel, dependencies: userContainer)
        sut.loadViewIfNeeded()
    }

    private func clickDone() {
        _ = sut.doneButton?.target?.perform(sut.doneButton?.action)
    }

    private func parseAndVerify(
        cardData: CardData,
        userPrivateKey: ArmoredKey = ContactParserTestData.privateKey,
        passphrase: Passphrase = ContactParserTestData.passphrase
    ) throws -> PMNIVCard? {
        let plainText: String
        switch cardData.type {
        case .SignedOnly:
            plainText = cardData.data
        case .SignAndEncrypt:
            plainText = try cardData.data.decryptMessageWithSingleKeyNonOptional(userPrivateKey, passphrase: passphrase)
        default:
            plainText = cardData.data
        }

        if !cardData.signature.isEmpty {
            let result = try Sign.verifyDetached(
                signature: .init(value: cardData.signature),
                plainText: plainText,
                verifierKey: .init(value: userPrivateKey.armoredPublicKey)
            )
            XCTAssertTrue(result)
        }

        return PMNIEzvcard.parseFirst(plainText)
    }
}
