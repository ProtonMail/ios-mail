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

@preconcurrency import Combine
import Foundation
import InboxCore
import proton_app_uniffi

/**
 `SendResultPublisher` observes any send result published from the SDK and republishes
 the result mapped to `SendResultInfo`.
*/
@MainActor
public final class SendResultPublisher: Sendable, ObservableObject {
    private let subject = PassthroughSubject<SendResultInfo, Never>()
    public var results: AnyPublisher<SendResultInfo, Never> {
        subject.eraseToAnyPublisher()
    }

    private let userSession: MailUserSession
    private var watcher: DraftSendResultWatcher!

    public init(userSession: MailUserSession) {
        self.userSession = userSession
        Task {
            await initialise()
        }
    }

    private func initialise() async {
        let sendCallback = DraftSendResultCallbackWrapper { [weak self] results in
            Task { @MainActor in
                self?.publish(results: results)
            }
        }

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
            AppLogger.log(message: "send result received: \(result)", category: .send)
            let messageId = result.messageId
            switch result.origin {
            // TODO: pending discussion about `DraftSendResult` scenarios
            case .attachmentUpload:
                break
            case .save:
                break
            case .saveBeforeSend:
                break
            case .send:
                switch result.error {
                case .success(let secondsUntilCancel, _):
                    subject.send(.init(messageId: messageId, type: .sent(secondsToUndo: secondsUntilCancel)))
                case .failure(let draftError):
                    subject.send(.init(messageId: messageId, type: .error(draftError)))
                }
            case .scheduleSend:
                switch result.error {
                case .success(_, let deliveryTime):
                    let date = Date(timeIntervalSince1970: TimeInterval(deliveryTime))
                    subject.send(.init(messageId: messageId, type: .scheduled(deliveryTime: date)))
                case .failure(let draftError):
                    subject.send(.init(messageId: messageId, type: .error(draftError)))
                }
            }
        }
    }
}

final class DraftSendResultCallbackWrapper: Sendable, DraftSendResultCallback {
    typealias Delegate = @Sendable ([DraftSendResult]) -> Void

    private let delegate: Delegate

    init(delegate: @escaping Delegate) {
        self.delegate = delegate
    }

    func onNewSendResult(details: [DraftSendResult]) {
        delegate(details)
    }
}
