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

import InboxTesting
import Testing
import proton_app_uniffi

@testable import ProtonMail

@MainActor
final class ScrollerUpdatesAsyncTests {
    private var sut: ScrollerUpdatesAsync
    private var observedTasks: [Task<Void, Never>?]
    private var receivedMessageUpdates: [MessageScrollerUpdate]
    private var receivedConversationUpdates: [ConversationScrollerUpdate]

    private let dummyMessageUpdate = MessageScrollerUpdate.list(.none)
    private let dummyConversationUpdate = ConversationScrollerUpdate.list(.replaceFrom(idx: 0, items: []))

    init() {
        self.sut = .init()
        self.observedTasks = []
        self.receivedMessageUpdates = []
        self.receivedConversationUpdates = []
    }

    @Test
    func testObserve_itRetainsTask() async {
        sut.taskDidChange = { self.observedTasks.append($0) }

        await sut.observe(\.messageStream) { _ in }
        let firstTask = observedTasks.last

        #expect(firstTask != nil)
    }

    @Test
    func testObserve_itCreatesNewTaskOnEachCall() async {
        sut.taskDidChange = { self.observedTasks.append($0) }

        await sut.observe(\.messageStream) { _ in }
        await sut.observe(\.conversationStream) { _ in }

        #expect(observedTasks.first!! != observedTasks.last!!)
    }

    @Test
    func testObserve_itCancelsPreviousTask() async {
        sut.taskDidChange = { self.observedTasks.append($0) }

        await sut.observe(\.messageStream) { _ in }
        let firstTask = observedTasks.last!!
        #expect(!firstTask.isCancelled)

        await sut.observe(\.conversationStream) { _ in }

        #expect(firstTask.isCancelled)
    }

    @Test
    func testObserve_whenMessageUpdate_itCallsHandleUpdate() async throws {
        await sut.observe(\.messageStream) { update in
            self.receivedMessageUpdates.append(update)
        }

        sut.enqueueUpdate(dummyMessageUpdate)

        try await expectToEventually(self.receivedMessageUpdates == [self.dummyMessageUpdate])
    }

    @Test
    func testObserve_whenConversationUpdate_itCallsHandleUpdate() async throws {
        await sut.observe(\.conversationStream) { update in
            self.receivedConversationUpdates.append(update)
        }

        let update = ConversationScrollerUpdate.list(.replaceBefore(idx: 0, items: []))
        sut.enqueueUpdate(update)

        try await expectToEventually(self.receivedConversationUpdates == [update])
    }

    @Test
    func testObserve_whenSwitchingStream_itStopsOldStream() async throws {
        await sut.observe(\.messageStream) { update in
            self.receivedMessageUpdates.append(update)
        }
        await sut.observe(\.conversationStream) { update in
            self.receivedConversationUpdates.append(update)
        }

        sut.enqueueUpdate(dummyMessageUpdate)
        sut.enqueueUpdate(dummyConversationUpdate)

        try await expectToEventually(self.receivedConversationUpdates == [self.dummyConversationUpdate])
        #expect(receivedMessageUpdates.isEmpty)
    }

    @Test
    func testObserve_whenObservingSameStreamTwice_itStopsOldStream() async throws {
        var receivedConversationUpdates1: [ConversationScrollerUpdate] = []
        var receivedConversationUpdates2: [ConversationScrollerUpdate] = []
        await sut.observe(\.conversationStream) { update in
            receivedConversationUpdates1.append(update)
        }
        await sut.observe(\.conversationStream) { update in
            receivedConversationUpdates2.append(update)
        }

        sut.enqueueUpdate(dummyConversationUpdate)

        try await expectToEventually(receivedConversationUpdates2 == [self.dummyConversationUpdate])
        #expect(receivedConversationUpdates1.isEmpty)
    }

    @Test
    func testEnqueueUpdate_itDoesNotDropUpdatesUnderStress() async throws {
        var receivedCount = 0
        let expectedCount = 10_000

        await sut.observe(\.messageStream) { _ in
            receivedCount += 1
        }
        await Task.yield()

        for _ in 0..<expectedCount {
            sut.enqueueUpdate(dummyMessageUpdate)
        }

        try await expectToEventually(receivedCount == expectedCount)
    }
}
