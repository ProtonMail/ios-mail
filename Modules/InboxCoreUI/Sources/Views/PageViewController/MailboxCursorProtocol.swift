//
// Copyright (c) 2025 Proton Technologies AG
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

public enum CursorEntry {
    case conversationEntry(Conversation)
    case messageEntry(Message)
}

public enum MailboxCursorPeekNextResult {
    case some(CursorEntry)
    case none
    case unknown
}

public protocol MailboxCursorProtocol {
    func fetchNext() async throws(MailScrollerError) -> CursorEntry?
    func gotoNext()
    func gotoPrev()
    func peekNext() -> MailboxCursorPeekNextResult
    func peekPrev() -> CursorEntry?
}

extension MailConversationCursor: MailboxCursorProtocol {
    public func fetchNext() async throws(MailScrollerError) -> CursorEntry? {
        try await fetchNext().get().map(CursorEntry.conversationEntry)
    }

    public func peekNext() -> MailboxCursorPeekNextResult {
        let result: NextMailCursorConversation = peekNext()

        switch result {
        case .none:
            return .none
        case .some(let cursorEntry):
            return .some(.conversationEntry(cursorEntry))
        case .maybe:
            return .unknown
        }
    }

    public func peekPrev() -> CursorEntry? {
        peekPrev().map(CursorEntry.conversationEntry)
    }
}

extension MailMessageCursor: MailboxCursorProtocol {
    public func fetchNext() async throws(MailScrollerError) -> CursorEntry? {
        try await fetchNext().get().map(CursorEntry.messageEntry)
    }

    public func peekNext() -> MailboxCursorPeekNextResult {
        let result: NextMailCursorMessage = peekNext()

        switch result {
        case .none:
            return .none
        case .some(let cursorEntry):
            return .some(.messageEntry(cursorEntry))
        case .maybe:
            return .unknown
        }
    }

    public func peekPrev() -> CursorEntry? {
        peekPrev().map(CursorEntry.messageEntry)
    }
}
