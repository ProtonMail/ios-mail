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

import OrderedCollections
import proton_app_uniffi
import SwiftUI

struct MessageDetailsBodyView: View {
    let messageID: ID
    let attachments: [AttachmentDisplayModel]
    let mailbox: Mailbox
    let htmlLoaded: () -> Void
    @Binding var attachmentIDToOpen: ID?
    
    var body: some View {
        VStack(spacing: .zero) {
            MessageBannersView(types: OrderedSet([]), timer: Timer.self)
            MessageBodyAttachmentsView(attachments: attachments, attachmentIDToOpen: $attachmentIDToOpen)
            MessageBodyView(messageId: messageID, mailbox: mailbox, htmlLoaded: htmlLoaded)
        }
    }
}
