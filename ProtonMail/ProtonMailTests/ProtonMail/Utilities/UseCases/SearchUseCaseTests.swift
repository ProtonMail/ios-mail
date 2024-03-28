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

@testable import ProtonMail
import XCTest

final class SearchUseCase: XCTestCase {
    private var sut: MessageSearch!
    private var mockBackendSearch: MockBackendSearchUseCase!

    override func setUp() {
        super.setUp()
        mockBackendSearch = .init()
        sut = .init(dependencies: .init(backendSearch: mockBackendSearch))
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockBackendSearch = nil
    }


    func testExecute_backendSearchIsUsed() {
        let e = expectation(description: "Closure is called")
        mockBackendSearch.executionBlockStub.bodyIs { _, _, callback in
            callback(.success([]))
        }

        let query = SearchMessageQuery(page: 0, keyword: "")
        sut.execute(
            params: .init(query: query)) { _ in
                e.fulfill()
            }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(mockBackendSearch.executionBlockStub.wasCalledExactlyOnce)
    }
}
