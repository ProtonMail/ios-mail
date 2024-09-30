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

final class ContactGroupsViewControllerTests: XCTestCase {

    var sut: ContactGroupsViewController!
    var viewModel: ContactGroupsViewModelImpl!

    private var mockApi: APIServiceMock!
    private var mockUser: UserManager!
    private var mockContextProvider: MockCoreDataContextProvider!
    private var mockContactService: MockContactProvider!
    private var userContainer: UserContainer!

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
        let globalContainer = GlobalContainer()
        globalContainer.contextProviderFactory.register { self.mockContextProvider }
        userContainer = UserContainer(userManager: mockUser, globalContainer: globalContainer)
        viewModel = .init(dependencies: userContainer)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        viewModel = nil
        userContainer = nil
        mockUser = nil
        mockApi = nil
        mockContextProvider = nil
        mockContactService = nil
    }

    func testInit_newContactGroupIsAdded_viewWillShowNewContactGroup() throws {
        let contactGroup = try prepareTestData()
        sut = .init(viewModel: viewModel, dependencies: userContainer)
        sut.loadViewIfNeeded()

        wait(self.sut.tableView.visibleCells.count == 1)
        XCTAssertNotNil(
            sut.tableView.firstVisibleCell(ofType: ContactGroupsViewCell.self, withLabel: contactGroup.name)
        )

        // Add new contact group
        let newContactGroup = try mockContextProvider.write(block: { context in
            return TestDataCreator.generateContactGroupTestData(userID: self.mockUser.userID, context: context)
        })

        wait(self.sut.tableView.visibleCells.count == 2)
        XCTAssertNotNil(
            sut.tableView.firstVisibleCell(ofType: ContactGroupsViewCell.self, withLabel: newContactGroup.name)
        )
    }
}

extension ContactGroupsViewControllerTests {
    private func prepareTestData() throws -> LabelEntity {
        return try mockContextProvider.write { context in
            let label = TestDataCreator.generateContactGroupTestData(userID: self.mockUser.userID, context: context)
            return .init(label: label)
        }
    }
}
