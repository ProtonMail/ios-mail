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
import ProtonCore_TestingToolkit

final class ConversationDataServiceTests: XCTestCase {

    var sut: ConversationDataService!
    var userID = UserID("user1")
    var mockApiService: APIServiceMock!
    var mockContextProvider: MockCoreDataContextProvider!
    var mockLastUpdatedStore: MockLastUpdatedStore!
    var mockEventsService: MockEventsService!
    var fakeUndoActionManager: UndoActionManagerProtocol!

    override func setUp() {
        super.setUp()
        mockApiService = APIServiceMock()
        mockContextProvider = MockCoreDataContextProvider()
        mockLastUpdatedStore = MockLastUpdatedStore()
        mockEventsService = MockEventsService()
        fakeUndoActionManager = UndoActionManager(apiService: mockApiService,
                                                  contextProvider: mockContextProvider,
                                                  getEventFetching: {return nil},
                                                  getUserManager: {return nil})
        sut = ConversationDataService(api: mockApiService,
                                      userID: userID,
                                      contextProvider: mockContextProvider,
                                      lastUpdatedStore: mockLastUpdatedStore,
                                      eventsService: mockEventsService,
                                      undoActionManager: fakeUndoActionManager)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockApiService = nil
        mockContextProvider = nil
        mockLastUpdatedStore = nil
        mockEventsService = nil
        fakeUndoActionManager = nil
    }

    func testFilterMessagesDictionary() {
        let input: [[String: Any]] = [
            [
                "ID": "1"
            ],
            [
                "ID": "2"
            ],
            [
                "ID": "3"
            ],
            [
                "ID": "1"
            ]
        ]
        let ids = ["1"]

        let result = sut.messages(among: input, notContaining: ids)

        XCTAssertEqual(result.count, 2)
        result.forEach { item in
            let id = item["ID"] as! String
            XCTAssertFalse(ids.contains(id))
        }
    }

    func testFetchSendingMessageIDs() {
        let msg1 = Message(context: mockContextProvider.mainContext)
        msg1.messageID = "1"
        msg1.userID = userID.rawValue

        let msg2 = Message(context: mockContextProvider.mainContext)
        msg2.messageID = "2"
        msg2.isSending = true
        msg2.userID = userID.rawValue

        let result = sut.fetchSendingMessageIDs(context: mockContextProvider.mainContext)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0], "2")
    }
}
