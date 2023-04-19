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

import XCTest
import ProtonCore_TestingToolkit
@testable import ProtonMail

final class CountMessagesForLabelTests: XCTestCase {
    private var apiService: APIServiceMock!
    private var sut: CountMessagesForLabel!

    override func setUpWithError() throws {
        self.apiService = APIServiceMock()
        self.sut = CountMessagesForLabel(dependencies: .init(apiService: apiService))
    }

    override func tearDownWithError() throws {
        apiService = nil
        sut = nil
    }

    func testExecute_whenRequestSucceeds_itReturnsTheMessageCount() throws {
        let labelIDValue = String.randomString(6)
        let unreadValue = false
        let total = Int.random(in: 1...99)
        apiService.requestJSONStub.bodyIs { _, _, path, reqParams, _, _, _, _, _, _, handler in
            if path == "/mail/v4/messages/count" {
                handler(nil, .success(self.response(labelID: labelIDValue, total: total, unread: 4)))
            } else {
                XCTFail("Unhandled path \(path)")
            }
        }
        let expectation1 = expectation(description: "Get result")
        sut.executionBlock(params: .init(
            labelID: LabelID(labelIDValue),
            isUnread: unreadValue
        )) { result in
            switch result {
            case .failure:
                XCTFail("Should not fail")
            case .success(let count):
                XCTAssertEqual(count, total)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 5)
    }

    func testExecute_whenRequestSucceeds_itDidNotReturnsTheMessageCount() {
        apiService.requestJSONStub.bodyIs { _, _, path, reqParams, b, _, _, _, _, _, handler in
            if path == "/mail/v4/messages/count" {
                handler(nil, .success(self.response(labelID: "bbb", total: 8, unread: 3)))
            } else {
                XCTFail("Unhandled path \(path)")
            }
        }
        let expectation1 = expectation(description: "Get result")
        sut.executionBlock(params: .init(
            labelID: LabelID("aaa"),
            isUnread: true
        )) { result in
            switch result {
            case .failure(let error):
                let nsError = error as NSError
                XCTAssertEqual(nsError.localizedFailureReason, "Unable to parse the response object:\nDoesn\'t include target labelID")
            case .success:
                XCTFail("Should fail")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 5)
    }

    func testExecute_whenRequestFailed_itReturnsError() throws {
        apiService.requestJSONStub.bodyIs { _, _, path, reqParams, b, _, _, _, _, _, handler in
            if path == "/mail/v4/messages/count" {
                handler(nil, .failure(.badResponse()))
            } else {
                XCTFail("Unhandled path \(path)")
            }
        }
        let expectation1 = expectation(description: "Get result")
        sut.executionBlock(params: .init(
            labelID: LabelID("aaa"),
            isUnread: true
        )) { result in
            switch result {
            case .failure:
                break
            case .success:
                XCTFail("Should fail")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 5)
    }

    private func response(labelID: String, total: Int, unread: Int) -> [String: Any] {
        [
            "Code": 1000,
            "Counts": [
                [
                    "LabelID": labelID,
                    "Total": total,
                    "Unread": unread
                ]
            ]
        ]
    }
}
