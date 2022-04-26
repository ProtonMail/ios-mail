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
        let testUserInfo = UserInfo(displayName: "test display name", maxSpace: 42, notificationEmail: "test notification name",signature: "test signature", usedSpace: 123, userAddresses: [], autoSC: 321, language: "DE", maxUpload: 234, notify: 2345, showImage: 645, swipeL: 3452, swipeR: 4132, role: 1234, delinquent: 4123, keys: [], userId: "test", sign: 1234, attachPublicKey: 5467, linkConfirmation: "test link confirmation", credit: 098, currency: "BOL", pwdMode: 667, twoFA: 776, enableFolderColor: 77, inheritParentFolderColor: 88, subscribed: 12, groupingMode: 1, weekStart: 0, delaySendSeconds: 0)
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

    func testAddMessageToSearchIndex() throws {
        EncryptedSearchService.shared.setESState(userID: self.testUserID, indexingState: .downloading)
        let sut = EncryptedSearchService.shared.addMessageToSearchIndex
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

    func testClearSearchState() throws {
        let sut = EncryptedSearchService.shared.clearSearchState
        sut()
        XCTAssertNil(EncryptedSearchService.shared.searchState)
    }

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
  <p>Hello,</p>
  <p>
   <span>
    You have 1 new message(s) in your inbox and
    <mark style="background-color: #8498E9">custom</mark>
    <mark style="background-color: #8498E9">
    folders</mark>.</span></p>
  <p>Please log in at <a href="https://mail.protonmail.com">https://mail.protonmail.com</a> to check them. These notifications can be turned off by logging into your account and disabling the daily notification setting.</p>
  <p>Best regards,</p>
  <p>The ProtonMail Team</p>
"""
        result = result.components(separatedBy: .whitespacesAndNewlines).joined()
        expectedResult = expectedResult.components(separatedBy: .whitespacesAndNewlines).joined()
        XCTAssertEqual(result, expectedResult)
    }
}
