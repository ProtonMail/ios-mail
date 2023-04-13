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

import ProtonCore_Networking
import ProtonCore_TestingToolkit
import XCTest
@testable import ProtonMail

final class DownloadPageOperationTests: XCTestCase {
    private var apiService: APIServiceMock!
    private var sut: DownloadPageOperation!
    private var queue: OperationQueue!
    private let labelID = LabelID("test")
    private let userID = UserID("userID")

    override func setUpWithError() throws {
        apiService = APIServiceMock()
        queue = OperationQueue()
    }

    override func tearDownWithError() throws {
        apiService = nil
        sut = nil
        queue = nil
    }

    func testOneOperation_callAPI_success() {
        testOnBackground { isFinish in
            let sut = self.makeOperation()
            self.apiService.requestJSONStub.bodyIs { _, _, path, reqParams, header, _, _, _, _, _, completion in
                do {
                    try self.verifyRequest(
                        path: path,
                        reqParams: reqParams as! [String : Any],
                        header: header!,
                        expectedEndTime: sut.endTime,
                        expectedPageSize: sut.pageSize
                    )
                    completion(nil, .success(self.makeSuccessResponse(isEmpty: false)))
                } catch {
                    XCTFail("\(error)")
                }
            }
            self.queue.addOperation(sut.operation)
            self.queue.waitUntilAllOperationsAreFinished()
            let result = try XCTUnwrap(sut.operation.result)
            switch result {
            case .failure:
                XCTFail("Unexpected")
            case .success(let esMessages):
                XCTAssertEqual(esMessages.count, 4)
                let times = esMessages.map { $0.time }
                for i in 1..<esMessages.count {
                    XCTAssertTrue(times[i - 1] >= times[i])
                }
            }
            isFinish.fulfill()
        }
    }

    func testOneOperation_callAPI_success_with_emptyMessages() {
        testOnBackground { isFinish in
            let sut = self.makeOperation()
            self.apiService.requestJSONStub.bodyIs { _, _, path, reqParams, header, _, _, _, _, _, completion in
                do {
                    try self.verifyRequest(
                        path: path,
                        reqParams: reqParams as! [String : Any],
                        header: header!,
                        expectedEndTime: sut.endTime,
                        expectedPageSize: sut.pageSize
                    )
                    completion(nil, .success(self.makeSuccessResponse(isEmpty: true)))
                } catch {
                    XCTFail("\(error)")
                }
            }
            self.queue.addOperation(sut.operation)
            self.queue.waitUntilAllOperationsAreFinished()
            let result = try XCTUnwrap(sut.operation.result)
            switch result {
            case .failure:
                XCTFail("Unexpected")
            case .success(let esMessages):
                XCTAssertEqual(esMessages.count, 0)
            }
            isFinish.fulfill()
        }
    }

    func testOneOperation_callAPI_failed() {
        testOnBackground { isFinish in
            let sut = self.makeOperation()
            self.apiService.requestJSONStub.bodyIs { _, _, path, reqParams, header, _, _, _, _, _, completion in
                do {
                    try self.verifyRequest(
                        path: path,
                        reqParams: reqParams as! [String : Any],
                        header: header!,
                        expectedEndTime: sut.endTime,
                        expectedPageSize: sut.pageSize
                    )
                    completion(nil, .failure(.badResponse()))
                } catch {
                    XCTFail("\(error)")
                }
            }
            self.queue.addOperation(sut.operation)
            self.queue.waitUntilAllOperationsAreFinished()
            let result = try XCTUnwrap(sut.operation.result)
            switch result {
            case .failure(let error):
                let responseError = try XCTUnwrap(error as? ResponseError)
                let underlyingError = try XCTUnwrap(responseError.underlyingError)
                // code of .badResponse()
                XCTAssertEqual(underlyingError.code, 4)
            case .success:
                XCTFail("Unexpected")
            }
            isFinish.fulfill()
        }
    }

    func testOneOperation_callAPI_got_unexpected_response() {
        testOnBackground { isFinish in
            let sut = self.makeOperation()
            self.apiService.requestJSONStub.bodyIs { _, _, path, reqParams, header, _, _, _, _, _, completion in
                do {
                    try self.verifyRequest(
                        path: path,
                        reqParams: reqParams as! [String : Any],
                        header: header!,
                        expectedEndTime: sut.endTime,
                        expectedPageSize: sut.pageSize
                    )
                    var response = self.makeSuccessResponse(isEmpty: false)
                    response["Messages"] = 3
                    completion(nil, .success(response))
                } catch {
                    XCTFail("\(error)")
                }
            }
            self.queue.addOperation(sut.operation)
            self.queue.waitUntilAllOperationsAreFinished()
            let result = try XCTUnwrap(sut.operation.result)
            switch result {
            case .failure(let error):
                // code of .unableToParseResponse
                XCTAssertEqual((error as NSError).code, 3)
            case .success:
                XCTFail("Unexpected")
            }
            isFinish.fulfill()
        }
    }

    func testSecondOperation_is_cancelled() {
        testOnBackground { isFinish in
            self.queue.maxConcurrentOperationCount = 1
            let suts = [self.makeOperation(), self.makeOperation()]
            self.apiService.requestJSONStub.bodyIs { callTime, _, path, reqParams, header, _, _, _, _, _, completion in
                if callTime == 1 {
                    completion(nil, .success(self.makeSuccessResponse(isEmpty: false)))
                } else {
                    self.queue.cancelAllOperations()
                }
            }
            for sut in suts {
                self.queue.addOperation(sut.operation)
            }
            self.queue.waitUntilAllOperationsAreFinished()
            XCTAssertFalse(suts[0].operation.isCancelled)
            XCTAssertNotNil(suts[0].operation.result)
            XCTAssertTrue(suts[1].operation.isCancelled)
            XCTAssertNil(suts[1].operation.result)
            isFinish.fulfill()
        }
    }
}

extension DownloadPageOperationTests {
    private func makeSuccessResponse(isEmpty: Bool) -> [String: Any] {
        var response = testFetchingMessagesDataInInbox.parseObjectAny()!
        if isEmpty {
            response["Messages"] = []
        }
        return response
    }

    private func verifyRequest(
        path: String,
        reqParams: [String: Any],
        header: [String: Any],
        expectedEndTime: Int,
        expectedPageSize: Int
    ) throws {
        guard path == "/mail/v4/messages" else {
            throw "Unexpected path"
        }
        let endTime = try XCTUnwrap(reqParams["End"] as? Int)
        XCTAssertEqual(endTime + 1, expectedEndTime)
        let pageSize = try XCTUnwrap(reqParams["PageSize"] as? Int)
        XCTAssertEqual(pageSize, expectedPageSize)
        let priority = try XCTUnwrap(header["priority"] as? String)
        XCTAssertEqual(priority, "u=7")
    }

    private func makeOperation() -> (endTime: Int, pageSize: Int, operation: DownloadPageOperation) {
        let endTime = Int.random(in: 3...100)
        let pageSize = Int.random(in: 50...80)
        let operation = DownloadPageOperation(
            apiService: apiService,
            endTime: endTime,
            labelID: labelID,
            pageSize: pageSize,
            userID: userID
        )
        return (endTime, pageSize, operation)
    }

    // To prevent queue.waitUntilAllOperationsAreFinished() block main thread
    private func testOnBackground(block: @escaping (XCTestExpectation) throws -> Void) {
        let isFinish = expectation(description: "Queue tasks are completed")
        DispatchQueue.global().async {
            do {
                try block(isFinish)
            } catch {
                XCTFail("Unexpected \(error)")
            }
        }
        wait(for: [isFinish], timeout: 5)
    }
}
