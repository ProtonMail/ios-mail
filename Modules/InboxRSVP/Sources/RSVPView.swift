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

import InboxCore
import InboxCoreUI
import proton_app_uniffi
import ProtonUIFoundations
import SwiftUI

public struct RSVPView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.pasteboard) var pasteboard
    @EnvironmentObject var toastStateStore: ToastStateStore
    private let serviceProvider: RsvpEventServiceProvider
    private let draftPresenter: RecipientDraftPresenter

    public init(serviceProvider: RsvpEventServiceProvider, draftPresenter: RecipientDraftPresenter) {
        self.serviceProvider = serviceProvider
        self.draftPresenter = draftPresenter
    }

    public var body: some View {
        StoreView(
            store: RSVPStateStore(
                serviceProvider: serviceProvider,
                openURL: openURL,
                toastStateStore: toastStateStore,
                pasteboard: pasteboard,
                draftPresenter: draftPresenter
            )
        ) { state, store in
            Group {
                switch state {
                case .loading:
                    RSVPSkeletonView()
                case .loadFailed:
                    RSVPErrorRetryView { store.handle(action: .retry) }
                case .loaded(let event), .answering(let event):
                    RSVPEventView(
                        event: event,
                        isAnswering: state.isAnswering,
                        action: { action in handle(action: action, with: store) }
                    )
                }
            }
            .onLoad { store.handle(action: .onLoad) }
        }
    }

    // MARK: - Private

    private func handle(action: RSVPEventView.Action, with store: RSVPStateStore) {
        switch action {
        case .answerSelected(let selectedAnswer):
            store.handle(action: .answer(selectedAnswer))
        case .calendarIconTapped:
            store.handle(action: .calendarIconTapped)
        case .participantOptionSelected(let option, let email):
            switch option {
            case .copyAddress:
                store.handle(action: .copyAddress(email: email))
            case .newMessage:
                store.handle(action: .newMessage(email: email))
            }
        }
    }
}

private extension RSVPStateStore.State {
    var isAnswering: Bool {
        guard case .answering = self else {
            return false
        }

        return true
    }
}
