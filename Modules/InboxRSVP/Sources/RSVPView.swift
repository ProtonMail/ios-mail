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

import InboxCoreUI
import proton_app_uniffi
import SwiftUI

public struct RSVPView: View {
    @Environment(\.openURL) var openURL
    private let serviceProvider: RsvpEventServiceProvider

    public init(serviceProvider: RsvpEventServiceProvider) {
        self.serviceProvider = serviceProvider
    }

    public var body: some View {
        StoreView(store: RSVPStateStore(serviceProvider: serviceProvider, openURL: openURL)) { state, store in
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
        case .participantOptionSelected:
            // FIXME: To implement
            break
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
