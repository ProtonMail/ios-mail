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
import InboxCoreUI
import InboxTesting
import ProtonUIFoundations
import Testing
import proton_app_uniffi

@testable import InboxContacts

@MainActor
final class ContactGroupDetailsStateStoreTests {
    private var sut: ContactGroupDetailsStateStore!
    private var initialState: ContactGroupItem!
    private var draftPresenterSpy: ContactsDraftPresenterSpy!
    private var toastStateStore: ToastStateStore!
    private var router: Router<ContactsRoute>!

    init() {
        initialState = .advisorsGroup
        draftPresenterSpy = .init()
        toastStateStore = .init(initialState: .initial)
        router = .init()

        sut = ContactGroupDetailsStateStore(
            state: initialState,
            draftPresenter: draftPresenterSpy,
            toastStateStore: toastStateStore,
            router: router
        )
    }

    @Test
    func testInitialState_isSetCorrectly() {
        #expect(sut.state == initialState)
    }

    @Test
    func testContactItemTappedAction_ItNavigatesToContactDetails() async throws {
        let emailItem: ContactEmailItem = try #require(ContactGroupItem.advisorsGroup.contactEmails.first)

        await sut.handle(action: .contactItemTapped(emailItem))

        #expect(router.stack == [.contactDetails(.init(emailItem))])
    }

    @Test
    func testSendGroupMessageTappedAction_ItPresentsDraftWithContactGroup() async {
        await sut.handle(action: .sendGroupMessageTapped)

        #expect(draftPresenterSpy.openDraftGroupCalls.count == 1)
        #expect(draftPresenterSpy.openDraftGroupCalls == [initialState])
    }

    @Test
    func testSendGroupMessageTappedAction_AndOpeningDraftFails_ItPresentsToastWithError() async {
        let expectedError: TestError = .test

        draftPresenterSpy.stubbedOpenDraftGroupError = expectedError

        await sut.handle(action: .sendGroupMessageTapped)

        #expect(draftPresenterSpy.openDraftGroupCalls.count == 1)
        #expect(draftPresenterSpy.openDraftGroupCalls == [initialState])
        #expect(toastStateStore.state.toasts == [.error(message: expectedError.localizedDescription)])
    }
}
