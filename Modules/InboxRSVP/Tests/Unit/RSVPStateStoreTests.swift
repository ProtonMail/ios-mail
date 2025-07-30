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
import Testing

final class RSVPStateStoreTests {
    private let rsvpEventSpy = RsvpEventSpy()
    private var rsvpIDSpy = RsvpEventIdSpy()
    private(set) lazy var sut = RSVPStateStore(rsvpID: rsvpIDSpy)
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initial

    @Test
    func initialState_FetchIsNotCalledAndHasLoadingState() {
        let recordedStates = trackStates(of: sut.$state)

        #expect(rsvpIDSpy.fetchCallsCount == 0)
        #expect(recordedStates() == [.loading])
    }

    // MARK: - `onLoad` action

    @Test
    func onLoadAction_FetchingFailed_ItSetsLoadFailedState() async {
        let recordedStates = trackStates(of: sut.$state)

        rsvpIDSpy.stubbedResult = nil

        await sut.handle(action: .onLoad)

        #expect(rsvpIDSpy.fetchCallsCount == 1)
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

        let expectedService = rsvpEventSpy
        let expectedEvent: RsvpEventDetails = .bestEvent()

        rsvpEventSpy.stubbedDetailsResult = .ok(expectedEvent)
        rsvpIDSpy.stubbedResult = rsvpEventSpy

        await sut.handle(action: .onLoad)

        #expect(rsvpIDSpy.fetchCallsCount == 1)
        #expect(
            recordedStates() == [
                .loading,
                .loaded(.init(expectedService, expectedEvent)),
            ]
        )
    }

    @Test
    func onLoadAction_FetchingSuceedsAndRetrievingEventDetailsFails_ItSetsLoadFailedState() async {
        let recordedStates = trackStates(of: sut.$state)

        rsvpEventSpy.stubbedDetailsResult = .error
        rsvpIDSpy.stubbedResult = rsvpEventSpy

        await sut.handle(action: .onLoad)

        #expect(rsvpIDSpy.fetchCallsCount == 1)
        #expect(recordedStates() == [.loading, .loadFailed])
    }

    // MARK: - `retry` action

    @Test
    func retryAction_AfterFailedFetching_ItRetriesFetchingAndSetsLoadedState() async {
        let recordedStates = trackStates(of: sut.$state)

        rsvpIDSpy.stubbedResult = nil

        await sut.handle(action: .onLoad)

        #expect(rsvpIDSpy.fetchCallsCount == 1)
        #expect(recordedStates() == [.loading, .loadFailed])

        let expectedEvent: RsvpEventDetails = .bestEvent()

        rsvpIDSpy.stubbedResult = rsvpEventSpy
        rsvpEventSpy.stubbedDetailsResult = .ok(.bestEvent())

        await sut.handle(action: .retry)

        #expect(rsvpIDSpy.fetchCallsCount == 2)
        #expect(
            recordedStates() == [
                .loading,
                .loadFailed,
                .loading,
                .loaded(.init(rsvpEventSpy, expectedEvent)),
            ]
        )
    }

    // MARK: - `answer` action

    @Test(arguments: RsvpAnswer.allCases)
    func answerAction_AnsweringSuceeds_ItAnswersRefetchesDetailsAndSetsLoadedState(answer: RsvpAnswer) async {
        let recordedStates = trackStates(of: sut.$state)

        let initialEvent: RsvpEventDetails = .bestEvent(status: .unanswered)
        let updatedEvent: RsvpEventDetails = .bestEvent(status: answer.attendeeStatus)

        rsvpEventSpy.stubbedDetailsResult = .ok(initialEvent)
        rsvpIDSpy.stubbedResult = rsvpEventSpy

        await sut.handle(action: .onLoad)

        #expect(rsvpIDSpy.fetchCallsCount == 1)
        #expect(rsvpEventSpy.detailsCallsCount == 1)

        rsvpEventSpy.stubbedDetailsResult = .ok(updatedEvent)

        await sut.handle(action: .answer(answer))

        #expect(rsvpEventSpy.answerCalls == [answer])
        #expect(rsvpEventSpy.detailsCallsCount == 2)

        #expect(
            recordedStates() == [
                .loading,
                .loaded(.init(rsvpEventSpy, initialEvent)),
                .answering(.init(rsvpEventSpy, updatedEvent)),
                .loaded(.init(rsvpEventSpy, updatedEvent)),
            ]
        )
    }

    @Test
    func answerAction_AnsweringSucceedsAndFetchingDetailsFails_ItMakesOptimisticUpdateAndSetLoadFailedState() async {
        let recordedStates = trackStates(of: sut.$state)

        let expectedEvent: RsvpEventDetails = .bestEvent(status: .unanswered)

        rsvpEventSpy.stubbedDetailsResult = .ok(expectedEvent)
        rsvpIDSpy.stubbedResult = rsvpEventSpy

        await sut.handle(action: .onLoad)

        rsvpEventSpy.stubbedDetailsResult = .error

        await sut.handle(action: .answer(.no))

        #expect(
            recordedStates() == [
                .loading,
                .loaded(.init(rsvpEventSpy, expectedEvent)),
                .answering(.init(rsvpEventSpy, .bestEvent(status: .no))),
                .loadFailed,
            ]
        )
    }

    @Test
    func answerAction_AnsweringFailedAndFetchingDetailsSucceeds_ItMakesOptimisticUpdateAndRevertsEventToPreviousState() async {
        let recordedStates = trackStates(of: sut.$state)

        let initialEvent: RsvpEventDetails = .bestEvent(status: .unanswered)

        rsvpEventSpy.stubbedDetailsResult = .ok(initialEvent)
        rsvpIDSpy.stubbedResult = rsvpEventSpy

        await sut.handle(action: .onLoad)

        rsvpEventSpy.stubbedAnswerResult = .error

        await sut.handle(action: .answer(.yes))

        #expect(
            recordedStates() == [
                .loading,
                .loaded(.init(rsvpEventSpy, initialEvent)),
                .answering(.init(rsvpEventSpy, .bestEvent(status: .yes))),
                .loaded(.init(rsvpEventSpy, initialEvent)),
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

private class RsvpEventIdSpy: RsvpEventId, @unchecked Sendable {
    private(set) var fetchCallsCount = 0

    var stubbedResult: RsvpEvent?

    // MARK: - RsvpEventId

    override func fetch() async -> RsvpEvent? {
        fetchCallsCount += 1

        return stubbedResult
    }
}

private class RsvpEventSpy: RsvpEvent, @unchecked Sendable {
    private(set) var answerCalls: [RsvpAnswer] = []
    private(set) var detailsCallsCount = 0

    var stubbedAnswerResult: VoidAnswerRsvpResult = .ok
    var stubbedDetailsResult: RsvpEventDetailsResult = .error

    // MARK: - RsvpEvent

    override func answer(answer: RsvpAnswer) async -> VoidAnswerRsvpResult {
        answerCalls.append(answer)

        return stubbedAnswerResult
    }

    override func details() -> RsvpEventDetailsResult {
        detailsCallsCount += 1

        return stubbedDetailsResult
    }
}

private extension RsvpEventDetailsResult {

    var event: RsvpEventDetails? {
        switch self {
        case .ok(let details):
            details
        case .error:
            nil
        }
    }

}

private extension RsvpEventDetails {

    static func bestEvent(status: RsvpAttendeeStatus = .unanswered) -> Self {
        .testData(
            summary: "Best event",
            attendees: [.init(name: .none, email: "john@pm.me", status: status)],
            userAttendeeIdx: 0,
            state: .answerableInvite(progress: .pending, attendance: .optional)
        )
    }

}
