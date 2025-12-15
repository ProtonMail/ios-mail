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

struct RustMessageAddressWrapper {
    let block: @Sendable (_ userSession: MailUserSession, _ emailAddress: String) async -> VoidActionResult
    let isSenderBlocked: @Sendable (_ mailbox: Mailbox, _ messageID: ID) async -> BlockedSender

    init(
        block: @escaping @Sendable (MailUserSession, String) async -> VoidActionResult,
        isSenderBlocked: @escaping @Sendable (Mailbox, ID) async -> BlockedSender
    ) {
        self.block = block
        self.isSenderBlocked = isSenderBlocked
    }
}

extension RustMessageAddressWrapper {
    static func productionInstance() -> Self {
        .init(
            block: { session, email in await blockAddress(session: session, email: email) },
            isSenderBlocked: { mailbox, id -> BlockedSender in
                switch await isMessageSenderBlocked(mbox: mailbox, messageId: id) {
                case .ok(.some(true)):
                    .yes
                case .ok(.some(false)):
                    .no
                case .ok(.none), .error:
                    .notLoaded
                }
            }
        )
    }
}
