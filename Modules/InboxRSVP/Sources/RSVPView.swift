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

import SwiftUI

struct RSVPView: View {
    @StateObject private var store: RSVPStateStore

    init(serviceProvider: RsvpEventId) {
        _store = StateObject(wrappedValue: .init(serviceProvider: serviceProvider))
    }

    var body: some View {
        content
            .onLoad { handle(action: .onLoad) }
    }

    // MARK: - Private

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .loading:
            RSVPSkeletonView()
        case .loadFailed:
            RSVPErrorView { handle(action: .retry) }
        case .loaded(let data):
            eventDetailsView(with: data.details, isAnswering: false)
        case .answering(let data):
            eventDetailsView(with: data.details, isAnswering: true)
        }
    }

    @ViewBuilder
    private func eventDetailsView(with eventDetails: RsvpEventDetails, isAnswering: Bool) -> some View {
        RSVPEventView(
            eventDetails: eventDetails,
            isAnswering: isAnswering,
            onAnswerSelected: { selectedAnswer in handle(action: .answer(selectedAnswer)) }
        )
    }

    private func handle(action: RSVPStateStore.Action) {
        Task {
            await store.handle(action: action)
        }
    }
}
