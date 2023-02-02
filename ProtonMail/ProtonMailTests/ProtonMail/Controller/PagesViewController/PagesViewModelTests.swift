// Copyright (c) 2022 Proton Technologies AG
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

import CoreData
import Groot
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_TestingToolkit
import XCTest
@testable import ProtonMail

final class PagesViewModelTests: XCTestCase {
    private var contextProvider: CoreDataService!
    private var user: UserManager!
    private var userIntroduction: UserIntroductionProgressProvider!
    private var userInfo: UserInfo!
    private var toolbarStatusProvider: ToolbarCustomizationInfoBubbleViewStatusProvider!
    private var userID: String!

    override func setUpWithError() throws {
        userID = UUID().uuidString
        contextProvider = sharedServices.get(by: CoreDataService.self)
        let apiServiceMock = APIServiceMock()
        let auth = AuthCredential(
            sessionID: "id",
            accessToken: "token",
            refreshToken: "refresh",
            expiration: .distantFuture,
            userName: "name",
            userID: "1",
            privateKey: nil,
            passwordKeySalt: nil
        )
        userInfo = UserInfo.getDefault()
        userInfo.userId = userID
        user = UserManager(
            api: apiServiceMock,
            userInfo: userInfo,
            authCredential: auth,
            parent: nil,
            appTelemetry: MailAppTelemetry()
        )
        userIntroduction = MockUserIntroductionProgressProvider()
        toolbarStatusProvider = MockToolbarCustomizationInfoBubbleViewStatusProvider()
    }

    override func tearDownWithError() throws {
        try contextProvider.write { context in
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            let request = NSBatchDeleteRequest(fetchRequest: fetch)
            try context.execute(request)

            let labelFetch = NSFetchRequest<NSFetchRequestResult>(entityName: ContextLabel.Attributes.entityName)
            let labelRequest = NSBatchDeleteRequest(fetchRequest: labelFetch)
            try context.execute(labelRequest)

            let conversationFetch = NSFetchRequest<NSFetchRequestResult>(entityName: Conversation.Attributes.entityName)
            let conversationRequest = NSBatchDeleteRequest(fetchRequest: conversationFetch)
            try context.execute(conversationRequest)
            _ = context.saveUpstreamIfNeeded()
        }
        contextProvider = nil
        user = nil
        userInfo = nil
        userIntroduction = nil
        toolbarStatusProvider = nil
    }

    func testMessageSpotlight_no_spotlight() throws {
        let sut = makeSUT(withMessages: 1, openedMessageIndex: 0)
        XCTAssertEqual(sut.spotlightPosition(), nil)
    }

    func testMessageSpotlight_left_spotlight() throws {
        let sut = makeSUT(withMessages: 2, openedMessageIndex: 1)
        XCTAssertEqual(sut.spotlightPosition(), .left)
    }

    func testMessageSpotlight_right_spotlight() throws {
        let sut = makeSUT(withMessages: 2, openedMessageIndex: 0)
        XCTAssertEqual(sut.spotlightPosition(), .right)
    }

    func testConversationSpotlight_no_spotlight() throws {
        let sut = makeSUT(withConversations: 1, openedConversationIndex: 0)
        XCTAssertEqual(sut.spotlightPosition(), nil)
    }

    func testConversationSpotlight_left_spotlight() throws {
        let sut = makeSUT(withConversations: 2, openedConversationIndex: 1)
        XCTAssertEqual(sut.spotlightPosition(), .left)
    }

    func testConversationSpotlight_right_spotlight() throws {
        let sut = makeSUT(withConversations: 2, openedConversationIndex: 0)
        XCTAssertEqual(sut.spotlightPosition(), .right)
    }
}

extension PagesViewModelTests {
    private func generateMessageObject() -> MessageID {
        let id = UUID().uuidString
        contextProvider.performAndWaitOnRootSavingContext { context in
            let label = Label(context: context)
            label.labelID = "0"
            label.userID = self.userID

            var parsedObject = testMessageMetaData.parseObjectAny()!
            parsedObject["ID"] = id
            let testMessage = try? GRTJSONSerialization
                .object(withEntityName: "Message",
                        fromJSONDictionary: parsedObject,
                        in: context) as? Message
            testMessage?.userID = self.userID
            testMessage?.messageStatus = 1
            testMessage?.unRead = false
            testMessage?.isSoftDeleted = false
            testMessage?.add(labelID: "0")
            testMessage?.time = Date()
            _ = context.saveUpstreamIfNeeded()
        }
        return MessageID(id)
    }

    private func generateConversationObject() -> ConversationID {
        let id = UUID().uuidString
        contextProvider.performAndWaitOnRootSavingContext { context in

            let parsedObject = testConversationDetailData.parseObjectAny()!
            var conversation: [String: Any] = parsedObject["Conversation"] as! [String : Any]
            conversation["ID"] = id
            conversation["Order"] = Date().timeIntervalSinceReferenceDate
            let testConversation = try? GRTJSONSerialization
                .object(withEntityName: "Conversation",
                        fromJSONDictionary: conversation,
                        in: context) as? Conversation
            testConversation?.applyLabelChanges(labelID: "0", apply: true)

            let label = ContextLabel(context: context)
            label.userID = self.userID
            label.labelID = "0"
            label.time = Date()
            label.conversationID = id
            label.isSoftDeleted = false
            label.conversation = testConversation!
            _ = context.saveUpstreamIfNeeded()
        }
        return ConversationID(id)
    }

    private func makeSUT(withMessages: Int, openedMessageIndex: Int) -> MessagePagesViewModel {
        var ids: [MessageID] = []
        for _ in 0..<withMessages {
            ids.append(generateMessageObject())
        }
        ids.reverse()
        let sut = MessagePagesViewModel(
            initialID: ids[openedMessageIndex],
            isUnread: false,
            labelID: LabelID("0"),
            user: user,
            userIntroduction: userIntroduction,
            infoBubbleViewStatusProvider: toolbarStatusProvider
        ) { _ in }
        return sut
    }

    private func makeSUT(withConversations: Int, openedConversationIndex: Int) -> ConversationPagesViewModel {
        userInfo.groupingMode = 0
        var ids: [ConversationID] = []
        for _ in 0..<withConversations {
            ids.append(generateConversationObject())
        }
        ids.reverse()
        let sut = ConversationPagesViewModel(
            initialID: ids[openedConversationIndex],
            isUnread: false,
            labelID: LabelID("0"),
            user: user,
            targetMessageID: nil,
            userIntroduction: userIntroduction,
            infoBubbleViewStatusProvider: toolbarStatusProvider
        ) { _ in }
        return sut
    }
}
