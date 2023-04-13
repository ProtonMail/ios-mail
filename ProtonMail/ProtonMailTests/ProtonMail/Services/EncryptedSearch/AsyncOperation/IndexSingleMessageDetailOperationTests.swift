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

final class IndexSingleMessageDetailOperationTests: XCTestCase {
    private var apiService: APIServiceMock!
    private var sut: IndexSingleMessageDetailOperation!
    private var queue: OperationQueue!
    private let userID = UserID("userID")

    override func setUpWithError() throws {
        apiService = APIServiceMock()
        queue = OperationQueue()
    }

    override func tearDownWithError() throws {
        apiService = nil
        queue.cancelAllOperations()
        queue = nil
        sut = nil
    }

    func testOneOperation_callAPI_and_parseResponse_success() {
        testOnBackground { isFinish in
            let order = Int.random(in: 0...99)
            let message = self.makeEsMessage(order: order)
            let messageID = "ESID-\(order)"
            self.apiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, completion in
                guard path == "/mail/v4/messages/\(messageID)" else {
                    XCTFail("Unknown path")
                    return
                }
                let response = self.makeResponse(messageID: messageID)
                completion(nil, .success(response))
            }
            let operation = IndexSingleMessageDetailOperation(apiService: self.apiService, message: message, userID: self.userID)
            self.queue.addOperation(operation)
            self.queue.waitUntilAllOperationsAreFinished()
            let result = try XCTUnwrap(operation.result)
            switch result {
            case .failure:
                XCTFail("Unexpected")
            case .success(let esMessage):
                do {
                    let isDownloaded = try XCTUnwrap(esMessage.isDetailsDownloaded)
                    let conversationID = "3Spjf96LXv8EDUylCxJkKsL7x9IgBac_0z416buSBBMwAkbh_dHh2Ng7O6ss70yhlaLBht0hiJqvqbxoBKtb9Q=="
                    XCTAssertTrue(isDownloaded)
                    XCTAssertEqual(esMessage.conversationID, conversationID)
                } catch {
                    XCTFail("Unexpected")
                }
            }
            isFinish.fulfill()
        }
    }

    func testOneOperation_message_has_downloaded() {
        testOnBackground { isFinish in
            let order = Int.random(in: 0...99)
            let message = self.makeEsMessage(order: order)
            message.isDetailsDownloaded = true
            self.apiService.requestJSONStub.bodyIs { _, _, _, _, _, _, _, _, _, _, _ in
                XCTFail("Shouldn't call API")
            }
            let operation = IndexSingleMessageDetailOperation(apiService: self.apiService, message: message, userID: self.userID)
            self.queue.addOperation(operation)
            self.queue.waitUntilAllOperationsAreFinished()
            let result = try XCTUnwrap(operation.result)
            switch result {
            case .failure:
                XCTFail("Unexpected")
            case .success(let esMessage):
                let conversationID = message.conversationID
                XCTAssertEqual(esMessage.subject, message.subject)
                XCTAssertEqual(esMessage.conversationID, conversationID)
            }
            isFinish.fulfill()
        }
    }

    func testOneOperation_callAPI_fail() {
        testOnBackground { isFinish in
            let order = Int.random(in: 0...99)
            let message = self.makeEsMessage(order: order)
            let messageID = "ESID-\(order)"
            self.apiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, completion in
                guard path == "/mail/v4/messages/\(messageID)" else {
                    XCTFail("Unknown path")
                    return
                }
                completion(self.makeFailResponse(canRetry: false), .failure(.badResponse()))
            }
            let operation = IndexSingleMessageDetailOperation(apiService: self.apiService, message: message, userID: self.userID)
            self.queue.addOperation(operation)
            self.queue.waitUntilAllOperationsAreFinished()
            let result = try XCTUnwrap(operation.result)
            switch result {
            case .failure(let error):
                do {
                    let responseError = try XCTUnwrap(error as? ResponseError)
                    let httpCode = try XCTUnwrap(responseError.httpCode)
                    XCTAssertEqual(httpCode, 400)
                    let underlyingError = try XCTUnwrap(responseError.underlyingError)
                    // Code of .badResponse()
                    XCTAssertEqual(underlyingError.code, 4)
                } catch {
                    XCTFail("Unexpected")
                }
            case .success:
                XCTFail("Unexpected")
            }
            isFinish.fulfill()
        }
    }

    func testSecondOperation_is_cancelled() {
        testOnBackground { isFinish in
            self.queue.maxConcurrentOperationCount = 1
            let messages = [self.makeEsMessage(order: 1), self.makeEsMessage(order: 2)]
            self.apiService.requestJSONStub.bodyIs { callTimes, _, path, _, _, _, _, _, _, _, completion in
                if callTimes == 1 {
                    completion(nil, .success(self.makeResponse(messageID: "test")))
                } else {
                    self.queue.cancelAllOperations()
                }
            }
            let operations = messages.map { IndexSingleMessageDetailOperation(apiService: self.apiService, message: $0, userID: self.userID) }
            operations.forEach { self.queue.addOperation($0) }

            self.queue.waitUntilAllOperationsAreFinished()
            XCTAssertFalse(operations[0].isCancelled)
            XCTAssertNotNil(operations[0].result)
            XCTAssertTrue(operations[1].isCancelled)
            XCTAssertNil(operations[1].result)
            isFinish.fulfill()
        }
    }
}

extension IndexSingleMessageDetailOperationTests {
    private func makeEsMessage(order: Int) -> ESMessage {
        ESMessage(
            id: "ESID-\(order)",
            order: order,
            conversationID: "conversationID",
            subject: String.randomString(4),
            unread: 0,
            type: 0,
            senderAddress: "sender address",
            senderName: "sender name",
            sender: .init(),
            toList: .init(),
            ccList: .init(),
            bccList: .init(),
            time: 123,
            size: 456,
            isEncrypted: 0,
            expirationTime: nil,
            isReplied: 0,
            isRepliedAll: 0,
            isForwarded: 0,
            spamScore: nil,
            addressID: nil,
            numAttachments: 0,
            flags: 0,
            labelIDs: [],
            externalID: nil,
            body: nil,
            header: nil,
            mimeType: nil,
            userID: userID.rawValue
        )
    }

    private func makeResponse(messageID: String) -> [String: Any] {
        var parsedObject = testMessageDetailData.parseObjectAny()!
        parsedObject["ID"] = messageID
        return ["Message": parsedObject]
    }

    private func makeFailResponse(canRetry: Bool) -> URLSessionDataTask {
        let statusCode = canRetry ? 429 : 400
        let header = canRetry ? ["retry-after": "3"] : [:]

        let response = HTTPURLResponse(
            url: URL(string: "http://api.test")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: header
        )
        return URLSessionDataTaskMock(response: response!)
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
