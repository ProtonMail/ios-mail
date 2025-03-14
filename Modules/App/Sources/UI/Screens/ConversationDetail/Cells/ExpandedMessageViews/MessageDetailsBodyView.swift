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
    
    @StateObject var store: MessageBodyLoader
    
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
        _store = .init(wrappedValue: .init(mailbox: mailbox))
    }
    
    var body: some View {
        VStack(spacing: .zero) {
            MessageBannersView(types: OrderedSet([]), timer: Timer.self)
            MessageBodyAttachmentsView(attachments: attachments, attachmentIDToOpen: $attachmentIDToOpen)
            MessageBodyView(messageId: messageID, messageBody: store.state, htmlLoaded: htmlLoaded)
        }
        .task {
            await store.loadBody(for: messageID)
        }
    }
}

final class MessageBodyLoader: ObservableObject {
    enum MessageBodyState {
        case fetching
        case loaded(MessageBody)
        case error(Error)
        case noConnection
    }

    @Published var state: MessageBodyState = .fetching
    private let provider: MessageBodyProviding

    init(mailbox: Mailbox) {
        self.provider = MessageBodyProvider(mailbox: mailbox)
    }

    @MainActor
    func loadBody(for messageId: ID) async {
        switch await provider.messageBody(for: messageId) {
        case .loaded(let body):
            self.state = .loaded(body)
        case .noConnection:
            self.state = .noConnection
        case .error(let error):
            self.state = .error(error)
        }
    }
}
