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

struct StarActionPerformerWrapper {
    let starMessage: (_ session: MailUserSession, _ ids: [ID]) async throws -> Void
    let starConversation: (_ session: MailUserSession, _ ids: [ID]) async throws -> Void

    let unstarMessage: (_ session: MailUserSession, _ ids: [ID]) async throws -> Void
    let unstarConversation: (_ session: MailUserSession, _ ids: [ID]) async throws -> Void
}

extension StarActionPerformerWrapper {

    static func productionInstance() -> StarActionPerformerWrapper {
        .init(
            starMessage: starMessages,
            starConversation: starConversations,
            unstarMessage: unstarMessages,
            unstarConversation: unstarConversations
        )
    }

}

struct StarActionPerformer {
    private let mailUserSession: MailUserSession
    private let starActionPerformerWrapper: StarActionPerformerWrapper

    init(mailUserSession: MailUserSession, starActionPerformerWrapper: StarActionPerformerWrapper) {
        self.mailUserSession = mailUserSession
        self.starActionPerformerWrapper = starActionPerformerWrapper
    }

    func unstar(itemsWithIDs ids: Set<ID>, itemType: MailboxItemType, completion: (() -> Void)? = nil) {
        Task {
            await unstar(itemsWithIDs: ids, itemType: itemType)
            completion?()
        }
    }

    func star(itemsWithIDs ids: Set<ID>, itemType: MailboxItemType, completion: (() -> Void)? = nil) {
        Task {
            await star(itemsWithIDs: ids, itemType: itemType)
            completion?()
        }
    }

    // MARK: - Private

    private func star(itemsWithIDs ids: Set<ID>, itemType: MailboxItemType) async {
        switch itemType {
        case .message:
            try! await starMessages(session: mailUserSession, messageIds: ids.array)
        case .conversation:
            try! await starConversations(session: mailUserSession, ids: ids.array)
        }
    }

    private func unstar(itemsWithIDs ids: Set<ID>, itemType: MailboxItemType) async {
        switch itemType {
        case .message:
            try! await unstarMessages(session: mailUserSession, messageIds: ids.array)
        case .conversation:
            try! await unstarConversations(session: mailUserSession, ids: ids.array)
        }
    }
}

private extension Set {

    var array: Array<Element> {
        Array(self)
    }

}
