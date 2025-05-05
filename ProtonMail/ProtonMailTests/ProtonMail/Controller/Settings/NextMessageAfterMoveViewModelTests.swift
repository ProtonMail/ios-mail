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

final class NextMessageAfterMoveViewModelTests: XCTestCase {
    var sut: NextMessageAfterMoveViewModel!
    var mockNextMessageAfterMoveStatusProvider: MockNextMessageAfterMoveStatusProvider!
    var apiServiceMock: APIServiceMock!

    override func setUp() {
        super.setUp()
        mockNextMessageAfterMoveStatusProvider = .init()
        apiServiceMock = .init()
        sut = .init(mockNextMessageAfterMoveStatusProvider, apiService: apiServiceMock)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockNextMessageAfterMoveStatusProvider = nil
    }

    func testGetCellData_returnsCorrectStatue() {
        mockNextMessageAfterMoveStatusProvider.shouldMoveToNextMessageAfterMoveStub.fixture = Bool.random()

        let result = sut.cellData(for: IndexPath(row: 0, section: 0))

        XCTAssertEqual(result?.title, L10n.NextMsgAfterMove.rowTitle)
        XCTAssertEqual(result?.status, mockNextMessageAfterMoveStatusProvider.shouldMoveToNextMessageAfterMove)
    }

    func testGetSectionFooterAndHeader() throws {
        let result = try XCTUnwrap(sut.sectionFooter(section: 0))
        switch result {
        case .left(let text):
            XCTAssertEqual(text, L10n.NextMsgAfterMove.rowFooterTitle)
        case .right:
            XCTFail("Shouldn't be an attributedString")
        }



        XCTAssertNil(sut.sectionHeader())
    }

    func testCallToggleWithNewStatus_statusWillBeChangedToFalse() throws {
        let e = expectation(description: "Closure is called")
        mockNextMessageAfterMoveStatusProvider.shouldMoveToNextMessageAfterMoveStub.fixture = true
        apiServiceMock.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, _, completion in
            if path.contains("/next-message-on-move") {
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
            mockNextMessageAfterMoveStatusProvider.shouldMoveToNextMessageAfterMoveStub.setLastArguments?.a1
        )
        XCTAssertFalse(newStatus)
    }

    func testCallToggleWithNewStatus_apiFail_statusBillNotBeChanged() throws {
        let e = expectation(description: "Closure is called")
        mockNextMessageAfterMoveStatusProvider.shouldMoveToNextMessageAfterMoveStub.fixture = true
        apiServiceMock.requestJSONStub.bodyIs { _, _, _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .failure(.badResponse()))
        }

        sut.toggle(for: IndexPath(row: 0, section: 0), to: false) { error in
            XCTAssertNotNil(error)
            e.fulfill()
        }
        waitForExpectations(timeout: 1)
        
        XCTAssertFalse(
            mockNextMessageAfterMoveStatusProvider.shouldMoveToNextMessageAfterMoveStub.setWasCalled
        )
    }
}
