// Copyright (c) 2022 Proton Technologies AG
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

final class UndoSendViewModelTests: XCTestCase {
    private var sut: UndoSendSettingViewModel!
    private var user: UserManager!
    private var apiService: APIServiceMock!
    private var uiMock: SettingsSingleCheckMarkUIMock!

    override func setUpWithError() throws {
        apiService = APIServiceMock()
        user = UserManager(api: apiService, role: .member)
        sut = UndoSendSettingViewModel(user: user, delaySeconds: 0)
        uiMock = SettingsSingleCheckMarkUIMock()
        sut.set(uiDelegate: uiMock)
    }

    override func tearDownWithError() throws {
        apiService = nil
        user = nil
        sut = nil
        uiMock = nil
    }

    func testHeaderFooter() throws {
        XCTAssertNil(sut.sectionHeader(of: 0))
        XCTAssertEqual(sut.sectionFooter(of: 0)?.string, LocalString._undo_send_description)
    }

    func testCellTitle() throws {
        let expected = ["Disabled", "5 seconds", "10 seconds", "20 seconds"]
        for i in 0...6 {
            let indexPath = IndexPath(row: i, section: 0)
            let title = sut.cellTitle(of: indexPath)
            XCTAssertEqual(title, expected[safe: i])
        }
    }

    func testShouldShowSelection_only_row0_return_true() {
        XCTAssertTrue(sut.cellShouldShowSelection(of: IndexPath(row: 0, section: 0)))
        XCTAssertFalse(sut.cellShouldShowSelection(of: IndexPath(row: 1, section: 0)))
        XCTAssertFalse(sut.cellShouldShowSelection(of: IndexPath(row: 2, section: 0)))
        XCTAssertFalse(sut.cellShouldShowSelection(of: IndexPath(row: 3, section: 0)))
        XCTAssertFalse(sut.cellShouldShowSelection(of: IndexPath(row: 4, section: 0)))
    }

    func testSelectItem_choose_same_item() {
        sut.selectItem(indexPath: IndexPath(row: 0, section: 0))
        XCTAssertEqual(uiMock.loadingStatus, [])
    }

    func testSelectItem_success() {
        let expectation = expectation(description: "get server response")
        apiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, completion in
            guard path == "/mail/v4/settings/delaysend" else {
                XCTFail("Wrong path")
                return
            }
            completion(nil, .success([:]))
            DispatchQueue.global().asyncAfter(deadline: .now()+2) {
                expectation.fulfill()
            }
        }
        sut.selectItem(indexPath: IndexPath(row: 1, section: 0))
        wait(for: [expectation], timeout: 3)
        XCTAssertTrue(sut.cellShouldShowSelection(of: IndexPath(row: 1, section: 0)))
        XCTAssertEqual(uiMock.error, "")
        XCTAssertEqual(uiMock.reloadTableCount, 1)
        XCTAssertEqual(uiMock.loadingStatus, [true, false])
    }

    func testSelectItem_failed() {
        let expectation = expectation(description: "get server response")
        apiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, completion in
            guard path == "/mail/v4/settings/delaysend" else {
                XCTFail("Wrong path")
                return
            }
            completion(nil, .failure(.badResponse()))
            DispatchQueue.global().asyncAfter(deadline: .now()+2) {
                expectation.fulfill()
            }
        }
        sut.selectItem(indexPath: IndexPath(row: 1, section: 0))
        wait(for: [expectation], timeout: 3)
        XCTAssertTrue(sut.cellShouldShowSelection(of: IndexPath(row: 0, section: 0)))
        XCTAssertEqual(uiMock.error, LocalString._error_bad_response_title)
        XCTAssertEqual(uiMock.reloadTableCount, 0)
        XCTAssertEqual(uiMock.loadingStatus, [true, false])
    }
}
