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
    var stubDohStatus: DohStatusStub!
    var stubBioStatus: BioMetricStatusStub!
    var fakeSettingsDeviceCoordinator: SettingsDeviceCoordinator!

    override func setUp() {
        super.setUp()
        mockDoh = DohMock()
        mockApiService = APIServiceMock()
        mockUser = UserManager(api: mockApiService, role: .none)
        mockUsers = UsersManager(doh: mockDoh)
        mockUsers.add(newUser: mockUser)
        stubDohStatus = DohStatusStub()
        stubBioStatus = BioMetricStatusStub()
        viewModel = SettingsDeviceViewModel(user: mockUser,
                                            users: mockUsers,
                                            dohSetting: stubDohStatus,
                                            biometricStatus: stubBioStatus)
        fakeSettingsDeviceCoordinator = SettingsDeviceCoordinator(
            navigationController: nil,
            user: mockUser,
            usersManager: mockUsers,
            services: ServiceFactory()
        )
        sut = SettingsDeviceViewController(
            viewModel: viewModel,
            coordinator: fakeSettingsDeviceCoordinator
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
        stubDohStatus = nil
        fakeSettingsDeviceCoordinator = nil
    }

    func testAppSettings_hasCustomizeToolbarAction() throws {
        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.tableView.numberOfSections, 4)
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 1), 7)

        let cell = try XCTUnwrap(sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: 6, section: 1)) as? SettingsGeneralCell)
        XCTAssertEqual(cell.leftTextValue(), LocalString._toolbar_customize_general_title)
    }
}
