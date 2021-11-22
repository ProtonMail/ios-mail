// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

@testable import ProtonMail
import XCTest

class SettingsDarkModeViewModelTests: XCTestCase {

    var sut: SettingsDarkModeViewModel!
    var stub: DarkModeStatusStub!

    override func setUp() {
        super.setUp()
        stub = DarkModeStatusStub()
        sut = SettingsDarkModeViewModel(darkModeCache: stub)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        stub = nil
    }

    func testUpdateDarkModeStatus_getNotificationAndSetStatusToFollowSystem() {

        let expectation1 = XCTNSNotificationExpectation(name: .shouldUpdateUserInterfaceStyle)

        sut.updateDarkModeStatus(to: DarkModeStatus.forceOn)
        XCTAssertEqual(stub.darkModeStatus, DarkModeStatus.forceOn)

        wait(for: [expectation1], timeout: 1)
    }

    func testGetTitle() {
        XCTAssertEqual(sut.title, LocalString._dark_mode)
    }

    func testGetCellShouldShowSelection_followSystem_onlyRow0ReturnTrue() {
        stub.darkModeStatus = .followSystem

        XCTAssertTrue(sut.getCellShouldShowSelection(of: IndexPath(row: 0, section: 0)))

        XCTAssertFalse(sut.getCellShouldShowSelection(of: IndexPath(row: 1, section: 0)))
        XCTAssertFalse(sut.getCellShouldShowSelection(of: IndexPath(row: 2, section: 0)))
        XCTAssertFalse(sut.getCellShouldShowSelection(of: IndexPath(row: 3, section: 0)))
        XCTAssertFalse(sut.getCellShouldShowSelection(of: IndexPath(row: 4, section: 0)))
        XCTAssertFalse(sut.getCellShouldShowSelection(of: IndexPath(row: 1, section: 1)))
    }

    func testGetCellShouldShowSelection_forceOn_onlyRow1ReturnTrue() {
        stub.darkModeStatus = .forceOn

        XCTAssertTrue(sut.getCellShouldShowSelection(of: IndexPath(row: 1, section: 0)))

        XCTAssertFalse(sut.getCellShouldShowSelection(of: IndexPath(row: 0, section: 0)))
        XCTAssertFalse(sut.getCellShouldShowSelection(of: IndexPath(row: 2, section: 0)))
        XCTAssertFalse(sut.getCellShouldShowSelection(of: IndexPath(row: 3, section: 0)))
        XCTAssertFalse(sut.getCellShouldShowSelection(of: IndexPath(row: 4, section: 0)))
        XCTAssertFalse(sut.getCellShouldShowSelection(of: IndexPath(row: 1, section: 1)))
    }

    func testGetCellShouldShowSelection_followSystem_onlyRow2ReturnTrue() {
        stub.darkModeStatus = .forceOff

        XCTAssertTrue(sut.getCellShouldShowSelection(of: IndexPath(row: 2, section: 0)))

        XCTAssertFalse(sut.getCellShouldShowSelection(of: IndexPath(row: 0, section: 0)))
        XCTAssertFalse(sut.getCellShouldShowSelection(of: IndexPath(row: 1, section: 0)))
        XCTAssertFalse(sut.getCellShouldShowSelection(of: IndexPath(row: 3, section: 0)))
        XCTAssertFalse(sut.getCellShouldShowSelection(of: IndexPath(row: 4, section: 0)))
        XCTAssertFalse(sut.getCellShouldShowSelection(of: IndexPath(row: 1, section: 1)))
    }

    func testGetCellTitle() {
        XCTAssertEqual(sut.getCellTitle(of: IndexPath(row: 0, section: 0)), DarkModeStatus.followSystem.titleOfSetting)
        XCTAssertEqual(sut.getCellTitle(of: IndexPath(row: 1, section: 0)), DarkModeStatus.forceOn.titleOfSetting)
        XCTAssertEqual(sut.getCellTitle(of: IndexPath(row: 2, section: 0)), DarkModeStatus.forceOff.titleOfSetting)

        XCTAssertNil(sut.getCellTitle(of: IndexPath(row: 3, section: 0)))
        XCTAssertNil(sut.getCellTitle(of: IndexPath(row: 1, section: 1)))
    }

    func testGetDarkModeStatusForIndexPath() {
        // section not 0
        XCTAssertNil(sut.getDarkModeStatus(for: IndexPath(row: 0, section: 1)))
        XCTAssertNil(sut.getDarkModeStatus(for: IndexPath(row: 0, section: 2)))

        XCTAssertEqual(sut.getDarkModeStatus(for: IndexPath(row: 0, section: 0)), .followSystem)
        XCTAssertEqual(sut.getDarkModeStatus(for: IndexPath(row: 1, section: 0)), .forceOn)
        XCTAssertEqual(sut.getDarkModeStatus(for: IndexPath(row: 2, section: 0)), .forceOff)

        XCTAssertNil(sut.getDarkModeStatus(for: IndexPath(row: 3, section: 0)))
    }

    func testIndexPathFor() {
        XCTAssertEqual(sut.indexPath(for: .followSystem), IndexPath(row: 0, section: 0))
        XCTAssertEqual(sut.indexPath(for: .forceOn), IndexPath(row: 1, section: 0))
        XCTAssertEqual(sut.indexPath(for: .forceOff), IndexPath(row: 2, section: 0))
    }
}
