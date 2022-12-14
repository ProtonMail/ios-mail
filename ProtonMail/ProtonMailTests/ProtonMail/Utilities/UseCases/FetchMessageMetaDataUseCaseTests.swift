// Copyright (c) 2022 Proton AG
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
import ProtonCore_Services
import ProtonCore_TestingToolkit

final class FetchMessageMetaDataUseCaseTests: XCTestCase {
    var sut: FetchMessageMetaDataUseCase!
    var messageDataService: MockMessageDataService!
    var contextProvider: MockCoreDataContextProvider!
    var queueManager: MockQueueManager!

    override func setUp() {
        self.contextProvider = MockCoreDataContextProvider()
        self.messageDataService = MockMessageDataService()
        self.queueManager = MockQueueManager()
        let dependencies = FetchMessageMetaData
            .Dependencies(messageDataService: self.messageDataService,
                          contextProvider: self.contextProvider,
                          queueManager: self.queueManager)
        let params = FetchMessageMetaData.Parameters(userID: "the userID")
        self.sut = FetchMessageMetaData(
            params: params,
            dependencies: dependencies)
    }

    override func tearDown() {
        super.tearDown()
        self.sut = nil
        self.messageDataService = nil
        self.contextProvider = nil
    }

    func testExecute_whenWePassNoMessageIDs() {
        let expectation = expectation(description: "callbacks are called")
        self.sut.execute(with: []) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
        XCTAssertEqual(self.queueManager.executeTimes, 0)
        XCTAssertEqual(self.messageDataService.callFetchMessageMetaData.callCounter,
                       0)
    }

    func testAPICallTimes_whenPass21MessageIDs() throws {
        let ids = Array(0...20).map { _ in MessageID(UUID().uuidString) }
        let expectation = expectation(description: "callbacks are called")

        self.sut.execute(with: ids) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
        let callFetchMessageMetaData = self.messageDataService.callFetchMessageMetaData
        XCTAssertEqual(self.queueManager.executeTimes, 1)
        // There are 21 IDs, the API should call twice
        XCTAssertEqual(callFetchMessageMetaData.callCounter, 2)
        let captured = callFetchMessageMetaData.capturedArguments

        var countOfIDs = 0
        var queryIDs: [MessageID] = []
        for index in captured.indices {
            let capturedData = try XCTUnwrap(captured[safe: index],
                                             "Should have value")
            capturedData.a1.forEach {
                XCTAssertTrue(ids.contains($0))
                queryIDs.append($0)
                countOfIDs += 1
            }
        }
        XCTAssertEqual(countOfIDs, ids.count)
        XCTAssertEqual(queryIDs.count, ids.count)
        XCTAssertEqual(Set(queryIDs).count, ids.count)
    }

    func testFetchMetaData_saveToDBSuccess() throws {
        let messageID = MessageID(UUID().uuidString)

        let expectation = expectation(description: "callbacks are called")

        self.sut.execute(with: [messageID]) { _ in
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5.0)
        XCTAssertEqual(self.queueManager.executeTimes, 1)
        XCTAssertEqual(self.messageDataService.callFetchMessageMetaData.callCounter,
                       1)

        let message = try XCTUnwrap(Message.messageForMessageID(messageID.rawValue, inManagedObjectContext: contextProvider.viewContext))
        XCTAssertEqual(message.userID, "the userID")
        XCTAssertEqual(message.messageStatus, NSNumber(1))
    }

    func testFetchMetaData_withInvalidAndDuplicatedMessageIDs() throws {
        let ids = Array(0...20).map { _ in MessageID(UUID().uuidString) }
        let invalids = Array(0...5).map { _ in MessageID("") }
        let idsToTest = ids + invalids + ids
        let expectation = expectation(description: "callbacks are called")

        self.sut.execute(with: idsToTest) { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
        let callFetchMessageMetaData = self.messageDataService.callFetchMessageMetaData
        XCTAssertEqual(self.queueManager.executeTimes, 1)
        // There are 47 IDs passed in, but it should only has 21 valid ids.
        // Therefore, the API should only call twice.
        XCTAssertEqual(callFetchMessageMetaData.callCounter, 2)
        let captured = callFetchMessageMetaData.capturedArguments

        var countOfIDs = 0
        var queryIDs: [MessageID] = []
        for index in captured.indices {
            let capturedData = try XCTUnwrap(captured[safe: index],
                                             "Should have value")
            capturedData.a1.forEach {
                XCTAssertTrue(ids.contains($0))
                queryIDs.append($0)
                countOfIDs += 1
            }
        }
        XCTAssertEqual(countOfIDs, ids.count)
        XCTAssertEqual(queryIDs.count, ids.count)
        XCTAssertEqual(Set(queryIDs).count, ids.count)
    }
}
