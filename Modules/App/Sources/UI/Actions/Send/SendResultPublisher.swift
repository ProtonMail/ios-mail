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

import Combine
import Foundation
import InboxCore
import proton_app_uniffi

/**
 `SendResultPublisher` observes any send result published from the SDK and republishes
 the result mapped to `SendResultInfo`.
*/
final class SendResultPublisher: Sendable, ObservableObject {
    private let subject = PassthroughSubject<SendResultInfo, Never>()
    var results: AnyPublisher<SendResultInfo, Never> {
        subject.eraseToAnyPublisher()
    }

    private let userSession: MailUserSession
    private var watcher: DraftSendResultWatcher!
    private let sendCallback: DraftSendResultCallbackWrapper = .init()

    init(userSession: MailUserSession) {
        self.userSession = userSession
        Task {
            await initialise()
            sendCallback.delegate = { [weak self] results in self?.publish(results: results) }
        }
    }

    private func initialise() async {
        switch await newDraftSendWatcher(session: userSession, callback: sendCallback) {
        case .ok(let watcher):
            self.watcher = watcher
            AppLogger.log(message: "send result watcher started", category: .send)
        case .error(let error):
            AppLogger.log(error: error, category: .send)
        }
    }

    private func publish(results: [DraftSendResult]) {
        for result in results {
            let messageId = result.messageId
            switch result.origin {
            case .save:
                // TODO:
                break
            case .saveBeforeSend, .send:
                AppLogger.log(message: "send result received \(result)", category: .send)
                switch result.error {
                case .success:
                    subject.send(.init(messageId: messageId, type: .sent))
                case .failure(let draftError):
                    subject.send(.init(messageId: messageId, type: .error(draftError.localizedDescription)))
                }
            }
        }
    }
}

final class DraftSendResultCallbackWrapper: @unchecked Sendable, DraftSendResultCallback {
    var delegate: (([DraftSendResult]) -> Void)?
    func onNewSendResult(details: [DraftSendResult]) {
        delegate?(details)
    }
}
