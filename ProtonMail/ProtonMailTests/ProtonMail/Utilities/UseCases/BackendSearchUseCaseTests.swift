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

import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail
import XCTest

class BackendSearchUseCaseTests: XCTestCase {
    var sut: BackendSearchUseCase!
    var apiMock: APIServiceMock!
    var contextProviderMock: MockCoreDataContextProvider!
    var userID = UserID(String.randomString(20))

    override func setUp() {
        super.setUp()
        apiMock = APIServiceMock()
        contextProviderMock = .init()
        sut = BackendSearch(dependencies: .init(
            apiService: apiMock,
            contextProvider: contextProviderMock,
            userID: userID)
        )
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        apiMock = nil
        contextProviderMock = nil
    }

    func testExecute_withApiError_errorIsReturned() {
        let keyword = "test@pm.me"
        apiMock.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, _, completion in
            if path.contains(check: "/messages") {
                completion(nil, .failure(.badResponse()))
            }
        }
        let e = expectation(description: "Closure is called")
        let query = SearchMessageQuery(page: 0, keyword: keyword)
        sut.execute(params: .init(query: query)) { result in
            switch result {
            case .failure:
                break
            case .success:
                XCTFail("Should not reach here")
            }
            e.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testExecute_withOneMessageInResponse_dataIsSavedInsideDB() throws {
        let e = expectation(description: "Closure is called")
        let keyword = "test@pm.me"
        let msgID = String.randomString(20)
        apiMock.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, _, completion in
            if path.contains(check: "/messages") {
                let rawTestMsg = MessageTestData.messageMetaData(
                    sender: "self@pm.me",
                    recipient: keyword,
                    messageID: msgID
                )
                let response: [String: Any] = [
                    "Code": 1000,
                    "Total": 1,
                    "Limit": 1,
                    "Messages": [
                        rawTestMsg.parseObjectAny()
                    ]
                ]
                completion(nil, .success(response))
            }
        }

        var messagesResult: [MessageEntity] = []
        let query = SearchMessageQuery(page: 0, keyword: keyword)
        sut.execute(params: .init(query: query)) { result in
            switch result {
            case .failure:
                XCTFail("Should not reach here")
            case .success(let messages):
                XCTAssertTrue(!messages.isEmpty)
                messagesResult = messages
            }
            e.fulfill()
        }

        waitForExpectations(timeout: 1)

        let msg = try XCTUnwrap(messagesResult.first)

        XCTAssertEqual(msg.userID, userID)
        XCTAssertEqual(msg.messageID.rawValue, msgID)
    }
}
