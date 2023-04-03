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
import ProtonCore_TestingToolkit

class SettingsAccountViewControllerTests: XCTestCase {
    var sut: SettingsAccountViewController!
    var viewModel: SettingsAccountViewModelImpl!
    var coordinatorMock: MockSettingsAccountCoordinatorProtocol!
    var userMock: UserManager!
    var apiServiceMock: APIServiceMock!

    override func setUp() {
        super.setUp()
        apiServiceMock = .init()
        viewModel = .init(user: .init(api: apiServiceMock, role: .none))
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
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 2), 7)
        let cell = try XCTUnwrap(
            sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: 5, section: 2)) as? SettingsGeneralCell
        )
        XCTAssertEqual(cell.leftTextValue(), L11n.NextMsgAfterMove.settingTitle)

        sut.tableView(sut.tableView, didSelectRowAt: .init(row: 5, section: 2))

        XCTAssertTrue(coordinatorMock.goStub.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(coordinatorMock.goStub.lastArguments?.value)
        XCTAssertEqual(argument, .nextMsgAfterMove)
    }

    func testAccountSettings_sectionCount() {
        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.tableView.numberOfSections, 4)

        // account section
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 3)
        // addresses section
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 1), 4)
        // mailbox section
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 2), 7)
        // account deletion
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 3), 1)
    }
}
