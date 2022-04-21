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

import CoreData
import Foundation
@testable import ProtonMail
import ProtonCore_TestingToolkit

class MockConversationProvider: ConversationProvider {
    func fetchConversation(by conversationID: ConversationID) -> ConversationEntity? {
        return nil
    }

    func findConversationIDsToApplyLabels(conversations: [ConversationEntity], labelID: LabelID) -> [ConversationID] {
        return []
    }

    func findConversationIDSToRemoveLabels(conversations: [ConversationEntity], labelID: LabelID) -> [ConversationID] {
        return []
    }

    @FuncStub(MockConversationProvider.fetchConversationCounts(addressID:completion:)) var callFetchConversationCounts
    func fetchConversationCounts(addressID: String?, completion: ((Result<Void, Error>) -> Void)?) {
        callFetchConversationCounts(addressID, completion)
        completion?(.success)
    }

    @FuncStub(MockConversationProvider.fetchConversations(for:before:unreadOnly:shouldReset:completion:)) var callFetchConversations
    func fetchConversations(for labelID: LabelID, before timestamp: Int, unreadOnly: Bool, shouldReset: Bool, completion: ((Result<Void, Error>) -> Void)?) {
        callFetchConversations(labelID, timestamp, unreadOnly, shouldReset, completion)
        completion?(.success)
    }

    func fetchConversations(with conversationIDs: [ConversationID], completion: ((Result<Void, Error>) -> Void)?) {

    }

    @FuncStub(MockConversationProvider.fetchConversation(with:includeBodyOf:completion:)) var callFetchConversation
    func fetchConversation(with conversationID: ConversationID, includeBodyOf messageID: MessageID?, completion: ((Result<Conversation, Error>) -> Void)?) {
        callFetchConversation(conversationID, messageID, completion)
        completion?(.success(Conversation()))
    }

    @FuncStub(MockConversationProvider.deleteConversations(with:labelID:completion:)) var callDelete
    func deleteConversations(with conversationIDs: [ConversationID], labelID: LabelID, completion: ((Result<Void, Error>) -> Void)?) {
        callDelete(conversationIDs, labelID, completion)
        completion?(.success)
    }

    @FuncStub(MockConversationProvider.markAsRead(conversationIDs:labelID:completion:)) var callMarkAsRead
    func markAsRead(conversationIDs: [ConversationID], labelID: LabelID, completion: ((Result<Void, Error>) -> Void)?) {
        callMarkAsRead(conversationIDs, labelID, completion)
        completion?(.success)
    }

    @FuncStub(MockConversationProvider.markAsUnread(conversationIDs:labelID:completion:)) var callMarkAsUnRead
    func markAsUnread(conversationIDs: [ConversationID], labelID: LabelID, completion: ((Result<Void, Error>) -> Void)?) {
        callMarkAsUnRead(conversationIDs, labelID, completion)
        completion?(.success)

    }

    @FuncStub(MockConversationProvider.label(conversationIDs:as:isSwipeAction:completion:)) var callLabel
    func label(conversationIDs: [ConversationID], as labelID: LabelID, isSwipeAction: Bool, completion: ((Result<Void, Error>) -> Void)?) {
        callLabel(conversationIDs, labelID, isSwipeAction, completion)
        completion?(.success)
    }

    @FuncStub(MockConversationProvider.unlabel(conversationIDs:as:isSwipeAction:completion:)) var callUnlabel
    func unlabel(conversationIDs: [ConversationID], as labelID: LabelID, isSwipeAction: Bool, completion: ((Result<Void, Error>) -> Void)?) {
        callUnlabel(conversationIDs, labelID, isSwipeAction, completion)
        completion?(.success)
    }

    @FuncStub(MockConversationProvider.move(conversationIDs:from:to:isSwipeAction:completion:)) var callMove
    func move(conversationIDs: [ConversationID], from previousFolderLabel: LabelID, to nextFolderLabel: LabelID, isSwipeAction: Bool, completion: ((Result<Void, Error>) -> Void)?) {
        callMove(conversationIDs, previousFolderLabel, nextFolderLabel, isSwipeAction, completion)
        completion?(.success)
    }

    func cleanAll() {

    }

    @FuncStub(MockConversationProvider.fetchLocalConversations, initialReturn: []) var callFetchLocal
    func fetchLocalConversations(withIDs selected: NSMutableSet, in context: NSManagedObjectContext) -> [Conversation] {
        return callFetchLocal(selected, context)
    }

}
