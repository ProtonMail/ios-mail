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
    struct EventData: Equatable {
        let service: RsvpEvent
        let details: RsvpEventDetails

        init(_ service: RsvpEvent, _ details: RsvpEventDetails) {
            self.service = service
            self.details = details
        }
    }

    enum State: Equatable {
        case loading
        case loadFailed
        case loaded(EventData)
        case answering(EventData)
    }

    private let serviceProvider: RsvpEventId
    @Published var state: State

    enum Action {
        case onLoad
        case retry
        case answer(RsvpAnswer)
    }

    init(serviceProvider: RsvpEventId, state: State = .loading) {
        self.serviceProvider = serviceProvider
        self.state = state
    }

    @MainActor
    func handle(action: Action) async {
        switch action {
        case .onLoad, .retry:
            await loadEventDetails()
        case .answer(let status):
            if case .loaded(let data) = state {
                await answer(with: status, eventData: data)
            }
        }
    }

    @MainActor
    private func loadEventDetails() async {
        updateState(with: .loading)

        switch await serviceProvider.fetch() {
        case .none:
            updateState(with: .loadFailed)
        case .some(let eventService):
            switch eventService.details() {
            case .ok(let details):
                updateState(with: .loaded(.init(eventService, details)))
            case .error:
                updateState(with: .loadFailed)
            }
        }
    }

    @MainActor
    private func answer(with answer: RsvpAnswer, eventData: EventData) async {
        let updatedDetails = eventData.details.copy(
            \.attendees,
            to: updatedAttendees(in: eventData.details, with: answer)
        )

        updateState(with: .answering(.init(eventData.service, updatedDetails)))

        let answerResult = await eventData.service.answer(answer: answer)

        switch (answerResult, eventData.service.details()) {
        case (.ok, .ok(let eventDetails)), (.error, .ok(let eventDetails)):
            updateState(with: .loaded(.init(eventData.service, eventDetails)))
        case (.ok, .error), (.error, .error):
            updateState(with: .loadFailed)
        }
    }

    private func updatedAttendees(in existingDetails: RsvpEventDetails, with newStatus: RsvpAnswer) -> [RsvpAttendee] {
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
