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
    enum State: Equatable {
        case loading
        case loadFailed
        case loaded(RsvpEventService, RsvpEvent)
        case answering(RsvpEventService, RsvpEvent)
    }

    private let serviceProvider: RsvpEventServiceProvider
    @Published var state: State

    enum Action {
        case onLoad
        case retry
        case answer(RsvpAnswer)
    }

    init(serviceProvider: RsvpEventServiceProvider, state: State = .loading) {
        self.serviceProvider = serviceProvider
        self.state = state
    }

    @MainActor
    func handle(action: Action) async {
        switch action {
        case .onLoad, .retry:
            await loadEventDetails()
        case .answer(let status):
            if case let .loaded(service, event) = state {
                await answer(with: status, event: event, service: service)
            }
        }
    }

    @MainActor
    private func loadEventDetails() async {
        updateState(with: .loading)

        switch await serviceProvider.eventService() {
        case .none:
            updateState(with: .loadFailed)
        case .some(let eventService):
            switch eventService.get() {
            case .ok(let details):
                updateState(with: .loaded(eventService, details))
            case .error:
                updateState(with: .loadFailed)
            }
        }
    }

    @MainActor
    private func answer(with answer: RsvpAnswer, event: RsvpEvent, service: RsvpEventService) async {
        let updatedDetails = event.copy(
            \.attendees,
            to: updatedAttendees(in: event, with: answer)
        )

        updateState(with: .answering(service, updatedDetails))

        let answerResult = await service.answer(answer: answer)

        switch (answerResult, service.get()) {
        case (.ok, .ok(let eventDetails)), (.error, .ok(let eventDetails)):
            updateState(with: .loaded(service, eventDetails))
        case (.ok, .error), (.error, .error):
            updateState(with: .loadFailed)
        }
    }

    private func updatedAttendees(in existingDetails: RsvpEvent, with newStatus: RsvpAnswer) -> [RsvpAttendee] {
        let updateIndex = Int(existingDetails.userAttendeeIdx)
        var attendees = existingDetails.attendees

        attendees[updateIndex] = attendees[updateIndex].copy(\.status, to: newStatus.attendeeStatus)

        return attendees
    }

    private func updateState(with newState: State) {
        if state != newState {
            state = newState
        }
    }
}
