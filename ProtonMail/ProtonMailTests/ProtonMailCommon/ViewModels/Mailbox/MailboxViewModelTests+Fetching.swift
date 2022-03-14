// Copyright (c) 2022 Proton Technologies AG
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
                               removeAllDraft: true,
                               unreadOnly: false) { _, _, _ in
            XCTAssertTrue(self.conversationProviderMock.callFetchConversations.wasCalledExactlyOnce)
            XCTAssertTrue(self.conversationProviderMock.callFetchConversationCounts.wasCalledExactlyOnce)
            XCTAssertTrue(self.eventsServiceMock.callFetchLatestEventID.wasCalledExactlyOnce)
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

    func testCheckToUseReadOrUnreadAction_inConversation_withUnreadMessage() {
        conversationStateProviderMock.viewMode = .conversation
        createSut(labelID: "1245", labelType: .folder, isCustom: false, labelName: nil)
        let conversationToReturn = Conversation(context: coreDataServiceMock.mainContext)
        conversationToReturn.conversationID = "1"
        let testMessage = Message(context: coreDataServiceMock.mainContext)
        testMessage.conversationID = "1"
        testMessage.unRead = true
        // Prepare the conversation has one message which is unread.
        conversationToReturn.applyLabelChanges(labelID: "1245", apply: true, context: coreDataServiceMock.mainContext)

        conversationProviderMock.callFetchLocal.bodyIs { _, _, _  in
            return [conversationToReturn]
        }

        XCTAssertFalse(sut.checkToUseReadOrUnreadAction(messageIDs: Set(["1"]), labelID: "1245"), "Should return false because the conversation has unread message in label 1245")
        XCTAssertTrue(conversationProviderMock.callFetchLocal.wasCalledExactlyOnce)

        XCTAssertTrue(sut.checkToUseReadOrUnreadAction(messageIDs: Set(["1"]), labelID: "1"))
    }

    func testCheckToUseReadOrUnreadAction_inConversation_withoutUnreadMessage() {
        conversationStateProviderMock.viewMode = .conversation
        createSut(labelID: "1245", labelType: .folder, isCustom: false, labelName: nil)
        let conversationToReturn = Conversation(context: coreDataServiceMock.mainContext)
        conversationToReturn.conversationID = "1"
        let testMessage = Message(context: coreDataServiceMock.mainContext)
        testMessage.conversationID = "1"
        testMessage.unRead = false
        // Prepare the conversation has one message which is unread.
        conversationToReturn.applyLabelChanges(labelID: "1245", apply: true, context: coreDataServiceMock.mainContext)

        conversationProviderMock.callFetchLocal.bodyIs { _, _, _  in
            return [conversationToReturn]
        }

        XCTAssertTrue(sut.checkToUseReadOrUnreadAction(messageIDs: Set(["1"]), labelID: "1245"), "Should return false because the conversation has unread message in label 1245")
        XCTAssertTrue(conversationProviderMock.callFetchLocal.wasCalledExactlyOnce)
    }
}
