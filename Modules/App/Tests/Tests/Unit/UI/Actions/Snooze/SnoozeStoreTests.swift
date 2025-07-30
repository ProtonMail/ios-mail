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
import InboxCoreUI
import Testing

@MainActor
class SnoozeStoreTests {
    let toastStateStore = ToastStateStore(initialState: .initial)
    let upsellScreenPresenterSpy = UpsellScreenPresenterSpy()
    let conversationIDs: [ID] = [.init(value: 7), .init(value: 77)]
    let snoozeServiceSpy = SnoozeServiceSpy()
    var dismissInvokedCount = 0

    lazy var sut = SnoozeStore(
        state: .initial(screen: .main, conversationIDs: conversationIDs),
        upsellScreenPresenter: upsellScreenPresenterSpy,
        toastStateStore: toastStateStore,
        snoozeService: snoozeServiceSpy,
        dismiss: { [unowned self] in dismissInvokedCount += 1 }
    )

    @Test
    func testLoadData_proviesSnoozeActions() async {
        await sut.handle(action: .loadData)

        #expect(sut.state.options == snoozeServiceSpy.snoozeActionsStub.options)
        #expect(sut.state.showUnsnooze == snoozeServiceSpy.snoozeActionsStub.showUnsnooze)
    }

    @Test
    func testSnoozeAction_snoozesCorrectConversations() async {
        await sut.handle(action: .predefinedSnoozeOptionTapped(.nextWeek(.timestamp)))

        #expect(snoozeServiceSpy.invokedSnooze.count == 1)
        #expect(snoozeServiceSpy.invokedSnooze.first?.ids == conversationIDs)
        #expect(snoozeServiceSpy.invokedSnooze.first?.snoozeTime == .timestamp)
        #expect(dismissInvokedCount == 1)
    }

    @Test
    func testUnsnoozeAction_unsnoozesCorrectConversations() async {
        await sut.handle(action: .unsnoozeTapped)

        #expect(snoozeServiceSpy.invokedUnsnooze == [conversationIDs])
        #expect(dismissInvokedCount == 1)
    }

    @Test
    func testCustomButtonTapped_transitionsToCustomView() async {
        await sut.handle(action: .customButtonTapped)

        #expect(sut.state.screen == .custom)
    }

    @Test
    func customSnoozeCancelTapped_transitionsToMainView() async {
        sut.state = sut.state.copy(\.screen, to: .custom)

        await sut.handle(action: .customSnoozeCancelTapped)

        #expect(sut.state.screen == .main)
    }

    @Test
    func testUpgradeButtonTapped_ItShowsUpsellSheet() async {
        await sut.handle(action: .upgradeTapped)

        #expect(upsellScreenPresenterSpy.presentUpsellScreenCalled == [.snooze])
        #expect(sut.state.presentUpsellScreen != nil)
    }

    @Test
    func testUpgradeButtonTapped_WhenFailedToPresentUpsellScreen_ItShowsErrorToast() async {
        let error: NSError = .stubbed
        upsellScreenPresenterSpy.stubbedError = error

        await sut.handle(action: .upgradeTapped)

        #expect(toastStateStore.state.toasts == [.error(message: error.localizedDescription)])
        #expect(sut.state.presentUpsellScreen == nil)
    }
}

@testable import InboxIAP

class UpsellScreenPresenterSpy: UpsellScreenPresenter {
    var stubbedError: NSError?
    private(set) var presentUpsellScreenCalled: [UpsellScreenEntryPoint] = []

    func presentUpsellScreen(entryPoint: UpsellScreenEntryPoint) async throws -> UpsellScreenModel {
        presentUpsellScreenCalled.append(entryPoint)
        if let stubbedError {
            throw stubbedError
        } else {
            return .preview(entryPoint: entryPoint)
        }
    }
}

private extension NSError {
    static var stubbed: NSError {
        NSError(domain: .notUsed, code: 999, userInfo: nil)
    }
}

import proton_app_uniffi

class SnoozeServiceSpy: SnoozeServiceProtocol {
    lazy var snoozeActionsStub: SnoozeActions = .init(
        options: [.custom, .tomorrow(.timestamp), .nextWeek(.timestamp), .thisWeekend(.timestamp)],
        showUnsnooze: true
    )

    private(set) var invokedAvailableSnoozeActions: [(weekStart: NonDefaultWeekStart, id: ID)] = []
    private(set) var invokedSnooze: [(ids: [ID], snoozeTime: UnixTimestamp)] = []
    private(set) var invokedUnsnooze: [[ID]] = []

    // MARK: - SnoozeServiceProtocol

    func availableSnoozeActionsForConversation(weekStart: NonDefaultWeekStart, id: Id) -> AvailableSnoozeActionsForConversationResult {
        invokedAvailableSnoozeActions.append((weekStart, id))

        return .ok(snoozeActionsStub)
    }

    func snoozeConversations(ids: [Id], snoozeTime: UnixTimestamp) -> SnoozeConversationsResult {
        invokedSnooze.append((ids, snoozeTime))

        return .ok
    }

    func unsnoozeConversations(ids: [Id]) -> UnsnoozeConversationsResult {
        invokedUnsnooze.append(ids)

        return .ok
    }
}

private extension UInt64 {
    static var timestamp: UInt64 {
        1753883097
    }
}
