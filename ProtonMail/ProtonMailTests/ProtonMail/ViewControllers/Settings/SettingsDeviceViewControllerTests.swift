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

import XCTest
@testable import ProtonMail
import ProtonCore_TestingToolkit

class SettingsDeviceViewControllerTests: XCTestCase {

    var sut: SettingsDeviceViewController!
    var viewModel: SettingsDeviceViewModel!
    var mockUser: UserManager!
    var mockApiService: APIServiceMock!
    var mockUsers: UsersManager!
    var mockDoh: DohMock!
    var stubBioStatus: BioMetricStatusStub!
    var settingsDeviceCoordinatorMock: MockSettingsDeviceCoordinator!

    override func setUp() {
        super.setUp()
        mockDoh = DohMock()
        mockApiService = APIServiceMock()
        mockUser = UserManager(api: mockApiService, role: .none)
        mockUsers = UsersManager(doh: mockDoh)
        mockUsers.add(newUser: mockUser)
        stubBioStatus = BioMetricStatusStub()
        viewModel = SettingsDeviceViewModel(user: mockUser,
                                            users: mockUsers,
                                            biometricStatus: stubBioStatus)
        settingsDeviceCoordinatorMock = MockSettingsDeviceCoordinator(
            navigationController: nil,
            user: mockUser,
            usersManager: mockUsers,
            services: ServiceFactory()
        )
        sut = SettingsDeviceViewController(
            viewModel: viewModel,
            coordinator: settingsDeviceCoordinatorMock
        )
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        viewModel = nil
        mockUsers = nil
        mockUser = nil
        mockApiService = nil
        mockDoh = nil
        stubBioStatus = nil
        settingsDeviceCoordinatorMock = nil
    }

    func testAppSettings_hasCustomizeToolbarAction() throws {
        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.tableView.numberOfSections, 4)
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 1), 7)

        let cell = try XCTUnwrap(sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: 6, section: 1)) as? SettingsGeneralCell)
        XCTAssertEqual(cell.leftTextValue(), LocalString._toolbar_customize_general_title)
    }

    func testAppSettings_tapDarkMode_openCorrectPage() throws {
        sut.loadViewIfNeeded()

        sut.tableView(sut.tableView, didSelectRowAt: IndexPath(row: 0, section: 1))

        XCTAssertTrue(settingsDeviceCoordinatorMock.callGo.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(settingsDeviceCoordinatorMock.callGo.lastArguments?.first)
        XCTAssertEqual(argument, .darkMode)
    }

    func testAppSettings_appPin_openCorrectPage() throws {
        sut.loadViewIfNeeded()

        sut.tableView(sut.tableView, didSelectRowAt: IndexPath(row: 1, section: 1))

        XCTAssertTrue(settingsDeviceCoordinatorMock.callGo.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(settingsDeviceCoordinatorMock.callGo.lastArguments?.first)
        XCTAssertEqual(argument, .autoLock)
    }

    func testAppSettings_combineContacts_openCorrectPage() throws {
        sut.loadViewIfNeeded()

        sut.tableView(sut.tableView, didSelectRowAt: IndexPath(row: 2, section: 1))

        XCTAssertTrue(settingsDeviceCoordinatorMock.callGo.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(settingsDeviceCoordinatorMock.callGo.lastArguments?.first)
        XCTAssertEqual(argument, .combineContact)
    }

    func testAppSettings_alternativeRouting_openCorrectPage() throws {
        sut.loadViewIfNeeded()

        sut.tableView(sut.tableView, didSelectRowAt: IndexPath(row: 4, section: 1))

        XCTAssertTrue(settingsDeviceCoordinatorMock.callGo.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(settingsDeviceCoordinatorMock.callGo.lastArguments?.first)
        XCTAssertEqual(argument, .alternativeRouting)
    }

    func testAppSettings_swipeAction_openCorrectPage() throws {
        sut.loadViewIfNeeded()

        sut.tableView(sut.tableView, didSelectRowAt: IndexPath(row: 5, section: 1))

        XCTAssertTrue(settingsDeviceCoordinatorMock.callGo.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(settingsDeviceCoordinatorMock.callGo.lastArguments?.first)
        XCTAssertEqual(argument, .swipeAction)
    }    
}
