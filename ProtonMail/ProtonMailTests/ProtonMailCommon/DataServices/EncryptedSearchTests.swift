// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
import Crypto
import SQLite
import CoreData
import Groot

import ProtonCore_Doh
import ProtonCore_Services
import ProtonCore_Networking
import ProtonCore_DataModel

@testable import ProtonMail
import BackgroundTasks

class EncryptedSearchTests: XCTestCase {
    var testUserID: String!
    var testMessageID: String!
    var testSearchIndexDBName: String!
    var connectionToSearchIndexDB: Connection!

    var coreDataService: CoreDataService!
    var user: UserManager!
    var testContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        self.testUserID = self.setUpTestUser()!
        self.testMessageID = "uniqueID1"

        // Create a test search index for user 'test'
        self.createTestSearchIndexDB()
        let doesTestIndexExist: Bool = EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: self.testUserID)
        print("Test database created: \(doesTestIndexExist)")
        let numberOfEntries = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: self.testUserID)
        print("Entries in db: \(numberOfEntries)")
        
        // Set up core data to create some test messages
        try self.setupCoreData()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

        // Delete test search index for user 'test'
        let doesTestIndexExist: Bool = EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: self.testUserID)
        if doesTestIndexExist {
            try self.deleteTestSearchIndexDB()  // delete test index if it exists
        }

        // Reset some values in EncryptedSearchService Singleton
        EncryptedSearchService.shared.pauseIndexingDueToOverheating = false
        EncryptedSearchService.shared.pauseIndexingDueToLowBattery = false
        EncryptedSearchService.shared.pauseIndexingDueToWiFiNotDetected = false
        EncryptedSearchService.shared.pauseIndexingDueToNetworkConnectivityIssues = false

        // Delete core data
        self.deleteCoreData()
    }

    private func setUpTestUser() -> String? {
        let users: UsersManager = sharedServices.get(by: UsersManager.self)
        let testUserInfo = UserInfo(displayName: "test display name", maxSpace: 42, notificationEmail: "test notification name",signature: "test signature", usedSpace: 123, userAddresses: [], autoSC: 321, language: "DE", maxUpload: 234, notify: 2345, showImage: 645, swipeL: 3452, swipeR: 4132, role: 1234, delinquent: 4123, keys: [], userId: "test", sign: 1234, attachPublicKey: 5467, linkConfirmation: "test link confirmation", credit: 098, currency: "BOL", pwdMode: 667, twoFA: 776, enableFolderColor: 77, inheritParentFolderColor: 88, subscribed: 12, groupingMode: 1, weekStart: 0)
        let testAuth = AuthCredential(sessionID: "test session id", accessToken: "test access token", refreshToken: "test refresh token",expiration: .distantFuture, userName: "test user name", userID: "test", privateKey: "test private key", passwordKeySalt: "test password key salt")
        let apiService = PMAPIService(doh: users.doh, sessionUID: "test session id")
        self.user = UserManager(api: apiService, userinfo: testUserInfo, auth: testAuth, parent: users)
        users.users.append(self.user)
        return users.firstUser?.userInfo.userId
    }

    private func createTestSearchIndexDB() {
        EncryptedSearchService.shared.setESState(userID: self.testUserID, indexingState: .downloading)
        userCachedStatus.isEncryptedSearchOn = true
        self.testSearchIndexDBName = EncryptedSearchIndexService.shared.getSearchIndexName(self.testUserID)
        self.connectionToSearchIndexDB = EncryptedSearchIndexService.shared.connectToSearchIndex(for: self.testUserID)!
        EncryptedSearchIndexService.shared.createSearchIndexTable(using: self.connectionToSearchIndexDB)

        let testMessage: ESMessage = ESMessage(id: self.testMessageID, order: 1, conversationID: "", subject: "subject", unread: 1, type: 1, senderAddress: "sender", senderName: "sender", sender: ESSender(Name: "sender", Address: "address"), toList: [], ccList: [], bccList: [], time: 1637058775, size: 5, isEncrypted: 1, expirationTime: Date(), isReplied: 0, isRepliedAll: 0, isForwarded: 0, spamScore: 0, addressID: "", numAttachments: 0, flags: 0, labelIDs: ["5", "1"], externalID: "", body: "hello", header: "", mimeType: "", userID: self.testUserID)
        let testMessageSecond: ESMessage = ESMessage(id: "uniqueID2", order: 2, conversationID: "", subject: "subject", unread: 1, type: 1, senderAddress: "sender", senderName: "sender", sender: ESSender(Name: "sender", Address: "address"), toList: [], ccList: [], bccList: [], time: 1637141557, size: 5, isEncrypted: 1, expirationTime: Date(), isReplied: 0, isRepliedAll: 0, isForwarded: 0, spamScore: 0, addressID: "", numAttachments: 0, flags: 0, labelIDs: ["5", "1"], externalID: "", body: "hello2", header: "", mimeType: "", userID: self.testUserID)
        let encryptedContent: EncryptedsearchEncryptedMessageContent? = EncryptedSearchService.shared.createEncryptedContent(message: testMessage, cleanedBody: "hello", userID: self.testUserID)
        let encryptedContent2: EncryptedsearchEncryptedMessageContent? = EncryptedSearchService.shared.createEncryptedContent(message: testMessageSecond, cleanedBody: "hello2", userID: self.testUserID)
        EncryptedSearchService.shared.addMessageToSearchIndex(userID: testUserID, message: testMessage, encryptedContent: encryptedContent, completionHandler: {})
        EncryptedSearchService.shared.addMessageToSearchIndex(userID: testUserID, message: testMessageSecond, encryptedContent: encryptedContent2, completionHandler: {})
    }

    private func setupCoreData() throws {
        coreDataService = CoreDataService(container: CoreDataStore.shared.memoryPersistentContainer)
        testContext = coreDataService.rootSavingContext

        let parsedLabel = testLabelsData.parseJson()!
        _ = try GRTJSONSerialization.objects(withEntityName: Label.Attributes.entityName,
                                             fromJSONArray: parsedLabel,
                                             in: testContext)

        try testContext.save()
    }

    private func deleteCoreData() {
        coreDataService = nil
        testContext = nil
    }

    private func deleteTestSearchIndexDB() throws {
        // Create the path to the database for user 'test'.
        let pathToTestDB: String = EncryptedSearchIndexService.shared.getSearchIndexPathToDB(self.testSearchIndexDBName)
        let urlToDB: URL? = URL(string: pathToTestDB)

        // Tear down search index db
        sqlite3_close(self.connectionToSearchIndexDB.handle)
        self.connectionToSearchIndexDB = nil

        // Remove the database file.
        try FileManager.default.removeItem(atPath: urlToDB!.path)
    }

    private func makeTestMessageIn(_ labelId: String) -> Message? {
        let parsedObject = testMessageMetaData.parseObjectAny()!
        let message = try? GRTJSONSerialization
            .object(withEntityName: Message.Attributes.entityName,
                    fromJSONDictionary: parsedObject,
                    in: testContext) as? Message
        message?.remove(labelID: "0")
        message?.add(labelID: labelId)
        try? testContext.save()
        return message
    }

    func testEncryptedSearchServiceSingleton() throws {
        XCTAssertNotNil(EncryptedSearchService.shared)
    }

    func testPauseIndexingByUser() throws {
        let sut = EncryptedSearchService.shared.pauseAndResumeIndexingByUser

        sut(true, self.testUserID)
        // Wait for 2 seconds - as pausing is async
        _ = XCTWaiter.wait(for: [expectation(description: "Wait for n seconds")], timeout: 2.0)

        XCTAssertEqual(EncryptedSearchService.shared.getESState(userID: self.testUserID), EncryptedSearchService.EncryptedSearchIndexState.paused)
    }

    /* func testResumeIndexingByUser() throws {
        let sut = EncryptedSearchService.shared.pauseAndResumeIndexingByUser

        // Test resume
        sut(false, self.testUserID)
        XCTAssertEqual(EncryptedSearchService.shared.state, EncryptedSearchService.EncryptedSearchIndexState.downloading)
        XCTAssertEqual(EncryptedSearchService.shared.numPauses, 0)
    } */

    func testPauseIndexingDueToLowBattery() throws {
        let sut = EncryptedSearchService.shared.pauseAndResumeIndexingDueToInterruption

        // Test interruption low battery
        EncryptedSearchService.shared.pauseIndexingDueToLowBattery = true
        sut(true, self.testUserID)
        XCTAssertEqual(EncryptedSearchService.shared.getESState(userID: self.testUserID), EncryptedSearchService.EncryptedSearchIndexState.paused)
    }

    func testPauseIndexingDueToOverheating() throws {
        let sut = EncryptedSearchService.shared.pauseAndResumeIndexingDueToInterruption

        // Test interruption low battery
        EncryptedSearchService.shared.pauseIndexingDueToOverheating = true
        sut(true, self.testUserID)
        XCTAssertEqual(EncryptedSearchService.shared.getESState(userID: self.testUserID), EncryptedSearchService.EncryptedSearchIndexState.paused)
    }

    func testPauseIndexingDueToLowStorage() throws {
        let sut = EncryptedSearchService.shared.pauseAndResumeIndexingDueToInterruption

        // Test interruption low battery
        EncryptedSearchService.shared.setESState(userID: self.testUserID, indexingState: EncryptedSearchService.EncryptedSearchIndexState.lowstorage)
        sut(true, self.testUserID)
        XCTAssertEqual(EncryptedSearchService.shared.getESState(userID: self.testUserID), EncryptedSearchService.EncryptedSearchIndexState.lowstorage)
    }

    func testPauseIndexingDueToWiFiNotDetected() throws {
        let sut = EncryptedSearchService.shared.pauseAndResumeIndexingDueToInterruption

        // Test interruption low battery
        EncryptedSearchService.shared.pauseIndexingDueToWiFiNotDetected = true
        sut(true, self.testUserID)
        XCTAssertEqual(EncryptedSearchService.shared.getESState(userID: self.testUserID), EncryptedSearchService.EncryptedSearchIndexState.paused)
    }

    func testPauseIndexingDueToNetworkConnectivityIssues() throws {
        let sut = EncryptedSearchService.shared.pauseAndResumeIndexingDueToInterruption

        // Test interruption low battery
        EncryptedSearchService.shared.pauseIndexingDueToNetworkConnectivityIssues = true
        sut(true, self.testUserID)
        XCTAssertEqual(EncryptedSearchService.shared.getESState(userID: self.testUserID), EncryptedSearchService.EncryptedSearchIndexState.paused)
    }

    // Backend returns 401 - unautorized access for test user account when fetching a message
    /* func testUpdateSearchIndexInsert() throws {
        let sut = EncryptedSearchService.shared.updateSearchIndex
        
        EncryptedSearchService.shared.state = .complete
        let action: NSFetchedResultsChangeType = .insert
        let message = try XCTUnwrap(makeTestMessageIn(Message.Location.allmail.rawValue))

        // Create an expactation
        let expectation = self.expectation(description: "Number of entries in search index")

        // Run insert - async
        sut(action, message)

        // Wait for the message to be inserted
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            print("insert successfull?")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
        print("check number of messages")
        let numberOfMessagesInSearchIndex: Int = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: self.testUserID)
        XCTAssertEqual(numberOfMessagesInSearchIndex, 3)
    } */

    // TODO
    /* func testUpdateSearchIndexDelete() throws {
        let sut = EncryptedSearchService.shared.updateSearchIndex

        // Create an expectation
        let expectation = self.expectation(description: "Number of entries in search index")

        // Create some test parameters
        let action: NSFetchedResultsChangeType = .delete
        let message = try XCTUnwrap(makeTestMessageIn(Message.Location.trash.rawValue))
        message.messageID = self.testMessageID

        // Run test
        sut(action, message, self.testUserID) {
            expectation.fulfill()
        }

        // Wait for the expectation to fulfill
        waitForExpectations(timeout: 5, handler: nil)

        // Check number of message in index
        let numberOfMessagesInSearchIndex: Int = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: self.testUserID)
        XCTAssertEqual(numberOfMessagesInSearchIndex, 1)
    } */

    // Private function
    /* func testProcessEventsAfterIndexingNoEvents() throws {
        let sut = EncryptedSearchService.shared.processEventsAfterIndexing
        
        // No events while indexing
        sut(){}
        let numberOfMessagesInSearchIndex: Int = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: self.testUserID)
        XCTAssertEqual(numberOfMessagesInSearchIndex, 2)
    } */

    // Private function
    /* func testProcessEventsAfterIndexingInsertEvent() throws {
        let sut = EncryptedSearchService.shared.processEventsAfterIndexing

        // Add an insert event while indexing
        EncryptedSearchService.shared.indexBuildingInProgress = true
        let message = try XCTUnwrap(makeTestMessageIn(Message.Location.allmail.rawValue))
        EncryptedSearchService.shared.updateSearchIndex(NSFetchedResultsChangeType.insert, message)
        let message2 = try XCTUnwrap(makeTestMessageIn(Message.Location.trash.rawValue))
        EncryptedSearchService.shared.updateSearchIndex(NSFetchedResultsChangeType.insert, message2)
        let message3 = try XCTUnwrap(makeTestMessageIn(Message.Location.sent.rawValue))
        EncryptedSearchService.shared.updateSearchIndex(NSFetchedResultsChangeType.insert, message3)

        // Test process events - with above insert
        EncryptedSearchService.shared.indexBuildingInProgress = false
        sut(){}
        // Wait for the message to be inserted
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let numberOfMessagesInSearchIndex: Int = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: self.testUserID)
            XCTAssertEqual(numberOfMessagesInSearchIndex, 5)
        }
    } */

    // Backend returns 401 - unautorized access for test user account when fetching a message
    /* func testInsertSingleMessageToSearchIndex() throws {
        let sut = EncryptedSearchService.shared.insertSingleMessageToSearchIndex

        // Create an expactation
        let expectation = self.expectation(description: "Number of entries in search index")

        // Create some test parameters
        let message = try XCTUnwrap(makeTestMessageIn(Message.Location.allmail.rawValue))

        // Run insert
        sut(message, self.testUserID) {
            expectation.fulfill()
        }

        // Wait for the expectation to fulfill
        waitForExpectations(timeout: 5, handler: nil)

        // Check number of message in index
        let numberOfMessagesInSearchIndex: Int = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: self.testUserID)
        XCTAssertEqual(numberOfMessagesInSearchIndex, 3)
    } */

    // TODO
    /* func testDeleteMessageFromSearchIndex() throws {
        let sut = EncryptedSearchService.shared.deleteMessageFromSearchIndex

        // Create an expectation
        let expectation = self.expectation(description: "Number of entries in search index")

        // Create some test parameters
        let message = try XCTUnwrap(makeTestMessageIn(Message.Location.allmail.rawValue))
        message.messageID = self.testMessageID

        // Run delete
        sut(message, self.testUserID) {
            expectation.fulfill()
        }

        // Wait for the expectation to fulfill
        waitForExpectations(timeout: 5, handler: nil)

        // Check number of message in index
        let numberOfMessagesInSearchIndex: Int = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: self.testUserID)
        XCTAssertEqual(numberOfMessagesInSearchIndex, 1)
    } */

    func testDeleteSearchIndex() throws {
        let sut = EncryptedSearchService.shared.deleteSearchIndex
        sut(self.testUserID, {})

        // Wait for 2 seconds - as deleting the search index is async
        _ = XCTWaiter.wait(for: [expectation(description: "Wait for n seconds")], timeout: 2.0)
        XCTAssertEqual(EncryptedSearchService.shared.getESState(userID: self.testUserID), EncryptedSearchService.EncryptedSearchIndexState.disabled)
        XCTAssertFalse(EncryptedSearchIndexService.shared.checkIfSearchIndexExists(for: self.testUserID))
    }

    func testConvertMessageToESMessage() throws {
        let sut = EncryptedSearchService.shared.convertMessageToESMessage
        let message: Message = try XCTUnwrap(makeTestMessageIn(Message.Location.allmail.rawValue))
        let result: ESMessage = sut(message)

        XCTAssertEqual(result.ID, message.messageID)
        XCTAssertEqual(result.Order, Int(truncating: message.order))
        
        XCTAssertEqual(result.ConversationID, message.conversationID)
        XCTAssertEqual(result.Subject, message.subject)
        XCTAssertEqual(result.Unread, message.unRead ? 1:0)
        XCTAssertEqual(result.`Type`, Int(truncating: message.messageType))
        //XCTAssertEqual(result.SenderAddress, message.s)
        //XCTAssertEqual(result.SenderName, message.order)
        XCTAssertEqual(result.Time, message.time!.timeIntervalSince1970)
        XCTAssertEqual(result.Size, Int(truncating: message.size))
        XCTAssertEqual(result.IsEncrypted, message.isE2E ? 1:0)
        XCTAssertEqual(result.ExpirationTime, message.expirationTime)
        XCTAssertEqual(result.IsReplied, message.replied ? 1:0)
        XCTAssertEqual(result.IsRepliedAll, message.repliedAll ? 1:0)
        XCTAssertEqual(result.IsForwarded, message.forwarded ? 1:0)
        //XCTAssertEqual(result.SpamScore, Int(truncating: message.spam))
        XCTAssertEqual(result.AddressID, message.addressID)
        XCTAssertEqual(result.NumAttachments, Int(truncating: message.numAttachments))
        XCTAssertEqual(result.Flags, Int(truncating: message.flags))
        //XCTAssertEqual(result.LabelIDs, message.labels)
        //XCTAssertEqual(result.ExternalID, message.id)
        XCTAssertEqual(result.Body, message.body)
        XCTAssertEqual(result.Header, message.header)
        XCTAssertEqual(result.MIMEType, message.mimeType)
        XCTAssertEqual(result.UserID, message.userID)
        XCTAssertEqual(result.isDetailsDownloaded, message.isDetailDownloaded)
        /*XCTAssertEqual(result.Order, message.order)
        XCTAssertEqual(result.Order, message.order)
        XCTAssertEqual(result.Order, message.order)
        XCTAssertEqual(result.Order, message.order)*/
    }

    // Test with some UI tests?
    /*func testFetchMessages() throws {
        let sut = EncryptedSearchService.shared.fetchMessages
        sut(self.testUserID, Message.Location.allmail.rawValue, 0){
            (errors, messages) in
            XCTAssertNotNil(errors) // errors should be nil
            // There are no message for test user? what to check?
        }
    }*/

    // Test with some UI tests?
    /* func testProcessPageOneByOne() throws {
        //TODO
    } */

    /* func testGetMessageDetailsForSingleMessage() throws {
        let sut = EncryptedSearchService.shared.getMessageDetailsForSingleMessage
        let testSender: ESSender = ESSender(Name: "sender", Address: "sender@sender.ch")
        let testESMessage: ESMessage = ESMessage(id: self.testMessageID, order: 0, conversationID: "", subject: "subject", unread: 0, type: 0, senderAddress: "sender@sender.ch", senderName: "sender", sender: testSender, toList: [testSender], ccList: [testSender], bccList: [testSender], time: 0, size: 5, isEncrypted: 1, expirationTime: Date(), isReplied: 0, isRepliedAll: 0, isForwarded: 0, spamScore: 0, addressID: "", numAttachments: 0, flags: 0, labelIDs: Set(arrayLiteral: Message.Location.allmail.rawValue), externalID: "", body: nil, header: nil, mimeType: nil, userID: self.testUserID)
        sut(testESMessage, self.testUserID){
            (message) in
            // hwo to check
        }
    } */

    /*func testDecryptBodyIfNeeded() throws {
        //TODO
    }*/

    /*func testDecryptAndExtractDataSingleMessage() throws {
        //TODO
    }*/

    /* func testCreateEncryptedContent() throws {
        let sut = EncryptedSearchService.shared.createEncryptedContent
        let testMessage: ESMessage = ESMessage(id: "uniqueID3", order: 3, conversationID: "", subject: "subject", unread: 1, type: 1, senderAddress: "sender", senderName: "sender", sender: ESSender(Name: "sender", Address: "address"), toList: [], ccList: [], bccList: [], time: 1637058776, size: 5, isEncrypted: 1, expirationTime: Date(), isReplied: 0, isRepliedAll: 0, isForwarded: 0, spamScore: 0, addressID: "", numAttachments: 0, flags: 0, labelIDs: ["5", "1"], externalID: "", body: "hello", header: "", mimeType: "", userID: self.testUserID)
        let result: EncryptedsearchEncryptedMessageContent? = sut(testMessage, "hello", testUserID)

        // TODO getcipher creates a new key each time
        //XCTAssertEqual(result!.iv?.base64EncodedString(), "xxhosAXX20sumrAz")
        //XCTAssertEqual(result!.ciphertext?.base64EncodedString(), "jTW7KjWSlKrY068Wc3slqtxh8J9+u1HrbLQYXrqpUJUqovjWgIxfWy0OkjaeI0w562bZU1h8HveNe2LDUhRDSK/ClxEk8A+qailLETeq+mptugbnIgRUe5RGP/5N7knAPoTAN+l/xB4OiT4C+CFKGizaxg2fzHsb3J/DnNSJohFi4cInC5msUXAOj68=")
    } */

    func testAddMessageKewordsToSearchIndex() throws {
        EncryptedSearchService.shared.setESState(userID: self.testUserID, indexingState: .downloading)
        let sut = EncryptedSearchService.shared.addMessageKewordsToSearchIndex
        let testMessage: ESMessage = ESMessage(id: "uniqueID3",
                                               order: 3,
                                               conversationID: "",
                                               subject: "subject",
                                               unread: 1,
                                               type: 1,
                                               senderAddress: "sender",
                                               senderName: "sender",
                                               sender: ESSender(Name: "sender", Address: "address"),
                                               toList: [],
                                               ccList: [],
                                               bccList: [],
                                               time: 1637058776,
                                               size: 5,
                                               isEncrypted: 1,
                                               expirationTime: Date(),
                                               isReplied: 0,
                                               isRepliedAll: 0,
                                               isForwarded: 0,
                                               spamScore: 0,
                                               addressID: "",
                                               numAttachments: 0,
                                               flags: 0,
                                               labelIDs: ["5", "1"],
                                               externalID: "",
                                               body: "hello",
                                               header: "",
                                               mimeType: "",
                                               userID: self.testUserID)
        let encryptedContent: EncryptedsearchEncryptedMessageContent? = EncryptedSearchService.shared.createEncryptedContent(message: testMessage,
                                                                                                                             cleanedBody: "hello",
                                                                                                                             userID: self.testUserID)
        sut(self.testUserID, testMessage, encryptedContent, {})

        let numberOfEntries = EncryptedSearchIndexService.shared.getNumberOfEntriesInSearchIndex(for: self.testUserID)
        XCTAssertEqual(numberOfEntries, 3)
    }

    // Depending on RAM usage
    /*func testSlowDownIndexing() throws {
        let sut = EncryptedSearchService.shared.slowDownIndexing
        EncryptedSearchService.shared.setESState(userID: self.testUserID, indexingState: .downloading)
        sut(self.testUserID)
        if let indexingQueue = EncryptedSearchService.shared.messageIndexingQueue {
            XCTAssertNotEqual(indexingQueue.maxConcurrentOperationCount, OperationQueue.defaultMaxConcurrentOperationCount)
        }
    }*/

    // Depending on RAM usage
    /*func testSpeedUpIndexing() throws {
        let sut = EncryptedSearchService.shared.speedUpIndexing
        EncryptedSearchService.shared.setESState(userID: self.testUserID, indexingState: .downloading)
        EncryptedSearchService.shared.slowDownIndexing(userID: self.testUserID)    // first slow it down
        sut(self.testUserID)
        if let indexingQueue = EncryptedSearchService.shared.messageIndexingQueue {
            XCTAssertEqual(indexingQueue.maxConcurrentOperationCount, OperationQueue.defaultMaxConcurrentOperationCount)
        }
    }*/

    // Test with some UI tests
    /* func testSearch() throws {
        let sut = EncryptedSearchService.shared.search
        let query: String = "hello2"
        let page: Int = 0
        let searchViewModel: SearchViewModel = SearchViewModel(user: self.user, coreDataService: self.coreDataService, uiDelegate: nil)
        sut(query, page, searchViewModel){_ in
            XCTAssertEqual(searchViewModel.messages.count, 1)
        }
    } */

    func testClearSearchState() throws {
        let sut = EncryptedSearchService.shared.clearSearchState
        sut()
        XCTAssertNil(EncryptedSearchService.shared.searchState)
    }
    
    // Cannot be tested as BG launch handlers must be registered before the app launches
    /*@available(iOS 13.0, *)
    func testRegisterBGProcessingTask() throws {
        let sut = EncryptedSearchService.shared.registerBGProcessingTask
        sut()
        BGTaskScheduler.shared.getPendingTaskRequests { (bgtaskrequests) in
            print("BG task: \(bgtaskrequests[0].identifier)")
            print("length: \(bgtaskrequests.count)")
        }
    }*/

    // Cannot be tested as BG launch handlers must be registered before the app launches
    /* func testRegisterBGAppRefreshTask() throws {
        //TODO
    } */

    // Cannot be tested as it depends on the device
    /* func testGetTotalAvailableMemory() throws {
        //TODO
    } */
    
    // Private Function
    /* func testFetchMessageDetailForMessage() throws {
        //TODO
    } */

    // Private Function
    /* func testCheckIfIndexingIsComplete() throws {
        //TODO
    } */

    // Private function
    /* func testCleanUpAfterIndexing() throws {
        //TODO
    } */

    // Private Function
    /*func testPauseAndResumeIndexing() throws {
        //TODO
    }*/

    // Private Function
    /* func testUpdateMessageMetadataInSearchIndex() throws {
        //TODO
    } */

    // Private Function
    /* func testUpdateCurrentUserIfNeeded() throws {
        //TODO
    } */

    // Private Function
    /* func testGetTotalMessages() throws {
        //TODO
    } */

    // Private function
    /* func testJsonStringToESMessage() throws {
        //TODO
    } */

    // Private function
    /* func testParseMessageResponse() throws {
        //TODO
    } */

    // Private function
    /* func testParseMessageDetailResponse() throws {
        //TODO
    } */

    // Private function
    /* func testFetchSingleMessageFromServer() throws {
        //TODO
    } */

    // Private Function
    /* func testDownloadAndProcessPage() throws {
        //TODO
    } */

    // Private function
    /* func testDownloadPage() throws {
        //TODO
    } */

    // TODO remove?
    //func testParseMessageObjectFromResponse() throws {
        //TODO
    //}

    // Private function
    /* func testGetMessage() throws {
        //TODO
    } */

    // Private function
    /*func testGetCipher() throws {
        let sut = EncryptedSearchService.shared.getCipher

        let result: EncryptedsearchAESGCMCipher = sut(self.testUserID)

        let testKey = KeychainWrapper.keychain.data(forKey: "searchIndexKey_" + self.testUserID)
        let cipher = EncryptedsearchAESGCMCipher(testKey!)

        //XCTAssertEqual(result.)
        //TODO
    }*/

    // Private function
    /*func testGenerateSearchIndexKey() throws {
        let sut = EncryptedSearchService.shared.generateSearchIndexKey

        let result: Data? = sut(self.testUserID)
        
        XCTAssertEqual(result!.count, 32)   // should be 32 byte
        XCTAssertFalse(result!.isEmpty)     // should be false
        
        let decoded = Data(base64Encoded: result!)  // check if the result is base64
        XCTAssertNil(decoded)   // should not be nil
    }*/

    // Private function
    /* func testStoreSearchIndexKey() throws {
        //TODO
    } */

    // Private function
    /* func testRetrieveSearchIndexKey() throws {
        //TODO
    } */

    // Private function
    /* func testHasSearchedBefore() throws {
        //TODO
    } */

    // Private function
    /* func testGetSearcher() throws {
        let sut = EncryptedSearchService.shared.getSearcher
        let testQuery: String = "test query"
        let result: EncryptedsearchSimpleSearcher = sut(testQuery)

        let testStringList: EncryptedsearchStringList = EncryptedSearchService.shared.createEncryptedSearchStringList(testQuery)
        let testSearcher = EncryptedsearchSimpleSearcher(testStringList, contextSize: 50)
        //XCTAssertEqual(result, testSearcher)
        //TODO how to test this?
    } */

    // Private function
    /* func testCreateEncryptedSearchStringList() throws {
        let sut = EncryptedSearchService.shared.createEncryptedSearchStringList
        let testQuery: String = "test query"
        let result: EncryptedsearchStringList = sut(testQuery)

        XCTAssertEqual(result.length(), 2)
        XCTAssertEqual(result.get(0, error: nil), "test")
        XCTAssertEqual(result.get(1, error: nil), "query")
    } */

    // Private function
    /* func testGetCache() throws {
        let sut = EncryptedSearchService.shared.getCache

        let testKey = KeychainWrapper.keychain.data(forKey: "searchIndexKey_" + self.testUserID)
        let cipher = EncryptedsearchAESGCMCipher(testKey!)
        let result: EncryptedsearchCache = sut(cipher!, self.testUserID)

        let dbParams = EncryptedSearchIndexService.shared.getDBParams(self.testUserID)
        let cache: EncryptedsearchCache = EncryptedSearchCacheService.shared.buildCacheForUser(userId: self.testUserID, dbParams: dbParams, cipher: cipher!)

        XCTAssertTrue(result.isBuilt())
        XCTAssertEqual(result.getLength(), cache.getLength())
    } */

    // Private function
    /* func testExtractSearchResults() throws {
        //TODO
    } */

    // Private function
    /* func testDoIndexSearch() throws {
        //TODO
    } */

    // Private function
    /* func testGetIndex() throws {
        //TODO
    } */

    // Private function
    /* func testDoCachedSearch() throws {
        //TODO
    } */

    // Private function
    /* func testPublishIntermediateResults() throws {
        //TODO
    } */

    // Private function
    /* func testContinueIndexingInBackground() throws {
        //TODO
    } */

    // Private function
    /* func testEndBackgroundTask() throws {
        //TODO
    } */

    // Private function
    /* func testCancelBGProcessingTask() throws {
        //TODO
    } */

    // Private function
    /* func testScheduleNewBGProcessingTask() throws {
        //TODO
    } */

    // Private function
    /* func testBgProcessingTask() throws {
        //TODO
    } */

    // Private function
    /* func testCancelBGAppRefreshTask() throws {
        //TODO
    } */

    // Private function
    /* func testScheduleNewAppRefreshTask() throws {
        //TODO
    } */

    // Private function
    /* func testAppRefreshTask() throws {
        //TODO
    } */

    // Private function
    /* func testSendIndexingMetrics() throws {
        //TODO
    } */

    // Private function
    /* func testSendSearchMetrics() throws {
        //TODO
    } */

    // Private function
    /* func testSendMetrics() throws {
        //TODO
    } */

    // Private function
    /* func testSendNotification() throws {
        //TODO
    } */

    // Private function
    /* func testAppMovedToBackground() throws {
        //TODO
    } */

    // Private function
    /* func testCheckIfEnoughStorage() throws {
        //TODO
    } */

    // Private function
    /* func testEstimateIndexingTime() throws {
        //TODO
    } */

    // Private function
    /* func testUpdateRemainingIndexingTime() throws {
        //TODO
    } */

    // Private function
    /* func testRegisterForBatteryLevelChangeNotifications() throws {
        //TODO
    } */

    // Private function
    /* func testRegisterForPowerStateChangeNotifications() throws {
        //TODO
    } */

    // Private function
    /* func testResponseToLowPowerMode() throws {
        //TODO
    } */

    // Private function
    /* func testResponseToBatteryLevel() throws {
        //TODO
    } */

    // Private function
    /* func testRegisterForTermalStateChangeNotifications() throws {
        //TODO
    } */

    // Private function
    /* func testResponseToHeat() throws {
        //TODO
    } */

    // Private function
    /* func testGetCurrentlyAvailableAppMemory() throws {
        //TODO
    } */

    // Private function
    /* func testUpdateIndexBuildingProgress() throws {
        //TODO
    } */

    // TODO remove?
    /*func testUpdateUIWithProgressBarStatus() throws {
        //TODO
    }*/

    // Private function
    /* func testUpdateUIWithIndexingStatus() throws {
        //TODO
    } */

    // Private function
    /* func testUpdateUIIndexingComplete() throws {
        //TODO
    } */

    func testHighlightKeyWords() throws {
        let sut = EncryptedSearchService.shared.highlightKeyWords
        EncryptedSearchService.shared.searchQuery = ["custom", "folders"]
        let html = """
<html>
 <head></head>
 <body>
  <p>Hello,</p>
  <p>You have 1 new message(s) in your inbox and custom folders.</p>
  <p>Please log in at <a href="https://mail.protonmail.com">https://mail.protonmail.com</a> to check them. These notifications can be turned off by logging into your account and disabling the daily notification setting.</p>
  <p>Best regards,</p>
  <p>The ProtonMail Team</p>
 </body>
</html>
"""
        var result = sut(html)
        var expectedResult: String = """
<html>
 <head></head>
 <body>
  <p>Hello,</p>
  <p>
   <span>
    You have 1 new message(s) in your inbox and
    <mark>custom</mark>
    <mark>
    folders</mark>.</span></p>
  <p>Please log in at <a href="https://mail.protonmail.com">https://mail.protonmail.com</a> to check them. These notifications can be turned off by logging into your account and disabling the daily notification setting.</p>
  <p>Best regards,</p>
  <p>The ProtonMail Team</p>
 </body>
</html>
"""
        result = result.components(separatedBy: .whitespacesAndNewlines).joined()
        expectedResult = expectedResult.components(separatedBy: .whitespacesAndNewlines).joined()
        XCTAssertEqual(result, expectedResult)
    }
}
