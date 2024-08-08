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

import Foundation
import proton_mail_uniffi

class MailUserSessionSpy: MailUserSessionProtocol {

    private(set) var newSystemLabelsObservedQueryCallback: MailboxLiveQueryUpdatedCallback?
    private(set) var newLabelLabelsObservedQueryCallback: MailboxLiveQueryUpdatedCallback?
    private(set) var newFolderLabelsObservedQueryCallback: MailboxLiveQueryUpdatedCallback?

    let systemFoldersQueryStub = MailLabelsLiveQueryStub()
    let labelsQueryStub = MailLabelsLiveQueryStub()
    let foldersQueryStub = MailLabelsLiveQueryStub()

    // MARK: - MailUserSessionProtocol

    func applicableLabels() throws -> [LocalLabel] {
        fatalError("Not implemented")
    }

    func conversationWithIdAndContext(id: UInt64, labelId: UInt64) async throws -> LocalConversation? {
        fatalError("Not implemented")
    }

    func conversationWithIdWithAllMailContext(id: UInt64) async throws -> LocalConversation? {
        fatalError("Not implemented")
    }

    func conversationWithRemoteId(id: ConversationId) async throws -> LocalConversation? {
        fatalError("Not implemented")
    }

    func executePendingAction() async throws {
        fatalError("Not implemented")
    }

    func executePendingActions() async throws {
        fatalError("Not implemented")
    }

    func filterConversations(filter: ConversationFilter, labelId: UInt64) async throws -> FilteredConversations {
        fatalError("Not implemented")
    }

    func filterMessages(filter: MessageMetadataFilter) async throws -> FilteredMessages {
        fatalError("Not implemented")
    }

    func fork() async throws -> String {
        fatalError("Not implemented")
    }

    func imageForSender(
        mailSettings: MailUserSettings,
        address: String,
        bimiSelector: String?,
        displaySenderImage: Bool,
        size: UInt32?,
        mode: String?,
        format: String?
    ) async throws -> Data? {
        fatalError("Not implemented")
    }

    func initialize(cb: any MailUserSessionInitializationCallback) async throws {
        fatalError("Not implemented")
    }

    func logout() async throws {
        fatalError("Not implemented")
    }

    func messageMetadata(id: UInt64) throws -> LocalMessageMetadata? {
        fatalError("Not implemented")
    }

    func messageMetadataWithRemoteId(remoteId: MessageId) async throws -> LocalMessageMetadata? {
        fatalError("Not implemented")
    }

    func movableFolders() throws -> [LocalLabel] {
        fatalError("Not implemented")
    }

    func newFolderLabelsObservedQuery(cb: MailboxLiveQueryUpdatedCallback) -> MailLabelsLiveQuery {
        newFolderLabelsObservedQueryCallback = cb

        return foldersQueryStub
    }

    func newLabelLabelsObservedQuery(cb: MailboxLiveQueryUpdatedCallback) -> MailLabelsLiveQuery {
        newLabelLabelsObservedQueryCallback = cb

        return labelsQueryStub
    }

    func newSystemLabelsObservedQuery(cb: MailboxLiveQueryUpdatedCallback) -> MailLabelsLiveQuery {
        newSystemLabelsObservedQueryCallback = cb

        return systemFoldersQueryStub
    }

    func pollEvents() async throws {
        fatalError("Not implemented")
    }

}
