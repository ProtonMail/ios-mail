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

import Foundation
import InboxCore
import proton_app_uniffi

enum MessageBodyState {
    case fetching
    case loaded(MessageBody)
    case error(Error)
    case noConnection
}

@MainActor
final class MessageBodyStateStore: ObservableObject {
    enum Action {
        case onLoad
        case displayEmbeddedImages
        case downloadRemoteContent
        case spamMarkAsLegitimate
    }

    @Published var state: MessageBodyState = .fetching
    private let messageID: ID
    private let provider: MessageBodyProvider
    private let legitMessageMarker: LegitMessageMarker

    init(
        messageID: ID,
        mailbox: Mailbox,
        bodyWrapper: RustMessageBodyWrapper,
        actionsWrapper: RustMessageActionsWrapper
    ) {
        self.messageID = messageID
        self.provider = .init(mailbox: mailbox, bodyWrapper: bodyWrapper)
        self.legitMessageMarker = .init(mailbox: mailbox, actionsWrapper: actionsWrapper)
    }

    func handle(action: Action) async {
        switch action {
        case .onLoad:
            await loadMessageBody(with: .none)
        case .displayEmbeddedImages:
            if case let .loaded(body) = state {
                let updatedOptions = body.html.options
                    .copy(\.hideEmbeddedImages, to: false)

                await loadMessageBody(with: updatedOptions)
            }
        case .downloadRemoteContent:
            if case let .loaded(body) = state {
                let updatedOptions = body.html.options
                    .copy(\.hideRemoteImages, to: false)
                
                await loadMessageBody(with: updatedOptions)
            }
        case .spamMarkAsLegitimate:
            if case let .loaded(body) = state {
                await markAsNotSpam(with: body.html.options)
            }
        }
    }

    // MARK: - Private

    private func loadMessageBody(with options: TransformOpts?) async {
        switch await provider.messageBody(forMessageID: messageID, with: options) {
        case .success(let body):
            state = .loaded(body)
        case .noConnectionError:
            state = .noConnection
        case .error(let error):
            state = .error(error)
        }
    }
    
    private func markAsNotSpam(with options: TransformOpts) async {
        _ = await legitMessageMarker.markAsNotSpam(forMessageID: messageID)
        await loadMessageBody(with: options)
    }
}
