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
import SwiftUI

final class RSVPStateStore: ObservableObject {
    /// Represents the full UI state for RSVP data, including loading status,
    /// the fetched event, and its detailed metadata.
    ///
    /// - Important: When `mode == .loaded`, both `rsvpEvent` and `eventDetails` are guaranteed to be non-nil.
    ///
    /// - Note:
    /// `rsvpEvent` and `eventDetails` are not stored as associated values in `Mode`
    /// because SwiftUI cannot create `@Binding` to values inside enum cases.
    /// By keeping them as separate properties, we can:
    ///   - Bind directly to `eventDetails` in the UI
    ///   - Avoid complex unwrapping or custom binding logic
    ///   - Maintain compatibility with SwiftUI’s reactive updates
    struct State: Copying {
        /// The current phase of the view or data loading lifecycle.
        enum Mode: Equatable {
            /// Actively loading data
            case loading
            /// Successfully loaded data
            case loaded
            /// Failed to load
            case failed
        }

        /// Current mode (loading, loaded, or failed).
        var mode: Mode = .loading

        /// The loaded event, if available.
        /// - Safe to unwrap when `mode == .loaded`.
        var rsvpEvent: RsvpEvent?

        /// The details associated with the loaded event, if available.
        /// - Safe to unwrap when `mode == .loaded`.
        var eventDetails: RsvpEventDetails?
    }

    private let rsvpID: RsvpEventId
    @Published var state: State

    enum Action {
        case onLoad
        case retry
        case answer(RsvpAnswer)
    }

    init(rsvpID: RsvpEventId, state: State = .init()) {
        self.rsvpID = rsvpID
        self.state = state
    }

    @MainActor
    func handle(action: Action) async {
        switch action {
        case .onLoad, .retry:
            await loadEventDetails()
        case .answer(let status):
            if case .loaded = state.mode, let rsvpEvent = state.rsvpEvent {
                await answer(with: status, for: rsvpEvent)
            }
        }
    }

    @MainActor
    private func loadEventDetails() async {
        updateState(mode: .loading, event: .none, details: .none)

        if let event = await rsvpID.fetch(), case .ok(let details) = event.details() {
            updateState(mode: .loaded, event: event, details: details)
        } else {
            updateState(mode: .failed, event: .none, details: .none)
        }
    }

    @MainActor
    private func answer(with answer: RsvpAnswer, for event: RsvpEvent) async {
        let answerResult = await event.answer(answer: answer)

        switch (answerResult, event.details()) {
        case (.ok, .ok(let details)), (.error, .ok(let details)):
            updateState(mode: .loaded, event: event, details: details)
        case (.ok, .error), (.error, .error):
            updateState(mode: .failed, event: .none, details: .none)
        }
    }

    @MainActor
    func updateState(mode: State.Mode, event: RsvpEvent?, details: RsvpEventDetails?) {
        state =
            state
            .copy(\.mode, to: mode)
            .copy(\.rsvpEvent, to: event)
            .copy(\.eventDetails, to: details)
    }
}
