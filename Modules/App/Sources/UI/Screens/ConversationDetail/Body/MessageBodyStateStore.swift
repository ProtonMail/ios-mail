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
import proton_app_uniffi

enum MessageBodyState {
    case fetching
    case loaded(MessageBody)
    case error(Error)
    case noConnection
}

final class MessageBodyStateStore: ObservableObject {
    enum Action {
        case onLoad(messageID: ID)
    }

    @Published var state: MessageBodyState = .fetching
    private let provider: MessageBodyProvider

    init(mailbox: Mailbox, bodyWrapper: RustMessageBodyWrapper) {
        self.provider = .init(mailbox: mailbox, bodyWrapper: bodyWrapper)
    }

    @MainActor
    func handle(action: Action) {
        switch action {
        case .onLoad(let messageID):
            loadMessageBody(forMessageID: messageID)
        }
    }

    @MainActor
    private func loadMessageBody(forMessageID messageID: ID) {
        Task {
            switch await provider.messageBody(forMessageID: messageID) {
            case .success(let body):
                state = .loaded(body)
            case .noConnectionError:
                state = .noConnection
            case .error(let error):
                state = .error(error)
            }
        }
    }
}
