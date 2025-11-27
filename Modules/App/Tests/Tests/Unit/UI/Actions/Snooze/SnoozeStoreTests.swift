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

import InboxCoreUI
import ProtonUIFoundations
import Testing
import proton_app_uniffi

@testable import ProtonMail

@MainActor
class SnoozeStoreTests {
    private let upsellScreenPresenterSpy = UpsellScreenPresenterSpy()
    private let snoozeServiceSpy = SnoozeServiceSpy()
    let conversationIDs: [ID] = [.init(value: 7), .init(value: 77)]
    let toastStateStore = ToastStateStore(initialState: .initial)
    let labelId = ID(value: 5)
    var dismissInvokedCount = 0

    lazy var sut = SnoozeStore(
        state: .initial(screen: .main, labelId: labelId, conversationIDs: conversationIDs),
        upsellScreenPresenter: upsellScreenPresenterSpy,
        toastStateStore: toastStateStore,
        snoozeService: snoozeServiceSpy,
        dismiss: { [unowned self] in dismissInvokedCount += 1 }
    )

    @Test
    func testLoadData_ProvidesSnoozeActions() async {
        await sut.handle(action: .loadData)

        #expect(sut.state.snoozeActions == .init(options: snoozeServiceSpy.snoozeOptionsStub, showUnsnooze: true))
    }

    @Test
    func testSnoozeAction_SnoozesCorrectConversations() async {
        await sut.handle(action: .predefinedSnoozeOptionTapped(.nextWeek(.timestamp)))

        #expect(snoozeServiceSpy.invokedSnooze.count == 1)
        #expect(snoozeServiceSpy.invokedSnooze.first?.ids == conversationIDs)
        #expect(snoozeServiceSpy.invokedSnooze.first?.labelId == labelId)
        #expect(snoozeServiceSpy.invokedSnooze.first?.timestamp == .timestamp)
        #expect(toastStateStore.state.toasts == [.snooze(snoozeDate: UInt64.timestamp.date)])
        #expect(dismissInvokedCount == 1)
    }

    @Test
    func testUnsnoozeAction_UnsnoozesCorrectConversations() async {
        await sut.handle(action: .unsnoozeTapped)

        #expect(snoozeServiceSpy.invokedUnsnooze.count == 1)
        #expect(snoozeServiceSpy.invokedUnsnooze.first?.ids == conversationIDs)
        #expect(snoozeServiceSpy.invokedUnsnooze.first?.labelId == labelId)
        #expect(toastStateStore.state.toasts == [.unsnooze])
        #expect(dismissInvokedCount == 1)
    }

    @Test
    func testUnsnoozeActionFailure_ItDisplaysToast() async {
        snoozeServiceSpy.unsnoozeResultStub = .error(.reason(.invalidSnoozeLocation))

        await sut.handle(action: .unsnoozeTapped)

        #expect(
            toastStateStore.state.toasts == [
                .error(message: SnoozeErrorReason.invalidSnoozeLocation.errorMessage.string)
            ]
        )
    }

    @Test
    func testSnoozeActionFailure_ItDisplaysToast() async {
        snoozeServiceSpy.snoozeResultStub = .error(.reason(.invalidSnoozeLocation))

        await sut.handle(action: .customSnoozeDateSelected(.now))

        #expect(
            toastStateStore.state.toasts == [
                .error(message: SnoozeErrorReason.invalidSnoozeLocation.errorMessage.string)
            ]
        )
    }

    @Test
    func testSnoozeActionOtherFailure_ItDoesNotDisplayToast() async {
        snoozeServiceSpy.snoozeResultStub = .error(.other(.network))

        await sut.handle(action: .customSnoozeDateSelected(.now))

        #expect(toastStateStore.state.toasts == [])
    }

    @Test
    func testCustomButtonTapped_TransitionsToCustomView() async {
        await sut.handle(action: .customButtonTapped)

        #expect(sut.state.screen == .custom)
    }

    @Test
    func customSnoozeCancelTapped_TransitionsToMainView() async {
        sut.state = sut.state.copy(\.screen, to: .custom)

        await sut.handle(action: .customSnoozeCancelTapped)

        #expect(sut.state.screen == .main)
    }

    @Test
    func customSnoozeDateIsSelected_ItSnoozesConversation() async {
        await sut.handle(action: .customSnoozeDateSelected(UInt64.timestamp.date))

        #expect(snoozeServiceSpy.invokedSnooze.count == 1)
        #expect(snoozeServiceSpy.invokedSnooze.first?.ids == conversationIDs)
        #expect(snoozeServiceSpy.invokedSnooze.first?.labelId == labelId)
        #expect(snoozeServiceSpy.invokedSnooze.first?.timestamp == .timestamp)
        #expect(toastStateStore.state.toasts == [.snooze(snoozeDate: UInt64.timestamp.date)])
        #expect(dismissInvokedCount == 1)
    }

    @Test
    func testUpgradeButtonTapped_ItShowsUpsellSheet() async {
        await sut.handle(action: .upgradeTapped)

        #expect(upsellScreenPresenterSpy.presentUpsellScreenCalled == [.snooze])
        #expect(sut.state.presentUpsellScreen != nil)
    }

    @Test
    func testUpgradeButtonTapped_WhenFailedToPresentUpsellScreen_ItShowsErrorToast() async {
        let error: NSError = .dummy
        upsellScreenPresenterSpy.stubbedError = error

        await sut.handle(action: .upgradeTapped)

        #expect(toastStateStore.state.toasts == [.error(message: error.localizedDescription)])
        #expect(sut.state.presentUpsellScreen == nil)
    }
}
