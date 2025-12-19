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

import InboxCore
import SwiftUI
import proton_app_uniffi

@MainActor
final class AttachmentViewLoader: ObservableObject {
    @Published private(set) var state: State
    private let mailbox: MailboxProtocol
    private let queue: DispatchQueue = DispatchQueue(label: "\(Bundle.defaultIdentifier).AttachmentViewLoader")

    init(state: State = .loading, mailbox: MailboxProtocol) {
        self.state = state
        self.mailbox = mailbox
    }

    func load(attachmentId: ID) async {
        switch await mailbox.getAttachment(localAttachmentId: attachmentId) {
        case .ok(let result):
            let url = URL(fileURLWithPath: result.dataPath)

            updateState(.attachmentReady(url))
        case .error(let error):
            updateState(.error(error))
        }
    }

    private func updateState(_ newState: State) {
        queue.sync {
            state = newState
        }
    }
}

extension AttachmentViewLoader {
    enum State {
        case loading
        case attachmentReady(URL)
        case error(ActionError)
    }
}
