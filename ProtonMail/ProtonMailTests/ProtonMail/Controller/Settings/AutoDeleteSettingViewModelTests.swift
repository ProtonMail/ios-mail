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

import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail
import XCTest

final class AutoDeleteSettingViewModelTests: XCTestCase {
    var sut: AutoDeleteSettingViewModel!
    var mockAutoDeleteSpamAndTrashDaysProvider: MockAutoDeleteSpamAndTrashDaysProvider!
    var apiServiceMock: APIServiceMock!

    override func setUp() {
        super.setUp()
        mockAutoDeleteSpamAndTrashDaysProvider = .init()
        apiServiceMock = .init()
        sut = .init(mockAutoDeleteSpamAndTrashDaysProvider, apiService: apiServiceMock)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockAutoDeleteSpamAndTrashDaysProvider = nil
    }

    func testGetCellData_returnsCorrectStatus() {
        mockAutoDeleteSpamAndTrashDaysProvider.isAutoDeleteEnabledStub.fixture = Bool.random()

        let result = sut.cellData(for: IndexPath(row: 0, section: 0))

        XCTAssertEqual(result?.title, L10n.AutoDeleteSettings.rowTitle)
        XCTAssertEqual(result?.status, mockAutoDeleteSpamAndTrashDaysProvider.isAutoDeleteEnabled)
    }

    func testGetSectionFooterAndHeader() throws {
        let result = try XCTUnwrap(sut.sectionFooter(section: 0))
        switch result {
        case .left(let text):
            XCTAssertEqual(text, L10n.AutoDeleteSettings.rowFooterTitle)
        case .right:
            XCTFail("Shouldn't be an attributedString")
        }

        XCTAssertNil(sut.sectionHeader())
    }

    func testCallToggleToTrueWithNewStatus_statusWillBeChangedToTrue() throws {
        let e = expectation(description: "Closure is called")
        mockAutoDeleteSpamAndTrashDaysProvider.isAutoDeleteEnabledStub.fixture = false
        apiServiceMock.requestJSONStub.bodyIs { _, method, path, body, parameter, _, _, _, _, _, _, _, completion in
            XCTAssertEqual(method, .put)
            guard let dict = body as? [String: Any] else {
                XCTFail("Should contain a dictionary in body")
                fatalError()
            }
            guard let daysValue = dict["Days"] as? Int else {
                XCTFail("Should contain a `Days` key with an `Int` value")
                fatalError()
            }
            XCTAssertEqual(daysValue, 30)
            if path.contains("/auto-delete-spam-and-trash-days") {
                completion(nil, .success([:]))
            } else {
                XCTFail("Unexpected path")
            }
        }

        sut.toggle(for: IndexPath(row: 0, section: 0), to: true) { error in
            XCTAssertNil(error)
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        let newStatus = try XCTUnwrap(
            mockAutoDeleteSpamAndTrashDaysProvider.isAutoDeleteEnabledStub.setLastArguments?.a1
        )
        XCTAssertTrue(newStatus)
    }

    func testCallToggleToFalseWithNewStatus_statusWillBeChangedToFalse() throws {
        let e = expectation(description: "Closure is called")
        mockAutoDeleteSpamAndTrashDaysProvider.isAutoDeleteEnabledStub.fixture = true
        apiServiceMock.requestJSONStub.bodyIs { _, method, path, body, parameter, _, _, _, _, _, _, _, completion in
            XCTAssertEqual(method, .put)
            guard let dict = body as? [String: Any] else {
                XCTFail("Should contain a dictionary in body")
                fatalError()
            }
            guard let daysValue = dict["Days"] as? Int else {
                XCTFail("Should contain a `Days` key with an `Int` value")
                fatalError()
            }
            XCTAssertEqual(daysValue, 0)
            if path.contains("/auto-delete-spam-and-trash-days") {
                completion(nil, .success([:]))
            } else {
                XCTFail("Unexpected path")
            }
        }

        sut.toggle(for: IndexPath(row: 0, section: 0), to: false) { error in
            XCTAssertNil(error)
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        let newStatus = try XCTUnwrap(
            mockAutoDeleteSpamAndTrashDaysProvider.isAutoDeleteEnabledStub.setLastArguments?.a1
        )
        XCTAssertFalse(newStatus)
    }

    func testCallToggleWithNewStatus_apiFail_statusWillNotBeChanged() throws {
        let e = expectation(description: "Closure is called")
        let initialState = Bool.random()
        mockAutoDeleteSpamAndTrashDaysProvider.isAutoDeleteEnabledStub.fixture = initialState
        apiServiceMock.requestJSONStub.bodyIs { _, _, path, _, parameter, _, _, _, _, _, _, _, completion in
            completion(nil, .failure(.badResponse()))
        }

        sut.toggle(for: IndexPath(row: 0, section: 0), to: !initialState) { error in
            XCTAssertNotNil(error)
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertFalse(
            mockAutoDeleteSpamAndTrashDaysProvider.isAutoDeleteEnabledStub.setWasCalled
        )
    }
}
