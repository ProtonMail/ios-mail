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

import class proton_app_uniffi.Mailbox
import SwiftUI

struct AsyncMessageBodyView<Content>: View where Content: View {
    @StateObject private var bodyLoader: MessageBodyLoader
    @ViewBuilder private var content: (MessageBodyLoader.MessageBodyState) -> Content

    private let messageId: ID

    init(
        messageId: ID,
        mailbox: Mailbox,
        @ViewBuilder content: @escaping (MessageBodyLoader.MessageBodyState) -> Content
    ) {
        self.messageId = messageId
        _bodyLoader = .init(wrappedValue: .init(mailbox: mailbox))
        self.content = content
    }

    var body: some View {
        content(bodyLoader.body)
            .onAppear() {
                Task {
                    await bodyLoader.loadBody(for: messageId)
                }
            }
    }
}

final class MessageBodyLoader: ObservableObject {
    enum MessageBodyState {
        case fetching
        case value(_ value: MessageBody)
        case error(Error)
    }

    @Published var body: MessageBodyState = .fetching
    private let provider: MessageBodyProviding

    init(mailbox: Mailbox) {
        self.provider = MessageBodyProvider(mailbox: mailbox)
    }

    @MainActor
    func loadBody(for messageId: ID) async {
        guard let bodyValue = await provider.messageBody(for: messageId) else {
            body = .fetching // TODO: error
            return
        }
        body = .value(bodyValue)
    }
}
