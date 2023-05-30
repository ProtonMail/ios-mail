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
    private var mockESDefaultCache: MockEncryptedSearchUserCache!
    private var mockBackendSearch: MockBackendSearchUseCase!
    private var mockEncryptedSearch: MockEncryptedSearchUseCase!
    private var mockESStateProvider: MockEncryptedSearchStateProvider!

    override func setUp() {
        super.setUp()
        mockESDefaultCache = .init()
        mockBackendSearch = .init()
        mockEncryptedSearch = .init()
        mockESStateProvider = .init()
        sut = .init(
            dependencies: .init(
                isESEnable: true,
                esDefaultCache: mockESDefaultCache,
                userID: "",
                backendSearch: mockBackendSearch,
                encryptedSearch: mockEncryptedSearch,
                esStateProvider: mockESStateProvider
            )
        )
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockESDefaultCache = nil
        mockBackendSearch = nil
        mockEncryptedSearch = nil
        mockESStateProvider = nil
    }


    func testExecute_ESLocalFeatureFlagDisabled_backendSearchIsUsed() {
        sut = .init(
            dependencies: .init(
                isESEnable: false,
                esDefaultCache: mockESDefaultCache,
                userID: "",
                backendSearch: mockBackendSearch,
                encryptedSearch: mockEncryptedSearch,
                esStateProvider: mockESStateProvider
            )
        )
        let e = expectation(description: "Closure is called")
        mockBackendSearch.executionBlockStub.bodyIs { _, _, callback in
            callback(.success([]))
        }

        sut.execute(
            params: .init(query: "", page: 0)) { _ in
                e.fulfill()
            }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(mockBackendSearch.executionBlockStub.wasCalledExactlyOnce)
        XCTAssertTrue(mockEncryptedSearch.executionBlockStub.wasNotCalled)
    }

    func testExecute_ESLocalFeatureFlagEnabled_ESUserSettingIsDisabled_backendSearchIsUsed() {
        let e = expectation(description: "Closure is called")
        mockBackendSearch.executionBlockStub.bodyIs { _, _, callback in
            callback(.success([]))
        }

        mockESDefaultCache.isEncryptedSearchOnStub.bodyIs { _, _ in
            false
        }

        sut.execute(
            params: .init(query: "", page: 0)
        ) { _ in
            e.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(mockBackendSearch.executionBlockStub.wasCalledExactlyOnce)
        XCTAssertTrue(mockEncryptedSearch.executionBlockStub.wasNotCalled)
    }

    func testExecute_ESLocalFeatureFlagEnabled_ESUserSettingEnabled_ESStateNotInExpectedState_backendSearchIsUsed() {
        let e = expectation(description: "Closure is called")
        mockBackendSearch.executionBlockStub.bodyIs { _, _, callback in
            callback(.success([]))
        }
        mockESDefaultCache.isEncryptedSearchOnStub.bodyIs { _, _ in
            true
        }
        mockESStateProvider.indexBuildingStateStub.bodyIs { _, _ in
            return .disabled
        }


        sut.execute(
            params: .init(query: "", page: 0)
        ) { _ in
            e.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(mockBackendSearch.executionBlockStub.wasCalledExactlyOnce)
        XCTAssertTrue(mockEncryptedSearch.executionBlockStub.wasNotCalled)
    }

    func testExecute_ESLocalFeatureFlagEnabled_ESUserSettingEnabled_ESStateInExpectedState_encryptedSearchIsUsed() {
        let e = expectation(description: "Closure is called")
        mockEncryptedSearch.executionBlockStub.bodyIs { _, _, callback in
            callback(.success([]))
        }
        mockESDefaultCache.isEncryptedSearchOnStub.bodyIs { _, _ in
            true
        }
        mockESStateProvider.indexBuildingStateStub.bodyIs { _, _ in
            let states: [EncryptedSearchIndexState] = [.complete, .partial]
            return states.randomElement() ?? .complete
        }


        sut.execute(
            params: .init(query: "", page: 0)
        ) { _ in
            e.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(mockBackendSearch.executionBlockStub.wasNotCalled)
        XCTAssertTrue(mockEncryptedSearch.executionBlockStub.wasCalledExactlyOnce)
    }
}
