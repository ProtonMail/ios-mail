//
//  MessageDataServiceTests.swift
//  ProtonMailTests
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import XCTest
import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail
import Groot
import class ProtonCoreDataModel.UserInfo

class MessageDataServiceTests: XCTestCase {
    var testContext: NSManagedObjectContext!
    private var contextProvider: CoreDataContextProviderProtocol!
    let customLabelId: LabelID = "Vg_DqN6s-xg488vZQBkiNGz0U-62GKN6jMYRnloXY-isM9s5ZR-rWCs_w8k9Dtcc-sVC-qnf8w301Q-1sA6dyw=="

    override func setUpWithError() throws {
        testContext = MockCoreDataStore.testPersistentContainer.viewContext
        contextProvider = MockCoreDataContextProvider()
        let parsedLabel = testLabelsData.parseJson()!
        _ = try GRTJSONSerialization.objects(withEntityName: Label.Attributes.entityName,
                                             fromJSONArray: parsedLabel,
                                             in: testContext)

        try testContext.save()
    }

    override func tearDownWithError() throws {
        testContext = nil
        contextProvider = nil
    }

    func testFindMessagesWithSourceIdsWithMessageInSpamToInbox() throws {
        let message = try XCTUnwrap(makeTestMessageIn(Message.Location.spam.labelID))
        let sut = MessageDataService.findMessagesWithSourceIds
        let result = sut([MessageEntity(message)], [customLabelId], Message.Location.inbox.labelID)

        XCTAssertEqual(result.count, 1)
        let pair = try XCTUnwrap(result.first)
        XCTAssertEqual(pair.1, Message.Location.spam.labelID)
        XCTAssertEqual(pair.0, MessageEntity(message))
    }

    func testFindMessagesWithSourceIdsWithMessageInCustomFolderToInbox() throws {
        let message = try XCTUnwrap(makeTestMessageIn(customLabelId))
        let sut = MessageDataService.findMessagesWithSourceIds
        let result = sut([MessageEntity(message)], [customLabelId], Message.Location.inbox.labelID)

        XCTAssertEqual(result.count, 1)
        let pair = try XCTUnwrap(result.first)
        XCTAssertEqual(pair.1, customLabelId)
        XCTAssertEqual(pair.0, MessageEntity(message))
    }

    func testFindMessagesWithSourceIdsWithMessageInSpamToSamePlace() throws {
        let message = try XCTUnwrap(makeTestMessageIn(Message.Location.spam.labelID))
        let sut = MessageDataService.findMessagesWithSourceIds
        let result = sut([MessageEntity(message)], [customLabelId], Message.Location.spam.labelID)

        XCTAssertEqual(result.count, 0)
    }

    func testFindMessagesWithSourceIdsWithMessageInDraftToSpam() throws {
        let message = try XCTUnwrap(makeTestMessageIn(Message.Location.draft.labelID))
        let sut = MessageDataService.findMessagesWithSourceIds
        let result = sut([MessageEntity(message)], [customLabelId], Message.Location.spam.labelID)

        XCTAssertEqual(result.count, 0)
    }

    func testFindMessagesWithSourceIdsWithMessageInSentToSpam() throws {
        let message = try XCTUnwrap(makeTestMessageIn(Message.Location.sent.labelID))
        let sut = MessageDataService.findMessagesWithSourceIds
        let result = sut([MessageEntity(message)], [customLabelId], Message.Location.spam.labelID)

        XCTAssertEqual(result.count, 0)
    }

    func testFindMessagesWithSourceIdsWithMessageInDraftToInbox() throws {
        let message = try XCTUnwrap(makeTestMessageIn(Message.Location.draft.labelID))
        let sut = MessageDataService.findMessagesWithSourceIds
        let result = sut([MessageEntity(message)], [customLabelId], Message.Location.inbox.labelID)

        XCTAssertEqual(result.count, 0)
    }

    func testFindMessagesWithSourceIdsWithMessageInSentToInbox() throws {
        let message = try XCTUnwrap(makeTestMessageIn(Message.Location.sent.labelID))
        let sut = MessageDataService.findMessagesWithSourceIds
        let result = sut([MessageEntity(message)], [customLabelId], Message.Location.inbox.labelID)

        XCTAssertEqual(result.count, 0)
    }

    func testFindMessagesWithSourceIdsWithMessageHavingRandomLabelIdToInbox() throws {
        let message = try XCTUnwrap(makeTestMessageIn("sjldfjisdflngw"))
        let sut = MessageDataService.findMessagesWithSourceIds
        let result = sut([MessageEntity(message)], [customLabelId], Message.Location.inbox.labelID)

        XCTAssertEqual(result.count, 0)
    }

    func testFetchedResults_whenOneMessageIsSoftDeleted_itShouldNotReturnTheSofDeletedMessage() throws {
        let user = mockUser(showMoved: .doNotKeep)
        let userID = user.userID.rawValue
        let sut = user.messageService
        _ = mockMessage(in: [LabelLocation.inbox.labelID], userID: userID, isSoftDeleted: true, context: contextProvider.mainContext)
        _ = mockMessage(in: [LabelLocation.inbox.labelID], userID: userID, context: contextProvider.mainContext)
        _ = mockMessage(in: [LabelLocation.inbox.labelID], userID: userID, context: contextProvider.mainContext)

        let fetchedController = try XCTUnwrap(sut.fetchedResults(
            by: LabelLocation.inbox.labelID,
            viewMode: .singleMessage
        ))
        try fetchedController.performFetch()
        let objects = try XCTUnwrap(fetchedController.fetchedObjects)
        XCTAssertEqual(objects.count, 2)
    }

    func testFetchedResults_whenQueryUnreadMessageAndOneMessageIsUnreaded_itShouldReturnTheUnreadedMessage() throws {
        let user = mockUser(showMoved: .doNotKeep)
        let userID = user.userID.rawValue
        let sut = user.messageService
        _ = mockMessage(in: [LabelLocation.inbox.labelID], userID: userID, isUnread: true, context: contextProvider.mainContext)
        _ = mockMessage(in: [LabelLocation.inbox.labelID], userID: userID, context: contextProvider.mainContext)
        _ = mockMessage(in: [LabelLocation.inbox.labelID], userID: userID, context: contextProvider.mainContext)

        let fetchedController = try XCTUnwrap(sut.fetchedResults(
            by: LabelLocation.inbox.labelID,
            viewMode: .singleMessage,
            isUnread: true
        ))
        try fetchedController.performFetch()
        let objects = try XCTUnwrap(fetchedController.fetchedObjects)
        XCTAssertEqual(objects.count, 1)
    }

    func testFetchedResults_whenQueryDraftAndShowMovedIsDoNotKeep_itShouldReturnMessageInDraft() throws {
        let user = mockUser(showMoved: .doNotKeep)
        let userID = user.userID.rawValue
        let sut = user.messageService
        _ = mockMessage(in: [LabelLocation.hiddenDraft.labelID, LabelID(UUID().uuidString)], userID: userID, context: contextProvider.mainContext)
        _ = mockMessage(in: [LabelLocation.draft.labelID], userID: userID, context: contextProvider.mainContext)
        _ = mockMessage(in: [LabelLocation.draft.labelID], userID: userID, context: contextProvider.mainContext)

        let fetchedController = try XCTUnwrap(sut.fetchedResults(
            by: LabelLocation.draft.labelID,
            viewMode: .singleMessage
        ))
        try fetchedController.performFetch()
        let objects = try XCTUnwrap(fetchedController.fetchedObjects)
        XCTAssertEqual(objects.count, 2)
    }

    func testFetchedResults_whenQueryDraftAndShowMovedIsKeepDraft_itShouldReturnMessageRelatedToDraft() throws {
        let user = mockUser(showMoved: .keepDraft)
        let userID = user.userID.rawValue
        let sut = user.messageService
        _ = mockMessage(in: [LabelLocation.hiddenDraft.labelID, LabelID(UUID().uuidString)], userID: userID, context: contextProvider.mainContext)
        _ = mockMessage(in: [LabelLocation.draft.labelID], userID: userID, context: contextProvider.mainContext)
        _ = mockMessage(in: [LabelLocation.draft.labelID], userID: userID, context: contextProvider.mainContext)

        let fetchedController = try XCTUnwrap(sut.fetchedResults(
            by: LabelLocation.draft.labelID,
            viewMode: .singleMessage
        ))
        try fetchedController.performFetch()
        let objects = try XCTUnwrap(fetchedController.fetchedObjects)
        XCTAssertEqual(objects.count, 3)
    }

    func testFetchedResults_whenQueryDraftAndShowMovedIsKeepSent_itShouldReturnMessageInDraft() throws {
        let user = mockUser(showMoved: .keepSent)
        let userID = user.userID.rawValue
        let sut = user.messageService
        _ = mockMessage(in: [LabelLocation.hiddenDraft.labelID, LabelID(UUID().uuidString)], userID: userID, context: contextProvider.mainContext)
        _ = mockMessage(in: [LabelLocation.draft.labelID], userID: userID, context: contextProvider.mainContext)
        _ = mockMessage(in: [LabelLocation.draft.labelID], userID: userID, context: contextProvider.mainContext)

        let fetchedController = try XCTUnwrap(sut.fetchedResults(
            by: LabelLocation.draft.labelID,
            viewMode: .singleMessage
        ))
        try fetchedController.performFetch()
        let objects = try XCTUnwrap(fetchedController.fetchedObjects)
        XCTAssertEqual(objects.count, 2)
    }

    func testFetchedResults_whenQuerySentAndShowMovedIsDoNotKeep_itShouldReturnMessageInSent() throws {
        let user = mockUser(showMoved: .doNotKeep)
        let userID = user.userID.rawValue
        let sut = user.messageService
        _ = mockMessage(in: [LabelLocation.hiddenSent.labelID, LabelID(UUID().uuidString)], userID: userID, context: contextProvider.mainContext)
        _ = mockMessage(in: [LabelLocation.sent.labelID], userID: userID, context: contextProvider.mainContext)
        _ = mockMessage(in: [LabelLocation.sent.labelID], userID: userID, context: contextProvider.mainContext)

        let fetchedController = try XCTUnwrap(sut.fetchedResults(
            by: LabelLocation.sent.labelID,
            viewMode: .singleMessage
        ))
        try fetchedController.performFetch()
        let objects = try XCTUnwrap(fetchedController.fetchedObjects)
        XCTAssertEqual(objects.count, 2)
    }

    func testFetchedResults_whenQuerySentAndShowMovedIsKeepDraft_itShouldReturnMessageInSent() throws {
        let user = mockUser(showMoved: .keepDraft)
        let userID = user.userID.rawValue
        let sut = user.messageService
        _ = mockMessage(in: [LabelLocation.hiddenSent.labelID, LabelID(UUID().uuidString)], userID: userID, context: contextProvider.mainContext)
        _ = mockMessage(in: [LabelLocation.sent.labelID], userID: userID, context: contextProvider.mainContext)
        _ = mockMessage(in: [LabelLocation.sent.labelID], userID: userID, context: contextProvider.mainContext)

        let fetchedController = try XCTUnwrap(sut.fetchedResults(
            by: LabelLocation.sent.labelID,
            viewMode: .singleMessage
        ))
        try fetchedController.performFetch()
        let objects = try XCTUnwrap(fetchedController.fetchedObjects)
        XCTAssertEqual(objects.count, 2)
    }

    func testFetchedResults_whenQuerySentAndShowMovedIsKeepSent_itShouldReturnMessageRelatedToSent() throws {
        let user = mockUser(showMoved: .keepSent)
        let userID = user.userID.rawValue
        let sut = user.messageService
        _ = mockMessage(in: [LabelLocation.hiddenSent.labelID, LabelID(UUID().uuidString)], userID: userID, context: contextProvider.mainContext)
        _ = mockMessage(in: [LabelLocation.sent.labelID], userID: userID, context: contextProvider.mainContext)
        _ = mockMessage(in: [LabelLocation.sent.labelID], userID: userID, context: contextProvider.mainContext)

        let fetchedController = try XCTUnwrap(sut.fetchedResults(
            by: LabelLocation.sent.labelID,
            viewMode: .singleMessage
        ))
        try fetchedController.performFetch()
        let objects = try XCTUnwrap(fetchedController.fetchedObjects)
        XCTAssertEqual(objects.count, 3)
    }

    func testFetchedResults_whenShowMovedIsKeepBoth_itShouldReturnMessageRelatedToCorrespondFolder() throws {
        let user = mockUser(showMoved: .keepBoth)
        let userID = user.userID.rawValue
        let sut = user.messageService
        _ = mockMessage(in: [LabelLocation.hiddenSent.labelID, LabelID(UUID().uuidString)], userID: userID, context: contextProvider.mainContext)
        _ = mockMessage(in: [LabelLocation.sent.labelID], userID: userID, context: contextProvider.mainContext)
        _ = mockMessage(in: [LabelLocation.sent.labelID], userID: userID, context: contextProvider.mainContext)

        _ = mockMessage(in: [LabelLocation.hiddenDraft.labelID, LabelID(UUID().uuidString)], userID: userID, context: contextProvider.mainContext)
        _ = mockMessage(in: [LabelLocation.draft.labelID], userID: userID, context: contextProvider.mainContext)
        _ = mockMessage(in: [LabelLocation.draft.labelID], userID: userID, context: contextProvider.mainContext)

        let sentFetched = try XCTUnwrap(sut.fetchedResults(
            by: LabelLocation.sent.labelID,
            viewMode: .singleMessage
        ))
        try sentFetched.performFetch()
        let sentMessages = try XCTUnwrap(sentFetched.fetchedObjects)
        XCTAssertEqual(sentMessages.count, 3)

        let draftFetched = try XCTUnwrap(sut.fetchedResults(
            by: LabelLocation.draft.labelID,
            viewMode: .singleMessage
        ))
        try draftFetched.performFetch()
        let draftMessages = try XCTUnwrap(draftFetched.fetchedObjects)
        XCTAssertEqual(draftMessages.count, 3)
    }

    func testFetchedResults_whenOneConversationIsSoftDeleted_itShouldNotReturnTheSofDeletedConversation() throws {
        let user = mockUser(showMoved: .doNotKeep)
        let userID = user.userID.rawValue
        let sut = user.messageService
        mockConversation(in: [LabelLocation.inbox.labelID], userID: userID, context: contextProvider.mainContext)
        mockConversation(in: [LabelLocation.inbox.labelID], userID: userID, context: contextProvider.mainContext)
        mockConversation(in: [LabelLocation.inbox.labelID], userID: userID, isSoftDeleted: true, context: contextProvider.mainContext)

        let fetchedController = try XCTUnwrap(sut.fetchedResults(
            by: LabelLocation.inbox.labelID,
            viewMode: .conversation
        ))
        try fetchedController.performFetch()
        let objects = try XCTUnwrap(fetchedController.fetchedObjects)
        XCTAssertEqual(objects.count, 2)
    }

    func testFetchedResults_whenQueryUnreadConversationAndOneConversationIsUnread_itShouldReturnTheUnreadConversation() throws {
        let user = mockUser(showMoved: .doNotKeep)
        let userID = user.userID.rawValue
        let sut = user.messageService
        mockConversation(in: [LabelLocation.inbox.labelID], userID: userID, context: contextProvider.mainContext)
        mockConversation(in: [LabelLocation.inbox.labelID], userID: userID, context: contextProvider.mainContext)
        mockConversation(in: [LabelLocation.inbox.labelID], userID: userID, isUnread: true, context: contextProvider.mainContext)

        let fetchedController = try XCTUnwrap(sut.fetchedResults(
            by: LabelLocation.inbox.labelID,
            viewMode: .conversation,
            isUnread: true
        ))
        try fetchedController.performFetch()
        let objects = try XCTUnwrap(fetchedController.fetchedObjects)
        XCTAssertEqual(objects.count, 1)
    }
}

extension MessageDataServiceTests {
    private func mockUser(showMoved: ShowMoved) -> UserManager {
        let globalContainer = GlobalContainer()
        globalContainer.contextProviderFactory.register { self.contextProvider }

        let userID = UUID().uuidString
        let userInfo = UserInfo.getDefault()
        userInfo.userId = userID
        let user = UserManager(api: APIServiceMock(), userInfo: userInfo, globalContainer: globalContainer)
        user.mailSettings = MailSettings(showMoved: showMoved)
        return user
    }

    private func mockLabel(labelID: LabelID, context: NSManagedObjectContext) {
        let label = Label(context: context)
        label.labelID = labelID.rawValue
        try? context.save()
    }

    private func makeTestMessageIn(_ labelId: LabelID) -> Message? {
        mockMessage(in: [labelId], context: testContext)
    }

    private func mockMessage(
        in labelIDs: [LabelID],
        userID: String = "",
        isUnread: Bool = false,
        isSoftDeleted: Bool = false,
        context: NSManagedObjectContext
    ) -> Message? {
        var parsedObject = testMessageMetaData.parseObjectAny()!
        parsedObject["ID"] = UUID().uuidString
        let message = try? GRTJSONSerialization.object(
            withEntityName: Message.Attributes.entityName,
            fromJSONDictionary: parsedObject,
            in: context
        ) as? Message
        message?.userID = userID
        message?.messageStatus = 1
        message?.unRead = isUnread
        message?.isSoftDeleted = isSoftDeleted
        message?.remove(labelID: "0")
        for id in labelIDs {
            if Label.labelForLabelID(id.rawValue, inManagedObjectContext: context) == nil {
                mockLabel(labelID: id, context: context)
            }
            message?.add(labelID: id.rawValue)
        }
        try? context.save()
        return message
    }

    private func mockConversation(
        in labelIDs: [LabelID],
        userID: String,
        isUnread: Bool = false,
        isSoftDeleted: Bool = false,
        context: NSManagedObjectContext
    ) {
        let parsedObject = testConversationDetailData.parseObjectAny()!
        let conversationID = UUID().uuidString
        var conversation: [String: Any] = parsedObject["Conversation"] as! [String : Any]
        conversation["ID"] = conversationID
        conversation["Order"] = Date().timeIntervalSinceReferenceDate
        let testConversation = try? GRTJSONSerialization
            .object(withEntityName: "Conversation",
                    fromJSONDictionary: conversation,
                    in: context) as? Conversation
        testConversation?.isSoftDeleted = isSoftDeleted
        for id in labelIDs {
            testConversation?.applyLabelChanges(labelID: id.rawValue, apply: true)

            let label = ContextLabel(context: context)
            label.userID = userID
            label.labelID = id.rawValue
            label.time = Date()
            label.unreadCount = isUnread ? NSNumber(value: 3) : NSNumber(value: 0)
            label.conversationID = conversationID
            label.isSoftDeleted = isSoftDeleted
            label.conversation = testConversation!
        }
        try? context.save()
    }
}
