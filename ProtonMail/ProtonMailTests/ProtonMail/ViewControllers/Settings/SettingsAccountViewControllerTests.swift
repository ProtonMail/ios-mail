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

import XCTest
@testable import ProtonMail
import ProtonCoreTestingToolkit

class SettingsAccountViewControllerTests: XCTestCase {
    var sut: SettingsAccountViewController!
    var viewModel: SettingsAccountViewModel!
    var coordinatorMock: MockSettingsAccountCoordinatorProtocol!
    var userMock: UserManager!
    var apiServiceMock: APIServiceMock!

    override func setUp() {
        super.setUp()
        apiServiceMock = .init()
        userMock = .init(api: apiServiceMock)
        viewModel = .init(user: userMock, isMessageSwipeNavigationEnabled: true)
        coordinatorMock = .init()
        sut = .init(viewModel: viewModel, coordinator: coordinatorMock)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        viewModel = nil
        coordinatorMock = nil
        userMock = nil
        apiServiceMock = nil
    }

    func testMailboxSettings_tapMoveToNextAction_openNextMsgAfterMovePage() throws {
        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.tableView.numberOfSections, 4)
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 2), 8)
        let cell = try XCTUnwrap(
            sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: 7, section: 2)) as? SettingsGeneralCell
        )
        XCTAssertEqual(cell.leftTextValue(), L11n.AutoDeleteSettings.settingTitle)

        sut.tableView(sut.tableView, didSelectRowAt: .init(row: 7, section: 2))

        XCTAssertTrue(coordinatorMock.goStub.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(coordinatorMock.goStub.lastArguments?.value)
        XCTAssertEqual(argument, .autoDeleteSpamTrash)
    }

    func testAccountSettings_sectionCount() {
        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.tableView.numberOfSections, 4)

        // account section
        let accountCells = sut.tableView.allIndexedCells(ofType: SettingsGeneralCell.self, inSection: 0)
        XCTAssertEqual(accountCells.count, 4)
        XCTAssertEqual(
            accountCells[0].cell.leftTextValue(),
            SettingsAccountItem.singlePassword.description
        )
        XCTAssertEqual(
            accountCells[1].cell.leftTextValue(),
            SettingsAccountItem.recovery.description
        )
        XCTAssertEqual(
            accountCells[2].cell.leftTextValue(),
            SettingsAccountItem.storage.description
        )
        XCTAssertEqual(
            accountCells[3].cell.leftTextValue(),
            SettingsAccountItem.privacyAndData.description
        )

        // addresses section
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 1), 4)
        // mailbox section
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 2), 8)
        // account deletion
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 3), 1)
    }

    func testAccountSettings_twoPasswordMode_hasLoginAndMailboxPwdSettings() {
        userMock.userInfo.passwordMode = 2
        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.tableView.numberOfSections, 4)

        let accountCells = sut.tableView.allIndexedCells(ofType: SettingsGeneralCell.self, inSection: 0)
        XCTAssertEqual(accountCells.count, 5)
        XCTAssertEqual(
            accountCells[0].cell.leftTextValue(),
            SettingsAccountItem.loginPassword.description
        )
        XCTAssertEqual(
            accountCells[1].cell.leftTextValue(),
            SettingsAccountItem.mailboxPassword.description
        )
        XCTAssertEqual(
            accountCells[2].cell.leftTextValue(),
            SettingsAccountItem.recovery.description
        )
        XCTAssertEqual(
            accountCells[3].cell.leftTextValue(),
            SettingsAccountItem.storage.description
        )
        XCTAssertEqual(
            accountCells[4].cell.leftTextValue(),
            SettingsAccountItem.privacyAndData.description
        )
    }
}
