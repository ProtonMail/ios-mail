// Copyright (c) 2024 Proton Technologies AG
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
import InboxTesting
import proton_app_uniffi
import XCTest

class MailboxItemActionSheetModelTests: BaseTestCase {

    var invokedWithMessagesIDs: [ID]!
    var invokedWithConversationIDs: [ID]!
    var spiedNavigation: [MailboxItemActionSheetNavigation]!
    var stubbedMessageActions: MessageAvailableActions!
    var stubbedConversationActions: ConversationAvailableActions!
    var starActionPerformerWrapperSpy: StarActionPerformerWrapperSpy!

    override func setUp() {
        super.setUp()

        invokedWithMessagesIDs = []
        invokedWithConversationIDs = []
        spiedNavigation = []
        starActionPerformerWrapperSpy = .init()
    }

    override func tearDown() {
        super.tearDown()

        invokedWithMessagesIDs = nil
        invokedWithConversationIDs = nil
        spiedNavigation = nil
        stubbedMessageActions = nil
        stubbedConversationActions = nil
        starActionPerformerWrapperSpy = nil
    }

    func testState_WhenMailboxTypeIsMessage_ItReturnsAvailableMessageActions() {
        stubbedMessageActions = .init(
            replyActions: [.reply],
            messageActions: [.delete],
            moveActions: [.init(localId: .init(value: 1), name: .inbox, isSelected: .unselected)],
            generalActions: [.print]
        )

        let messagesIDs: [ID] = [.init(value: 7), .init(value: 88)]
        let title = "Message title"
        let sut = sut(ids: messagesIDs, type: .message, title: title)

        sut.handle(action: .viewAppear)

        XCTAssertEqual(invokedWithMessagesIDs, messagesIDs)
        XCTAssertEqual(invokedWithConversationIDs, [])
        XCTAssertEqual(sut.state, .init(
            title: title,
            availableActions: .init(
                replyActions: [.reply],
                mailboxItemActions: [.delete],
                moveActions: [.system(.init(localId: .init(value: 1), systemLabel: .inbox))],
                generalActions: [.print]
            )
        ))
    }

    func testState_WhenMailboxTypeIsConversation_ItReturnsAvailableConversationActions() {
        stubbedConversationActions = .init(
            replyActions: [.forward],
            conversationActions: [.labelAs],
            moveActions: [.init(localId: .init(value: 1), name: .inbox, isSelected: .unselected)],
            generalActions: [.saveAsPdf]
        )

        let conversationIDs: [ID] = [.init(value: 8), .init(value: 88)]
        let title = "Conversation title"
        let sut = sut(ids: conversationIDs, type: .conversation, title: title)

        sut.handle(action: .viewAppear)

        XCTAssertEqual(invokedWithMessagesIDs, [])
        XCTAssertEqual(invokedWithConversationIDs, conversationIDs)
        XCTAssertEqual(sut.state, .init(
            title: title,
            availableActions: .init(
                replyActions: [.forward],
                mailboxItemActions: [.labelAs],
                moveActions: [.system(.init(localId: .init(value: 1), systemLabel: .inbox))],
                generalActions: [.saveAsPdf]
            )
        ))
    }

    func testNavigation_WhenLabelAsMailboxActionIsHandled_ItEmitsCorrectNavigation() {
        let sut = sut(ids: [], type: .message, title: .notUsed)

        sut.handle(action: .mailboxItemActionSelected(.labelAs))

        XCTAssertEqual(spiedNavigation, [.labelAs])
    }

    func testNavigation_WhenMessageIsStarred_ItEmitsDismissNavigation() {
        let ids: [ID] = [.init(value: 11),. init(value: 1)]
        let sut = sut(ids: ids, type: .message, title: .notUsed)

        sut.handle(action: .mailboxItemActionSelected(.star))

        XCTAssertEqual(starActionPerformerWrapperSpy.invokedStarMessage, ids)
        XCTAssertEqual(spiedNavigation, [.dismiss])
    }

    func testNavigation_WhenMessageIsUnstarred_ItEmitsDismissNavigation() {
        let ids: [ID] = [.init(value: 11),. init(value: 1)]
        let sut = sut(ids: ids, type: .message, title: .notUsed)

        sut.handle(action: .mailboxItemActionSelected(.unstar))

        XCTAssertEqual(starActionPerformerWrapperSpy.invokedUnstarMessage, ids)
        XCTAssertEqual(spiedNavigation, [.dismiss])
    }

    func testNavigation_WhenConversationIsStarred_ItEmitsDismissNavigation() {
        let ids: [ID] = [.init(value: 11),. init(value: 1)]
        let sut = sut(ids: ids, type: .conversation, title: .notUsed)

        sut.handle(action: .mailboxItemActionSelected(.star))

        XCTAssertEqual(starActionPerformerWrapperSpy.invokedStarConversation, ids)
        XCTAssertEqual(spiedNavigation, [.dismiss])
    }

    func testNavigation_WhenConversationIsUnstarred_ItEmitsDismissNavigation() {
        let ids: [ID] = [.init(value: 11),. init(value: 1)]
        let sut = sut(ids: ids, type: .conversation, title: .notUsed)

        sut.handle(action: .mailboxItemActionSelected(.star))

        XCTAssertEqual(starActionPerformerWrapperSpy.invokedStarConversation, ids)
        XCTAssertEqual(spiedNavigation, [.dismiss])
    }

    private func sut(ids: [ID], type: MailboxItemType, title: String) -> MailboxItemActionSheetModel {
        MailboxItemActionSheetModel(
            input: .init(ids: ids, type: type, title: title),
            mailbox: .init(noPointer: .init()),
            actionsProvider: .init(
                message: { _, ids in
                    self.invokedWithMessagesIDs = ids
                    return self.stubbedMessageActions
                },
                conversation: { _, ids in
                    self.invokedWithConversationIDs = ids
                    return self.stubbedConversationActions
                }
            ), 
            starActionPerformerWrapper: starActionPerformerWrapperSpy.starActionPerformerWrapper,
            mailUserSession: .testData,
            navigation: { navigation in self.spiedNavigation.append(navigation) }
        )
    }

}

class StarActionPerformerWrapperSpy {
    private(set) var invokedStarMessage: [ID] = []
    private(set) var invokedStarConversation: [ID] = []
    private(set) var invokedUnstarMessage: [ID] = []
    private(set) var invokedUnstarConversation: [ID] = []

    private(set) lazy var starActionPerformerWrapper = StarActionPerformerWrapper(
        starMessage: { [weak self] _, messagesIDs in
            self?.invokedStarMessage = messagesIDs
        },
        starConversation: { [weak self] _, conversationsIDs in
            self?.invokedStarConversation = conversationsIDs
        },
        unstarMessage: { [weak self] _, messagesIDs in
            self?.invokedUnstarMessage = messagesIDs
        },
        unstarConversation: { [weak self] _, conversationsIDs in
            self?.invokedUnstarConversation = conversationsIDs
        }
    )
}

extension MailUserSession {

    static var testData: MailUserSession {
        .init(noPointer: .init())
    }

}
