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

import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail
import XCTest

final class ContactDetailViewControllerTests: XCTestCase {

    private var viewModel: ContactDetailsViewModel!
    private var sut: ContactDetailViewController!

    private var mockApi: APIServiceMock!
    private var mockUser: UserManager!
    private var mockContextProvider: MockCoreDataContextProvider!
    private var mockContactService: MockContactProvider!
    private var contactID: ContactID!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockApi = .init()
        mockUser = try .prepareUser(apiMock: mockApi)
        mockUser.userInfo.userKeys.append(
            .init(
                keyID: "1",
                privateKey: ContactParserTestData.privateKey.value
            )
        )
        mockUser.authCredential.mailboxpassword = ContactParserTestData.passphrase.value
        mockContextProvider = .init()
        mockContactService = .init(coreDataContextProvider: mockContextProvider)
        contactID = .init(rawValue: String.randomString(20))
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        viewModel = nil
        mockUser = nil
        mockApi = nil
        mockContextProvider = nil
        mockContactService = nil
    }

    func testInit() throws {
        let displayName = String.randomString(20)
        try prepareTestData(displayName: displayName)
        let globalContainer = GlobalContainer()
        globalContainer.contextProviderFactory.register { self.mockContextProvider }
        let userContainer = UserContainer(userManager: mockUser, globalContainer: globalContainer)
        sut = .init(viewModel: viewModel, dependencies: userContainer)
        sut.loadViewIfNeeded()

        wait(self.sut.loaded)

        XCTAssertEqual(sut.customView.displayNameLabel.text, displayName)
        XCTAssertNil(sut.customView.profileImageView.image)
        XCTAssertEqual(sut.customView.shortNameLabel.text, displayName.initials())
        XCTAssertTrue(sut.customView.emailContactImageView.isUserInteractionEnabled)
        XCTAssertTrue(sut.customView.callContactImageView.isUserInteractionEnabled)
        XCTAssertTrue(sut.customView.shareContactImageView.isUserInteractionEnabled)

        let emailCell = try XCTUnwrap(sut.customView.tableView.allIndexedCells(
            ofType: ContactDetailDisplayEmailCell.self,
            inSection: 2
        ).first)
        XCTAssertEqual(emailCell.cell.value.text, "test@pm.me")

        let phoneCell = try XCTUnwrap(sut.customView.tableView.allIndexedCells(
            ofType: ContactDetailsDisplayCell.self,
            inSection: 6
        ).first)
        XCTAssertEqual(phoneCell.cell.value.text, "090000000")

        let addressCell = try XCTUnwrap(sut.customView.tableView.allIndexedCells(
            ofType: ContactDetailsDisplayCell.self,
            inSection: 7
        ).first)
        XCTAssertEqual(addressCell.cell.value.text, "Street City State 000 Country")

        let birthdayCell = try XCTUnwrap(sut.customView.tableView.allIndexedCells(
            ofType: ContactDetailsDisplayCell.self,
            inSection: 8
        ).first)
        XCTAssertEqual(birthdayCell.cell.value.text, "1990-10-22")

        let urlCell = try XCTUnwrap(sut.customView.tableView.allIndexedCells(
            ofType: ContactDetailsDisplayCell.self,
            inSection: 9
        ).first)
        XCTAssertEqual(urlCell.cell.value.text, "www.proton.me")

        let orgCells = try XCTUnwrap(sut.customView.tableView.allIndexedCells(
            ofType: ContactDetailsDisplayCell.self,
            inSection: 10
        ))
        XCTAssertEqual(orgCells[0].cell.value.text, "Organization")
        XCTAssertEqual(orgCells[1].cell.value.text, "Organization2")

        let nickNameCells = try XCTUnwrap(sut.customView.tableView.allIndexedCells(
            ofType: ContactDetailsDisplayCell.self,
            inSection: 11
        ))
        XCTAssertEqual(nickNameCells[0].cell.value.text, "NickName")
        XCTAssertEqual(nickNameCells[1].cell.value.text, "NickName2")

        let titleCells = try XCTUnwrap(sut.customView.tableView.allIndexedCells(
            ofType: ContactDetailsDisplayCell.self,
            inSection: 12
        ))
        XCTAssertEqual(titleCells[0].cell.value.text, "Title")
        XCTAssertEqual(titleCells[1].cell.value.text, "Title2")

        let genderCell = try XCTUnwrap(sut.customView.tableView.allIndexedCells(
            ofType: ContactDetailsDisplayCell.self,
            inSection: 13
        ).first)
        XCTAssertEqual(genderCell.cell.value.text, "GENDER")

        let anniversaryCell = try XCTUnwrap(sut.customView.tableView.allIndexedCells(
            ofType: ContactDetailsDisplayCell.self,
            inSection: 14
        ).first)
        XCTAssertEqual(anniversaryCell.cell.value.text, "20231022")
    }

    func testContactIsUpdated_viewIsUpdated() throws {
        let displayName = String.randomString(20)
        let newDisplayName = String.randomString(20)
        try prepareTestData(displayName: displayName)
        let globalContainer = GlobalContainer()
        globalContainer.contextProviderFactory.register { self.mockContextProvider }
        let userContainer = UserContainer(userManager: mockUser, globalContainer: globalContainer)
        sut = .init(viewModel: viewModel, dependencies: userContainer)
        sut.loadViewIfNeeded()

        wait(self.sut.loaded)

        XCTAssertEqual(sut.customView.displayNameLabel.text, displayName)

        _ = try mockContextProvider.write { context in
            let contact = try XCTUnwrap(try context.existingObject(with: self.viewModel.contact.objectID.rawValue) as? Contact)
            contact.name = newDisplayName
            try context.save()
        }

        wait(self.sut.customView.displayNameLabel.text == newDisplayName)
    }
}

extension ContactDetailViewControllerTests {
    private func prepareTestData(displayName: String) throws {
        let vCardData = "BEGIN:VCARD\r\nVERSION:4.0\r\nPRODID:pm-ez-vcard 0.0.1\r\nITEM1.CATEGORIES:\r\nEND:VCARD\r\n"
        let vCardSignedData = "BEGIN:VCARD\r\nVERSION:4.0\r\nPRODID:pm-ez-vcard 0.0.1\r\nFN:\(displayName)\r\nItem1.EMAIL;TYPE=:test@pm.me\r\nEND:VCARD\r\n"
        let vCardSignedAndEncryptedData = "BEGIN:VCARD\r\nVERSION:4.0\r\nPRODID:pm-ez-vcard 0.0.1\r\nN:LastName;FirstName\r\nURL:www.proton.me\r\nBDAY;VALUE=text:1990-10-22\r\nGENDER:Gender\r\nTITLE:Title\r\nNICKNAME:NickName\r\nADR;TYPE=:;;Street;City;State;000;Country\r\nORG:Organization\r\nTEL:090000000\r\nORG:Organization2\r\nTITLE:Title2\r\nNICKNAME:NickName2\r\nANNIVERSARY:20231022\r\nEND:VCARD\r\n"

        let data = try XCTUnwrap(
            try TestDataCreator.generateVCardTestData(
                vCardSignAndEncrypt: vCardSignedAndEncryptedData,
                vCardSign: vCardSignedData,
                vCard: vCardData
            )
        )
        let contact = try mockContextProvider.write { context in
            let rawContact = Contact(context: context)
            rawContact.cardData = data
            rawContact.name = displayName
            rawContact.contactID = self.contactID.rawValue
            try context.save()
            return rawContact
        }
        let entity = ContactEntity.make(
            objectID: .init(rawValue: contact.objectID),
            contactID: contactID,
            name: displayName,
            cardData: data
        )
        mockContactService.fetchContactResult = entity
        viewModel = .init(
            contact: entity,
            dependencies: .init(
                user: mockUser,
                coreDataService: mockContextProvider,
                contactService: mockContactService
            )
        )
    }
}
