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
import InboxCore
import InboxDesignSystem
import Testing

final class RSVPStateStoreTests {
    private let rsvpEventSpy = RsvpEventSpy()
    private var rsvpIDSpy = RsvpEventIdSpy()
    private(set) lazy var sut = RSVPStateStore(rsvpID: rsvpIDSpy)

    @Test
    func initialStateIsCorrect() {
        #expect(sut.state.mode == .loading)
        #expect(rsvpIDSpy.fetchCallsCount == 0)
    }

    @Test
    func onLoadAction_FetchingSucceeds_ItSetLoadedState() async {
        rsvpEventSpy.stubbedDetails = .ok(.bestEvent())
        rsvpIDSpy.stubbedResult = rsvpEventSpy

        await sut.handle(action: .onLoad)

        #expect(rsvpIDSpy.fetchCallsCount == 1)

        #expect(sut.state.mode == .loaded)
        #expect(sut.state.rsvpEvent === rsvpEventSpy)
        #expect(sut.state.eventDetails == rsvpEventSpy.details().event)
    }

    @Test
    func onLoadAction_FetchingFailed_ItSetsErrorState() async {
        rsvpIDSpy.stubbedResult = nil

        await sut.handle(action: .onLoad)

        #expect(rsvpIDSpy.fetchCallsCount == 1)

        #expect(sut.state.mode == .failed)
        #expect(sut.state.rsvpEvent == nil)
        #expect(sut.state.eventDetails == nil)
    }

    @Test
    func retryAction_ItRetriesFetchingAndSetsLoadedState() async {
        rsvpIDSpy.stubbedResult = nil

        await sut.handle(action: .onLoad)

        rsvpIDSpy.stubbedResult = rsvpEventSpy
        rsvpEventSpy.stubbedDetails = .ok(.bestEvent())

        await sut.handle(action: .retry)

        #expect(rsvpIDSpy.fetchCallsCount == 2)

        #expect(sut.state.mode == .loaded)
        #expect(sut.state.rsvpEvent === rsvpEventSpy)
        #expect(sut.state.eventDetails == rsvpEventSpy.details().event)
    }

    @Test(arguments: RsvpAnswer.allCases)
    func answerAction_AnsweringSuceeds_ItAnswersAndRefetchedDetails(answer: RsvpAnswer) async {
        rsvpEventSpy.stubbedDetails = .ok(.bestEvent(status: .unanswered))
        rsvpIDSpy.stubbedResult = rsvpEventSpy

        await sut.handle(action: .onLoad)

        #expect(rsvpIDSpy.fetchCallsCount == 1)
        #expect(rsvpEventSpy.detailsCallsCount == 1)

        rsvpEventSpy.stubbedDetails = .ok(.bestEvent(status: answer.attendeeStatus))

        await sut.handle(action: .answer(answer))

        #expect(rsvpEventSpy.answerCalls == [answer])
        #expect(rsvpEventSpy.detailsCallsCount == 2)

        #expect(sut.state.mode == .loaded)
        #expect(sut.state.rsvpEvent === rsvpEventSpy)
        #expect(sut.state.eventDetails == .bestEvent(status: answer.attendeeStatus))
    }

    @Test
    func answerAction_AnsweringSucceedsAndFetchingDetailsFails_ItSetsFailedState() async {
        rsvpEventSpy.stubbedDetails = .ok(.bestEvent())
        rsvpIDSpy.stubbedResult = rsvpEventSpy

        await sut.handle(action: .onLoad)

        rsvpEventSpy.stubbedDetails = .error

        await sut.handle(action: .answer(.no))

        #expect(sut.state.mode == .failed)
        #expect(sut.state.rsvpEvent == nil)
        #expect(sut.state.eventDetails == nil)
    }

    @Test
    func answerAction_AnsweringFailsAndFetchingDetailsSucceeds_ItSetsLoadedState() async {
        rsvpEventSpy.stubbedDetails = .ok(.bestEvent())
        rsvpIDSpy.stubbedResult = rsvpEventSpy

        await sut.handle(action: .onLoad)

        rsvpEventSpy.stubbedResult = .error
        rsvpEventSpy.stubbedDetails = .ok(.bestEvent(status: .no))

        await sut.handle(action: .answer(.yes))

        #expect(sut.state.mode == .loaded)
        #expect(sut.state.rsvpEvent === rsvpEventSpy)
        #expect(sut.state.eventDetails == rsvpEventSpy.details().event)
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

    var stubbedResult: VoidAnswerRsvpResult = .ok
    var stubbedDetails: RsvpEventDetailsResult = .error

    // MARK: - RsvpEvent

    override func answer(answer: RsvpAnswer) async -> VoidAnswerRsvpResult {
        answerCalls.append(answer)

        return stubbedResult
    }

    override func details() -> RsvpEventDetailsResult {
        detailsCallsCount += 1

        return stubbedDetails
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
            attendees: [.init(email: "john@pm.me", status: status)],
            userAttendeeIdx: 0,
            state: .answerableInvite(progress: .pending, attendance: .optional)
        )
    }

}
