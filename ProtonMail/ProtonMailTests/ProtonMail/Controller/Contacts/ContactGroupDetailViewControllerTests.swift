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

final class ContactGroupDetailViewControllerTests: XCTestCase {
    private var sut: ContactGroupDetailViewController!
    private var viewModel: ContactGroupDetailViewModel!
    private var userID: UserID!

    private var userContainer: UserContainer!
    private var mockUser: UserManager!
    private var mockContextProvider: MockCoreDataContextProvider!

    override func setUpWithError() throws {
        try super.setUpWithError()
        userID = .init(String.randomString(20))
        mockUser = try .prepareUser(apiMock: APIServiceMock(), userID: userID)
        let globalContainer = GlobalContainer()
        mockContextProvider = .init()
        globalContainer.contextProviderFactory.register { self.mockContextProvider }
        userContainer = UserContainer(userManager: mockUser, globalContainer: globalContainer)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        viewModel = nil
        mockUser = nil
        mockContextProvider = nil
        userID = nil
        userContainer = nil
    }

    func testInit_contactGroupDataIsChanged_viewIsUpdatedCorrectly() throws {
        let label = try prepareTestData()
        viewModel = .init(contactGroup: label, dependencies: userContainer)
        sut = .init(viewModel: viewModel, dependencies: userContainer)
        sut.loadViewIfNeeded()

        checkViewData(label, groupName: label.name)

        // ContactGroup data change
        let newName = String.randomString(10)
        let newLabel = try mockContextProvider.write(block: { context in
            guard let labelObject = Label.labelForLabelID(label.labelID.rawValue, inManagedObjectContext: context) else {
                XCTFail("Can not fetch the label here.")
                return LabelEntity.makeMock()
            }
            labelObject.name = newName
            let email = Email(context: context)
            let labelsOfEmail = email.mutableSetValue(forKey: "labels")
            labelsOfEmail.add(labelObject)
            email.userID = self.userID.rawValue
            email.email = "\(String.randomString(20))@pm.me"
            return LabelEntity(label: labelObject)
        })

        checkViewData(newLabel, groupName: newName)
    }

    private func checkViewData(_ label: LabelEntity, groupName: String) {
        wait(self.sut.tableView.visibleCells.count == label.emailRelations.count)

        XCTAssertEqual(sut.groupNameLabel.text, label.name)
        XCTAssertEqual(sut.groupDetailLabel.text, viewModel.getTotalEmailString())
        for email in label.emailRelations {
            XCTAssertNotNil(
                sut.tableView.find(
                    ContactGroupEditViewCell.self,
                    by: { $0.shortNameLabel.text == email.name.initials() && $0.emailLabel.text == email.email }
                )
            )
        }
        XCTAssertEqual(sut.tableView.visibleCells.count, label.emailRelations.count)
    }
}

extension ContactGroupDetailViewControllerTests {
    private func prepareTestData() throws -> LabelEntity {
        return try mockContextProvider.write { context in
            let label = TestDataCreator.generateContactGroupTestData(userID: self.userID, context: context)
            return .init(label: label)
        }
    }
}
