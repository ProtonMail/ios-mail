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

import Foundation
@testable import ProtonMail
import XCTest

extension MailboxViewModelTests {
    func testFetchConversation() {
        conversationStateProviderMock.viewMode = .conversation
        createSut(labelID: "1245", labelType: .folder, isCustom: false, labelName: nil)

        let expectation1 = expectation(description: "Closure is called")
        sut.fetchMessages(time: 999, forceClean: false, isUnread: false) { _, _, _ in
            XCTAssertTrue(self.conversationProviderMock.callFetchConversations.wasCalledExactlyOnce)
            do {
                let argument = try XCTUnwrap(self.conversationProviderMock.callFetchConversations.lastArguments)
                XCTAssertEqual(argument.first, self.sut.labelID)
                XCTAssertEqual(argument.a2, 999)
                XCTAssertFalse(argument.a3)
                XCTAssertFalse(argument.a4)
            } catch {
                XCTFail("Should not reach here")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFetchConversationWithReset() {
        conversationStateProviderMock.viewMode = .conversation
        createSut(labelID: "1245", labelType: .folder, isCustom: false, labelName: nil)

        let expectation1 = expectation(description: "Closure is called")
        sut.fetchDataWithReset(time: 999,
                               cleanContact: false,
                               unreadOnly: false) { _, _, _ in
            XCTAssertTrue(self.conversationProviderMock.callFetchConversations.wasCalledExactlyOnce)
            XCTAssertTrue(self.conversationProviderMock.callFetchConversationCounts.wasCalledExactlyOnce)
            XCTAssertTrue(self.mockFetchLatestEventId.executeWasCalled)
            do {
                let argument = try XCTUnwrap(self.conversationProviderMock.callFetchConversations.lastArguments)
                XCTAssertEqual(argument.first, self.sut.labelID)
                XCTAssertEqual(argument.a2, 999)
                XCTAssertFalse(argument.a3)
                XCTAssertTrue(argument.a4)

                let argument2 = try XCTUnwrap(self.conversationProviderMock.callFetchConversationCounts.lastArguments)
                XCTAssertNil(argument2.first)
            } catch {
                XCTFail("Should not reach here")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testSelectionContainsReadItems_inConversation_withReadConversation() {
        conversationStateProviderMock.viewMode = .conversation

        let conversationIDs = setupConversations(labelID: sut.labelID.rawValue, unreadStates: [true, false])
        sut.setupFetchController(nil)

        for id in conversationIDs {
            sut.select(id: id)
        }

        XCTAssertTrue(
            sut.selectionContainsReadItems(),
            "Should return true because the selected conversations contain at least one read message"
        )
    }

    func testSelectionContainsReadItems_inConversation_withoutReadConversation() {
        conversationStateProviderMock.viewMode = .conversation

        let conversationIDs = setupConversations(labelID: sut.labelID.rawValue, unreadStates: [true, true])
        sut.setupFetchController(nil)

        for id in conversationIDs {
            sut.select(id: id)
        }

        XCTAssertFalse(
            sut.selectionContainsReadItems(),
            "Should return false because all messages in all of the selected conversations are unread"
        )
    }

    func testSelectionContainsReadItems_inSingleMode_withReadMessage() {
        conversationStateProviderMock.viewMode = .singleMessage

        let messageIDs = setupMessages(labelID: sut.labelID.rawValue, unreadStates: [true, false])
        sut.setupFetchController(nil)

        for id in messageIDs {
            sut.select(id: id)
        }

        XCTAssertTrue(
            sut.selectionContainsReadItems(),
            "Should return true because the selected conversations contain at least one read message"
        )
    }

    func testSelectionContainsReadItems_inSingleMode_withoutReadMessage() {
        conversationStateProviderMock.viewMode = .singleMessage

        let messageIDs = setupMessages(labelID: sut.labelID.rawValue, unreadStates: [true, true])
        sut.setupFetchController(nil)

        for id in messageIDs {
            sut.select(id: id)
        }

        XCTAssertFalse(
            sut.selectionContainsReadItems(),
            "Should return false because all messages in all of the selected conversations are unread"
        )
    }

    private func setupConversations(labelID: String, unreadStates: [Bool]) -> [String] {
        let messageCount: NSNumber = 3

        return unreadStates.map { unreadState in
            let conversation = Conversation(context: testContext)
            conversation.conversationID = UUID().uuidString
            conversation.numMessages = messageCount

            let contextLabel = ContextLabel(context: testContext)
            contextLabel.labelID = labelID
            contextLabel.conversation = conversation
            contextLabel.unreadCount = unreadState ? messageCount : 0
            contextLabel.userID = "1"

            return conversation.conversationID
        }
    }

    private func setupMessages(labelID: String, unreadStates: [Bool]) -> [String] {
        let label = Label(context: testContext)
        label.labelID = labelID

        return unreadStates.map { unreadState in
            let testMessage = Message(context: testContext)
            testMessage.conversationID = UUID().uuidString
            testMessage.add(labelID: labelID)
            testMessage.messageStatus = 1
            testMessage.unRead = unreadState
            testMessage.userID = "1"
            return testMessage.messageID
        }
    }
}
