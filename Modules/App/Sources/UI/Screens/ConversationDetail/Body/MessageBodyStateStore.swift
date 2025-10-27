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
    enum Action {
        case onLoad
        case displayEmbeddedImages
        case downloadRemoteContent
        case markAsLegitimate
        case markAsLegitimateConfirmed(LegitMessageConfirmationAlertAction)
        case unblockSender(emailAddress: String)
        case unsubscribeNewsletter
        case unsubscribeNewsletterConfirmed(UnsubscribeNewsletterAlertAction)
        case refreshBanners
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
    private let backOnlineActionExecutor: BackOnlineActionExecuting

    init(
        messageID: ID,
        mailbox: Mailbox,
        wrapper: RustMessageBodyWrapper,
        toastStateStore: ToastStateStore,
        backOnlineActionExecutor: BackOnlineActionExecuting
    ) {
        self.messageID = messageID
        self.provider = .init(mailbox: mailbox, wrapper: wrapper)
        self.legitMessageMarker = .init(mailbox: mailbox, wrapper: wrapper)
        self.senderUnblocker = .init(mailbox: mailbox, wrapper: wrapper)
        self.toastStateStore = toastStateStore
        self.backOnlineActionExecutor = backOnlineActionExecutor
    }

    func handle(action: Action) async {
        switch action {
        case .onLoad:
            await loadMessageBody(with: .init())
        case .refreshBanners:
            if case let .loaded(body) = state.body {
                await loadMessageBody(with: body.html.options)
            }
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
            let alertModel: AlertModel = .legitMessageConfirmation { [weak self] action in
                await self?.handle(action: .markAsLegitimateConfirmed(action))
            }
            state = state.copy(\.alert, to: alertModel)
        case .markAsLegitimateConfirmed(let action):
            state = state.copy(\.alert, to: nil)

            if case let .loaded(body) = state.body, case .markAsLegitimate = action {
                await markAsLegitimate(with: body.html.options)
            }
        case .unblockSender(let emailAddress):
            if case let .loaded(body) = state.body {
                await unblockSender(emailAddress: emailAddress, with: body.html.options)
            }
        case .unsubscribeNewsletter:
            let alertModel: AlertModel = .unsubcribeNewsletter { [weak self] action in
                await self?.handle(action: .unsubscribeNewsletterConfirmed(action))
            }
            state = state.copy(\.alert, to: alertModel)
        case .unsubscribeNewsletterConfirmed(let action):
            state = state.copy(\.alert, to: nil)

            if case let .loaded(body) = state.body, case .unsubscribe = action {
                await unsubscribeNewsletter(with: body.newsletterService, options: body.html.options)
            }
        }
    }

    // MARK: - Private

    private func loadMessageBody(with options: TransformOpts) async {
        switch await provider.messageBody(forMessageID: messageID, with: options) {
        case .success(let body):
            state = state.copy(\.body, to: .loaded(body))
        case .noConnectionError:
            state = state.copy(\.body, to: .noConnection)
            reloadContentWhenBackOnline(options: options)
        case .error(let error):
            state = state.copy(\.body, to: .error(error))
        }
    }

    private func reloadContentWhenBackOnline(options: TransformOpts) {
        backOnlineActionExecutor.execute { [weak self] in
            guard let self else { return }
            self.state = self.state.copy(\.body, to: .fetching)
            await self.loadMessageBody(with: options)
        }
    }

    private func markAsLegitimate(with options: TransformOpts) async {
        await executeAndReloadMessage(
            operation: { await legitMessageMarker.markAsLegitimate(forMessageID: messageID) },
            with: options
        )
    }

    private func unblockSender(emailAddress: String, with options: TransformOpts) async {
        await executeAndReloadMessage(
            operation: { await senderUnblocker.unblock(emailAddress: emailAddress) },
            with: options
        )
    }

    private func unsubscribeNewsletter(with newsletterService: UnsubscribeNewsletter, options: TransformOpts) async {
        await executeAndReloadMessage(
            operation: { await newsletterService.unsubscribeFromNewsletter() },
            with: options,
            successToastMessage: L10n.MessageBanner.UnsubscribeNewsletter.Toast.success.string
        )
    }

    private func executeAndReloadMessage(
        operation: () async -> VoidActionResult,
        with options: TransformOpts,
        successToastMessage: String? = nil
    ) async {
        switch await operation() {
        case .ok:
            await loadMessageBody(with: options)
            if let successToastMessage {
                toastStateStore.present(toast: .information(message: successToastMessage))
            }
        case .error(let error):
            toastStateStore.present(toast: .error(message: error.localizedDescription))
        }
    }
}
