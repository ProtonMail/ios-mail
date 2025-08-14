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

@testable import ProtonMail

import Combine
import InboxTesting
import proton_app_uniffi
import Testing
import UIKit

@MainActor
@Suite(.serialized)
final class ShortcutItemsServiceTests {
    private let sessionStateSubject = CurrentValueSubject<SessionState, Never>(.noSession)
    private var stubbedResolveResult: ResolveSystemLabelIdResult = .ok(0)

    private lazy var sut = ShortcutItemsService(
        resolveSystemLabelID: { [unowned self] _, _ in try await stubbedResolveResult.get() },
        sessionState: sessionStateSubject
    )

    private let dummyUserSession = MailUserSessionSpy(id: "foo")

    @Test
    func setsItemsWhenASessionBecomesActive() async {
        let task = sut.startListeningToUserSessionChanges()
        sessionStateSubject.send(.activeSession(session: dummyUserSession))
        await waitForEventHandlingToFinish(task: task)

        #expect(UIApplication.shared.shortcutItems?.map(\.type) == ["search", "starred", "compose"])
    }

    @Test
    func clearsItemsWhenNoSessionIsActive() async {
        let task = sut.startListeningToUserSessionChanges()
        sessionStateSubject.send(.activeSession(session: dummyUserSession))
        sessionStateSubject.send(.noSession)
        await waitForEventHandlingToFinish(task: task)

        #expect(UIApplication.shared.shortcutItems == [])
    }

    @Test
    func ifStarredFolderDoesNotExist_setsRemainingItems() async {
        stubbedResolveResult = .ok(nil)

        let task = sut.startListeningToUserSessionChanges()
        sessionStateSubject.send(.activeSession(session: dummyUserSession))
        await waitForEventHandlingToFinish(task: task)

        #expect(UIApplication.shared.shortcutItems?.map(\.type) == ["search", "compose"])
    }

    @Test
    func ifStarredFolderLookupFails_setsRemainingItems() async {
        stubbedResolveResult = .error(.unexpected(.database))

        let task = sut.startListeningToUserSessionChanges()
        sessionStateSubject.send(.activeSession(session: dummyUserSession))
        await waitForEventHandlingToFinish(task: task)

        #expect(UIApplication.shared.shortcutItems?.map(\.type) == ["search", "compose"])
    }

    private func waitForEventHandlingToFinish(task: Task<Void, Never>) async {
        sessionStateSubject.send(completion: .finished)
        await task.value
    }
}
