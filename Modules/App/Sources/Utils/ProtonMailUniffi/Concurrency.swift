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

import proton_app_uniffi

/**
 Objects provided by the Rust SDK are concurrency safe, however at the moment of writing this, uniffi does
 not support marking reference types as Sendable.

 For this reason we extend the Rust SDK objects and mark them as unchecked Sendable to avoid warnings.
 */

extension ConversationPaginator: @unchecked Sendable {}
extension Draft: @unchecked Sendable {}
extension DecryptedMessage: @unchecked Sendable {}
extension DraftSendResultWatcher: @unchecked Sendable {}
extension LoginFlow: @unchecked Sendable {}
extension Mailbox: @unchecked Sendable {}
extension MessagePaginator: @unchecked Sendable {}
extension NewDraftResult: @unchecked Sendable {}
extension NewMailboxResult: @unchecked Sendable {}
extension PaginateConversationsForLabelResult: @unchecked Sendable {}
extension PaginateMessagesForLabelResult: @unchecked Sendable {}
extension StoredSession: @unchecked Sendable {}
extension UserSettings: @unchecked Sendable {}
extension WatchHandle: @unchecked Sendable {}
extension WatchedMessages: @unchecked Sendable {}
extension WatchedConversations: @unchecked Sendable {}
