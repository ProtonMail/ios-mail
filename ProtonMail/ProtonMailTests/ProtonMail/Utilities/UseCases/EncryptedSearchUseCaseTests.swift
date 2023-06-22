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
import GoLibs
import XCTest

class EncryptedSearchUseCaseTests: XCTestCase {
    var sut: EncryptedSearch!

    var mockContextProvider: MockCoreDataContextProvider!
    var mockEncryptedService: MockEncryptedSearchServiceProtocol!
    var mockFetchMessageMetaData: MockFetchMessageMetaData!
    var mockMessageDataService: MockLocalMessageDataServiceProtocol!
    var fakeUserID: UserID!

    override func setUp() {
        super.setUp()
        mockContextProvider = .init()
        mockEncryptedService = .init()
        mockMessageDataService = .init()
        mockFetchMessageMetaData = .init()
        fakeUserID = .init(String.randomString(10))

        sut = .init(
            dependencies: .init(
                encryptedSearchService: mockEncryptedService,
                contextProvider: mockContextProvider,
                userID: fakeUserID,
                fetchMessageMetaData: mockFetchMessageMetaData,
                messageDataService: mockMessageDataService)
        )
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockContextProvider = nil
        mockEncryptedService = nil
        mockFetchMessageMetaData = nil
        mockMessageDataService = nil
        fakeUserID = nil
    }

    func testExecute_oneMsgInCacheAndOneInIndex_bothReturned() {
        let e = expectation(description: "Closure is called")
        let existingMsgID = MessageID(String.randomString(10))
        let remoteMsgID = MessageID(String.randomString(10))
        createTestDataAndStub_oneMsgInCache_oneIsNot(msgID: existingMsgID, remoteMsgID: remoteMsgID)

        sut.execute(
            params: .init(query: "test@pm.me", page: 0)
        ) { result in
            switch result {
            case .success(let msgs):
                XCTAssertEqual(msgs.count, 2)
                XCTAssertTrue(msgs.contains(where: { $0.messageID == existingMsgID }))
                XCTAssertTrue(msgs.contains(where: { $0.messageID == remoteMsgID }))
            case .failure:
                XCTFail("Should not reach here")
            }
            e.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(mockEncryptedService.searchStub.wasCalledExactlyOnce)
        XCTAssertEqual(mockMessageDataService.fetchMessagesStub.callCounter, 2)
    }

    func testExecute_emptyQuery_returnEmptyArray() {
        let e = expectation(description: "Closure is called")

        sut.execute(params: .init(query: "", page: 0)) { result in
            switch result {
            case .success(let msgs):
                XCTAssertTrue(msgs.isEmpty)
            case .failure:
                XCTFail("Should not reach here")
            }
            e.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(mockEncryptedService.searchStub.wasNotCalled)
        XCTAssertTrue(mockMessageDataService.fetchMessagesStub.wasNotCalled)
    }

    func testExecute_noIndexReturnFromSearchService_messageFetchIsNotCalled() {
        let e = expectation(description: "Closure is called")
        mockEncryptedService.searchStub.bodyIs { _, _, _, _, completion in
            completion(.success(.init(resultFromCache: [], resultFromIndex: [])))
        }

        sut.execute(params: .init(query: "test@pm.me", page: 0)) { result in
            switch result {
            case .success(let msgs):
                XCTAssertTrue(msgs.isEmpty)
            case .failure:
                XCTFail("Should not reach here")
            }
            e.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(mockEncryptedService.searchStub.wasCalledExactlyOnce)
        XCTAssertTrue(mockMessageDataService.fetchMessagesStub.wasNotCalled)
    }

    private func createTestDataAndStub_oneMsgInCache_oneIsNot(msgID: MessageID, remoteMsgID: MessageID) {
        mockMessageDataService.fetchMessagesStub.bodyIs { count, _, _ in
            var result: [Message] = []
            if count == 1 {
                self.mockContextProvider.performAndWaitOnRootSavingContext { context in
                    let existingMessage = Message(context: context)
                    existingMessage.messageID = msgID.rawValue
                    _ = context.saveUpstreamIfNeeded()
                    result.append(existingMessage)
                }
                return result
            } else {
                self.mockContextProvider.performAndWaitOnRootSavingContext { context in
                    let existingMessage = Message(context: context)
                    existingMessage.messageID = msgID.rawValue
                    let remoteMessage = Message(context: context)
                    remoteMessage.messageID = remoteMsgID.rawValue
                    _ = context.saveUpstreamIfNeeded()
                    result.append(existingMessage)
                    result.append(remoteMessage)
                }
                return result
            }
        }

        mockEncryptedService.searchStub.bodyIs { _, _, _, _, completion in
            let cacheResultList = GoLibsEncryptedSearchResultList()
            let cacheMsg = EncryptedsearchMessage(
                msgID.rawValue,
                timeValue: 0,
                orderValue: 0,
                labelidsValue: nil,
                encryptedValue: nil,
                decryptedValue: nil
            )
            let cacheResult = EncryptedsearchSearchResult(cacheMsg)
            cacheResultList?.add(cacheResult)

            let indexResultList = GoLibsEncryptedSearchResultList()
            let indexMsg = EncryptedsearchMessage(
                remoteMsgID.rawValue,
                timeValue: 0,
                orderValue: 0,
                labelidsValue: nil,
                encryptedValue: nil,
                decryptedValue: nil
            )
            let indexResult = EncryptedsearchSearchResult(indexMsg)
            indexResultList?.add(indexResult)

            if let indexResultList = indexResultList,
               let cacheResultList = cacheResultList {
                completion(.success(.init(resultFromCache: [cacheResultList],
                                          resultFromIndex: [indexResultList, cacheResultList])))
            } else {
                XCTFail("Something is wrong.")
            }
        }

    }
}
