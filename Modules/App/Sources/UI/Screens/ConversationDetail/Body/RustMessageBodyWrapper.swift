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

struct RustMessageBodyWrapper {
    let messageBody: @Sendable (_ mailbox: Mailbox, _ messageID: Id) async -> GetMessageBodyResult
    let markMessageHam: @Sendable (_ mailbox: Mailbox, _ messageID: Id) async -> VoidActionResult
    let unblockSender: @Sendable (_ mailbox: Mailbox, _ addressID: Id) async -> VoidActionResult
    
    init(
        messageBody: @escaping @Sendable (Mailbox, Id) async -> GetMessageBodyResult,
        markMessageHam: @escaping @Sendable (Mailbox, Id) async -> VoidActionResult,
        unblockSender: @escaping @Sendable (Mailbox, Id) async -> VoidActionResult
    ) {
        self.messageBody = messageBody
        self.markMessageHam = markMessageHam
        self.unblockSender = unblockSender
    }
}

extension RustMessageBodyWrapper {

    static func productionInstance() -> Self {
        .init(
            messageBody: { mailbox, id in await getMessageBody(mbox: mailbox, id: id) },
            markMessageHam: { mailbox, id in await markMessagesHam(mailbox: mailbox, messageId: id) },
            unblockSender: { mailbox, addressID in await unblockAddress(mailbox: mailbox, addressId: addressID) }
        )
    }

}
