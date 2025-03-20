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

struct LegitMessageMarker {
    private let markMessageHam: @Sendable (_ messageID: ID) async -> VoidActionResult
    
    init(mailbox: Mailbox, actionsWrapper: RustMessageActionsWrapper) {
        self.markMessageHam = { messageID in await actionsWrapper.markMessageHam(mailbox, messageID) }
    }

    func markAsNotSpam(forMessageID messageID: ID) async -> Result<Void, ActionError> {
        switch await markMessageHam(messageID) {
        case .ok:
            return .success(())
        case .error(let actionError):
            return .failure(actionError)
        }
    }
}

struct RustMessageActionsWrapper {
    let markMessageHam: @Sendable (_ mailbox: Mailbox, _ messageID: Id) async -> VoidActionResult
    
    init(markMessageHam: @escaping @Sendable (Mailbox, Id) async -> VoidActionResult) {
        self.markMessageHam = markMessageHam
    }
}

extension RustMessageActionsWrapper {

    static func productionInstance() -> Self {
        .init(markMessageHam: { mailbox, id in
            // FIXME: markMessagesHam takes session as first argument instead of mailbox
            .ok
        })
    }

}
