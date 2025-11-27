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
import UIKit
import proton_app_uniffi

@testable import ProtonMail

@MainActor
@Suite(.serialized)
final class ShortcutItemsServiceTests {
    private var stubbedActiveUserSession: MailUserSessionSpy?
    private var stubbedResolveResult: ResolveSystemLabelIdResult = .ok(0)

    private lazy var sut = ShortcutItemsService(
        activeUserSession: { [unowned self] in stubbedActiveUserSession },
        resolveSystemLabelID: { [unowned self] _, _ in try await stubbedResolveResult.get() }
    )

    private let dummyUserSession = MailUserSessionSpy(id: "foo")

    @Test
    func setsItemsWhenASessionIsActive() async {
        stubbedActiveUserSession = dummyUserSession

        await sut.updateShortcutItems()

        #expect(UIApplication.shared.shortcutItems?.map(\.type) == ["search", "starred", "compose"])
    }

    @Test
    func clearsItemsWhenNoSessionIsActive() async {
        stubbedActiveUserSession = nil

        await sut.updateShortcutItems()

        #expect(UIApplication.shared.shortcutItems == [])
    }

    @Test
    func whenStarredFolderDoesNotExist_setsRemainingItems() async {
        stubbedActiveUserSession = dummyUserSession
        stubbedResolveResult = .ok(nil)

        await sut.updateShortcutItems()

        #expect(UIApplication.shared.shortcutItems?.map(\.type) == ["search", "compose"])
    }

    @Test
    func whenStarredFolderLookupFails_setsRemainingItems() async {
        stubbedActiveUserSession = dummyUserSession
        stubbedResolveResult = .error(.unexpected(.database))

        await sut.updateShortcutItems()

        #expect(UIApplication.shared.shortcutItems?.map(\.type) == ["search", "compose"])
    }
}
