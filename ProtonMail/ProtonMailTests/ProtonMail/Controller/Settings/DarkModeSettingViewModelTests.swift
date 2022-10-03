// Copyright (c) 2021 Proton AG
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

@testable import ProtonMail
import XCTest

class DarkModeSettingViewModelTests: XCTestCase {

    var sut: DarkModeSettingViewModel!
    var stub: DarkModeStatusStub!

    override func setUp() {
        super.setUp()
        stub = DarkModeStatusStub()
        sut = DarkModeSettingViewModel(darkModeCache: stub)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        stub = nil
    }

    func testUpdateDarkModeStatus_getNotificationAndSetStatusToFollowSystem() {

        let expectation1 = XCTNSNotificationExpectation(name: .shouldUpdateUserInterfaceStyle)
        sut.selectItem(indexPath: IndexPath(row: 1, section: 0))
        sut.selectItem(indexPath: IndexPath(row: 1, section: 0))
        XCTAssertEqual(stub.darkModeStatus, DarkModeStatus.forceOn)

        wait(for: [expectation1], timeout: 1)
    }

    func testGetCellShouldShowSelection_followSystem_onlyRow0ReturnTrue() {
        stub.darkModeStatus = .followSystem

        XCTAssertTrue(sut.cellShouldShowSelection(of: IndexPath(row: 0, section: 0)))

        XCTAssertFalse(sut.cellShouldShowSelection(of: IndexPath(row: 1, section: 0)))
        XCTAssertFalse(sut.cellShouldShowSelection(of: IndexPath(row: 2, section: 0)))
        XCTAssertFalse(sut.cellShouldShowSelection(of: IndexPath(row: 3, section: 0)))
        XCTAssertFalse(sut.cellShouldShowSelection(of: IndexPath(row: 4, section: 0)))
        XCTAssertFalse(sut.cellShouldShowSelection(of: IndexPath(row: 1, section: 1)))
    }

    func testGetCellShouldShowSelection_forceOn_onlyRow1ReturnTrue() {
        stub.darkModeStatus = .forceOn

        XCTAssertTrue(sut.cellShouldShowSelection(of: IndexPath(row: 1, section: 0)))

        XCTAssertFalse(sut.cellShouldShowSelection(of: IndexPath(row: 0, section: 0)))
        XCTAssertFalse(sut.cellShouldShowSelection(of: IndexPath(row: 2, section: 0)))
        XCTAssertFalse(sut.cellShouldShowSelection(of: IndexPath(row: 3, section: 0)))
        XCTAssertFalse(sut.cellShouldShowSelection(of: IndexPath(row: 4, section: 0)))
        XCTAssertFalse(sut.cellShouldShowSelection(of: IndexPath(row: 1, section: 1)))
    }

    func testGetCellShouldShowSelection_followSystem_onlyRow2ReturnTrue() {
        stub.darkModeStatus = .forceOff

        XCTAssertTrue(sut.cellShouldShowSelection(of: IndexPath(row: 2, section: 0)))

        XCTAssertFalse(sut.cellShouldShowSelection(of: IndexPath(row: 0, section: 0)))
        XCTAssertFalse(sut.cellShouldShowSelection(of: IndexPath(row: 1, section: 0)))
        XCTAssertFalse(sut.cellShouldShowSelection(of: IndexPath(row: 3, section: 0)))
        XCTAssertFalse(sut.cellShouldShowSelection(of: IndexPath(row: 4, section: 0)))
        XCTAssertFalse(sut.cellShouldShowSelection(of: IndexPath(row: 1, section: 1)))
    }

    func testGetCellTitle() {
        XCTAssertEqual(sut.cellTitle(of: IndexPath(row: 0, section: 0)), DarkModeStatus.followSystem.titleOfSetting)
        XCTAssertEqual(sut.cellTitle(of: IndexPath(row: 1, section: 0)), DarkModeStatus.forceOn.titleOfSetting)
        XCTAssertEqual(sut.cellTitle(of: IndexPath(row: 2, section: 0)), DarkModeStatus.forceOff.titleOfSetting)

        XCTAssertNil(sut.cellTitle(of: IndexPath(row: 3, section: 0)))
        XCTAssertNil(sut.cellTitle(of: IndexPath(row: 1, section: 1)))
    }

    func testHeaderFooter() {
        let header = sut.sectionHeader(of: 0)
        XCTAssertEqual(header?.string, LocalString._settings_dark_mode_section_title)
        XCTAssertNil(sut.sectionFooter(of: 0))
    }
}
