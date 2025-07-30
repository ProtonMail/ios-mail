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

@testable import InboxRSVP
import Combine
import InboxCore
import InboxDesignSystem
import proton_app_uniffi
import Testing

final class RSVPStateStoreTests {
    private let serviceSpy = RsvpEventServiceSpy(noPointer: .init())
    private var serviceProviderSpy = RsvpEventServiceProviderSpy(noPointer: .init())
    private(set) lazy var sut = RSVPStateStore(serviceProvider: serviceProviderSpy)
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initial

    @Test
    func initialState_FetchIsNotCalledAndHasLoadingState() {
        let recordedStates = trackStates(of: sut.$state)

        #expect(serviceProviderSpy.fetchCallsCount == 0)
        #expect(recordedStates() == [.loading])
    }

    // MARK: - `onLoad` action

    @Test
    func onLoadAction_FetchingFailed_ItSetsLoadFailedState() async {
        let recordedStates = trackStates(of: sut.$state)

        serviceProviderSpy.stubbedResult = nil

        await sut.handle(action: .onLoad)

        #expect(serviceProviderSpy.fetchCallsCount == 1)
        #expect(
            recordedStates() == [
                .loading,
                .loadFailed,
            ]
        )
    }

    @Test
    func onLoadAction_FetchingAndRetrievingEventDetailsSucceeds_ItSetsLoadedState() async {
        let recordedStates = trackStates(of: sut.$state)

        let expectedService = serviceSpy
        let expectedEvent: RsvpEvent = .bestEvent()

        serviceSpy.stubbedDetailsResult = .ok(expectedEvent)
        serviceProviderSpy.stubbedResult = serviceSpy

        await sut.handle(action: .onLoad)

        #expect(serviceProviderSpy.fetchCallsCount == 1)
        #expect(
            recordedStates() == [
                .loading,
                .loaded(expectedService, expectedEvent),
            ]
        )
    }

    @Test
    func onLoadAction_FetchingSuceedsAndRetrievingEventDetailsFails_ItSetsLoadFailedState() async {
        let recordedStates = trackStates(of: sut.$state)

        serviceSpy.stubbedDetailsResult = .error(.network)
        serviceProviderSpy.stubbedResult = serviceSpy

        await sut.handle(action: .onLoad)

        #expect(serviceProviderSpy.fetchCallsCount == 1)
        #expect(recordedStates() == [.loading, .loadFailed])
    }

    // MARK: - `retry` action

    @Test
    func retryAction_AfterFailedFetching_ItRetriesFetchingAndSetsLoadedState() async {
        let recordedStates = trackStates(of: sut.$state)

        serviceProviderSpy.stubbedResult = nil

        await sut.handle(action: .onLoad)

        #expect(serviceProviderSpy.fetchCallsCount == 1)
        #expect(recordedStates() == [.loading, .loadFailed])

        let expectedEvent: RsvpEvent = .bestEvent()

        serviceProviderSpy.stubbedResult = serviceSpy
        serviceSpy.stubbedDetailsResult = .ok(.bestEvent())

        await sut.handle(action: .retry)

        #expect(serviceProviderSpy.fetchCallsCount == 2)
        #expect(
            recordedStates() == [
                .loading,
                .loadFailed,
                .loading,
                .loaded(serviceSpy, expectedEvent),
            ]
        )
    }

    // MARK: - `answer` action

    @Test(arguments: RsvpAnswer.allCases)
    func answerAction_AnsweringSuceeds_ItAnswersRefetchesDetailsAndSetsLoadedState(answer: RsvpAnswer) async {
        let recordedStates = trackStates(of: sut.$state)

        let initialEvent: RsvpEvent = .bestEvent(status: .unanswered)
        let updatedEvent: RsvpEvent = .bestEvent(status: answer.attendeeStatus)

        serviceSpy.stubbedDetailsResult = .ok(initialEvent)
        serviceProviderSpy.stubbedResult = serviceSpy

        await sut.handle(action: .onLoad)

        #expect(serviceProviderSpy.fetchCallsCount == 1)
        #expect(serviceSpy.detailsCallsCount == 1)

        serviceSpy.stubbedDetailsResult = .ok(updatedEvent)

        await sut.handle(action: .answer(answer))

        #expect(serviceSpy.answerCalls == [answer])
        #expect(serviceSpy.detailsCallsCount == 2)

        #expect(
            recordedStates() == [
                .loading,
                .loaded(serviceSpy, initialEvent),
                .answering(serviceSpy, updatedEvent),
                .loaded(serviceSpy, updatedEvent),
            ]
        )
    }

    @Test
    func answerAction_AnsweringSucceedsAndFetchingDetailsFails_ItMakesOptimisticUpdateAndSetLoadFailedState() async {
        let recordedStates = trackStates(of: sut.$state)

        let expectedEvent: RsvpEvent = .bestEvent(status: .unanswered)

        serviceSpy.stubbedDetailsResult = .ok(expectedEvent)
        serviceProviderSpy.stubbedResult = serviceSpy

        await sut.handle(action: .onLoad)

        serviceSpy.stubbedDetailsResult = .error(.otherReason(.invalidParameter))

        await sut.handle(action: .answer(.no))

        #expect(
            recordedStates() == [
                .loading,
                .loaded(serviceSpy, expectedEvent),
                .answering(serviceSpy, .bestEvent(status: .no)),
                .loadFailed,
            ]
        )
    }

    @Test
    func answerAction_AnsweringFailedAndFetchingDetailsSucceeds_ItMakesOptimisticUpdateAndRevertsEventToPreviousState() async {
        let recordedStates = trackStates(of: sut.$state)

        let initialEvent: RsvpEvent = .bestEvent(status: .unanswered)

        serviceSpy.stubbedDetailsResult = .ok(initialEvent)
        serviceProviderSpy.stubbedResult = serviceSpy

        await sut.handle(action: .onLoad)

        serviceSpy.stubbedAnswerResult = .error(.unexpected(.api))

        await sut.handle(action: .answer(.yes))

        #expect(
            recordedStates() == [
                .loading,
                .loaded(serviceSpy, initialEvent),
                .answering(serviceSpy, .bestEvent(status: .yes)),
                .loaded(serviceSpy, initialEvent),
            ]
        )
    }

    // MARK: - Private

    private func trackStates(of publisher: Published<RSVPStateStore.State>.Publisher) -> () -> [RSVPStateStore.State] {
        var values: [RSVPStateStore.State] = []

        publisher
            .sink { values.append($0) }
            .store(in: &cancellables)

        return { values }
    }
}

private class RsvpEventServiceProviderSpy: RsvpEventServiceProvider, @unchecked Sendable {
    private(set) var fetchCallsCount = 0

    var stubbedResult: RsvpEventService?

    // MARK: - RsvpEventId

    override func eventService() async -> RsvpEventService? {
        fetchCallsCount += 1

        return stubbedResult
    }
}

private class RsvpEventServiceSpy: RsvpEventService, @unchecked Sendable {
    private(set) var answerCalls: [RsvpAnswer] = []
    private(set) var detailsCallsCount = 0

    var stubbedAnswerResult: VoidAnswerRsvpResult = .ok
    var stubbedDetailsResult: RsvpEventGetResult = .error(.network)

    // MARK: - RsvpEvent

    override func answer(answer: RsvpAnswer) async -> VoidAnswerRsvpResult {
        answerCalls.append(answer)

        return stubbedAnswerResult
    }

    override func get() -> RsvpEventGetResult {
        detailsCallsCount += 1

        return stubbedDetailsResult
    }
}

private extension RsvpEventGetResult {

    var event: RsvpEvent? {
        switch self {
        case .ok(let details):
            details
        case .error:
            nil
        }
    }

}

private extension RsvpEvent {

    static func bestEvent(status: RsvpAttendeeStatus = .unanswered) -> Self {
        .testData(
            summary: "Best event",
            attendees: [.init(name: .none, email: "john@pm.me", status: status)],
            userAttendeeIdx: 0,
            state: .answerableInvite(progress: .pending, attendance: .optional)
        )
    }

}
