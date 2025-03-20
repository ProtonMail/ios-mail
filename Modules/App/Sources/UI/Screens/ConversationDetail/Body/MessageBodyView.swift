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

struct MessageBodyView: View {
    let messageID: ID
    let attachments: [AttachmentDisplayModel]
    let mailbox: Mailbox
    let htmlLoaded: () -> Void
    @Binding var attachmentIDToOpen: ID?
    
    @StateObject var store: MessageBodyStateStore
    
    init(
        messageID: ID,
        attachments: [AttachmentDisplayModel],
        mailbox: Mailbox,
        attachmentIDToOpen: Binding<ID?>,
        htmlLoaded: @escaping () -> Void
    ) {
        self.messageID = messageID
        self.attachments = attachments
        self.mailbox = mailbox
        self._attachmentIDToOpen = attachmentIDToOpen
        self.htmlLoaded = htmlLoaded
        _store = .init(
            wrappedValue: .init(messageID: messageID, mailbox: mailbox, bodyWrapper: .productionInstance())
        )
    }
    
    var body: some View {
        VStack(spacing: .zero) {
            if case .loaded(let body) = store.state, !body.banners.isEmpty {
                MessageBannersView(
                    types: OrderedSet(body.banners),
                    timer: Timer.self,
                    action: { action in
                        switch action {
                        case .displayEmbeddedImagesTapped:
                            handle(action: .displayEmbeddedImages)
                        case .downloadRemoteContentTapped:
                            handle(action: .downloadRemoteContent)
                        }
                    }
                )
            }
            if !attachments.isEmpty {
                MessageBodyAttachmentsView(attachments: attachments, attachmentIDToOpen: $attachmentIDToOpen)
            }
            MessageBodyHTMLView(messageId: messageID, messageBody: store.state, htmlLoaded: htmlLoaded)
        }
        .onLoad { handle(action: .onLoad) }
    }
    
    private func handle(action: MessageBodyStateStore.Action) {
        Task {
            await store.handle(action: action)
        }
    }
}
