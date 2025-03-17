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

extension BackgroundExecutionHandle: @unchecked @retroactive Sendable {}
extension ConversationScroller: @unchecked @retroactive Sendable {}
extension Draft: @unchecked @retroactive Sendable {}
extension DecryptedMessage: @unchecked @retroactive Sendable {}
extension DraftSendResultWatcher: @unchecked @retroactive Sendable {}
extension EventLoopErrorObserverHandle: @unchecked @retroactive Sendable {}
extension LoginFlow: @unchecked @retroactive Sendable {}
extension Mailbox: @unchecked @retroactive Sendable {}
extension MessageScroller: @unchecked @retroactive Sendable {}
extension NewDraftResult: @unchecked @retroactive Sendable {}
extension NewMailboxResult: @unchecked @retroactive Sendable {}
extension NewInboxMailboxResult: @unchecked @retroactive Sendable {}
extension ScrollConversationsForLabelResult: @unchecked @retroactive Sendable {}
extension ScrollMessagesForLabelResult: @unchecked @retroactive Sendable {}
extension StoredSession: @unchecked @retroactive Sendable {}
extension WatchHandle: @unchecked @retroactive Sendable {}
extension WatchedMessages: @unchecked @retroactive Sendable {}
extension WatchedConversations: @unchecked @retroactive Sendable {}
