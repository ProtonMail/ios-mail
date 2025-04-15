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
import InboxCoreUI
import proton_app_uniffi

final class MessageBodyStateStore: StateStore {
    var makeTask = Task<Void, Never>.init(priority:operation:)
    
    enum Action {
        case onLoad
        case displayEmbeddedImages
        case downloadRemoteContent
        case markAsLegitimate
        case markAsLegitimateConfirmed(PhishingConfirmationAlertAction)
        case unblockSender(emailAddress: String)
    }
    
    struct State: Copying {
        enum Body {
            case fetching
            case loaded(MessageBody)
            case error(Error)
            case noConnection
        }
        
        var body: Body
        var alert: AlertModel?
    }

    @Published var state = State(body: .fetching, alert: .none)
    private let messageID: ID
    private let provider: MessageBodyProvider
    private let legitMessageMarker: LegitMessageMarker
    private let senderUnblocker: SenderUnblocker
    private let toastStateStore: ToastStateStore

    init(messageID: ID, mailbox: Mailbox, wrapper: RustMessageBodyWrapper, toastStateStore: ToastStateStore) {
        self.messageID = messageID
        self.provider = .init(mailbox: mailbox, wrapper: wrapper)
        self.legitMessageMarker = .init(mailbox: mailbox, wrapper: wrapper)
        self.senderUnblocker = .init(mailbox: mailbox, wrapper: wrapper)
        self.toastStateStore = toastStateStore
    }

    @MainActor
    func handle(action: Action) async {
        switch action {
        case .onLoad:
            await loadMessageBody(with: .none)
        case .displayEmbeddedImages:
            if case let .loaded(body) = state.body {
                let updatedOptions = body.html.options
                    .copy(\.hideEmbeddedImages, to: false)

                await loadMessageBody(with: updatedOptions)
            }
        case .downloadRemoteContent:
            if case let .loaded(body) = state.body {
                let updatedOptions = body.html.options
                    .copy(\.hideRemoteImages, to: false)
                
                await loadMessageBody(with: updatedOptions)
            }
        case .markAsLegitimate:
            let alertModel: AlertModel = .confirmation { [weak self] action in
                
                self?.markAsLegitimateConfirmed(action: action)
            }
            state = state.copy(\.alert, to: alertModel)
        case .markAsLegitimateConfirmed(let action):
            if case let .loaded(body) = state.body {
                state = state.copy(\.alert, to: nil)

                switch action {
                case .cancel:
                    break
                case .confirm:
                    await markAsLegitimate(with: body.html.options)
                }
            }
        case .unblockSender(let emailAddress):
            if case let .loaded(body) = state.body {
                await unblockSender(emailAddress: emailAddress, with: body.html.options)
            }
        }
    }

    // MARK: - Private
    
    private func markAsLegitimateConfirmed(action: PhishingConfirmationAlertAction) {
        _ = makeTask(nil) { [weak self] in
            await self?.handle(action: .markAsLegitimateConfirmed(action))
        }
    }

    @MainActor
    private func loadMessageBody(with options: TransformOpts?) async {
        switch await provider.messageBody(forMessageID: messageID, with: options) {
        case .success(let body):
            state = state.copy(\.body, to: .loaded(body))
        case .noConnectionError:
            state = state.copy(\.body, to: .noConnection)
        case .error(let error):
            state = state.copy(\.body, to: .error(error))
        }
    }
    
    @MainActor
    private func markAsLegitimate(with options: TransformOpts) async {
        switch await legitMessageMarker.markAsLegitimate(forMessageID: messageID) {
        case .ok:
            await loadMessageBody(with: options)
        case .error(let error):
            toastStateStore.present(toast: .error(message: error.localizedDescription))
        }
    }
    
    @MainActor
    private func unblockSender(emailAddress: String, with options: TransformOpts) async {
        switch await senderUnblocker.unblock(emailAddress: emailAddress) {
        case .ok:
            await loadMessageBody(with: options)
        case .error(let error):
            toastStateStore.present(toast: .error(message: error.localizedDescription))
        }
    }
}
