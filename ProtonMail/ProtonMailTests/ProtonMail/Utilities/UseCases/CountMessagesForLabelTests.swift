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
        let unreadValue = true
        let endTimeValue = Int.random(in: 1...99)
        let total = Int.random(in: 1...99)
        apiService.requestJSONStub.bodyIs { _, _, path, reqParams, _, _, _, _, _, _, handler in
            if path == "/mail/v4/messages" {
                guard
                    let paramsDict = reqParams as? [String: Any],
                    let label = paramsDict["LabelID"] as? String,
                    let unread = paramsDict["Unread"] as? Int,
                    let end = paramsDict["End"] as? Int
                else {
                    XCTFail("Parse reqParams failed")
                    return
                }
                XCTAssertEqual(label, labelIDValue)
                XCTAssertEqual(unread, unreadValue ? 1 : 0)
                XCTAssertEqual(end, endTimeValue - 1)
                handler(nil, .success(["Total": total]))
            } else {
                XCTFail("Unhandled path \(path)")
            }
        }
        let expectation1 = expectation(description: "Get result")
        sut.executionBlock(params: .init(
            labelID: LabelID(labelIDValue),
            endTime: endTimeValue,
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
            if path == "/mail/v4/messages" {
                handler(nil, .success([:]))
            } else {
                XCTFail("Unhandled path \(path)")
            }
        }
        let expectation1 = expectation(description: "Get result")
        sut.executionBlock(params: .init(
            labelID: LabelID("aaa"),
            endTime: 3,
            isUnread: true
        )) { result in
            switch result {
            case .failure(let error):
                guard let _ = error as? DecodingError else {
                    XCTFail("Error type is not expected, please check it")
                    return
                }
            case .success:
                XCTFail("Should fail")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 5)
    }

    func testExecute_whenRequestFailed_itReturnsError() throws {
        apiService.requestJSONStub.bodyIs { _, _, path, reqParams, b, _, _, _, _, _, handler in
            if path == "/mail/v4/messages" {
                handler(nil, .failure(.badResponse()))
            } else {
                XCTFail("Unhandled path \(path)")
            }
        }
        let expectation1 = expectation(description: "Get result")
        sut.executionBlock(params: .init(
            labelID: LabelID("aaa"),
            endTime: 3,
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

}
