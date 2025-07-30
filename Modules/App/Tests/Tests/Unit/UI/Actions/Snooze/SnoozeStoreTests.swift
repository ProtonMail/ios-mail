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

    lazy var sut = SnoozeStore(
        state: .initial(screen: .main),
        upsellScreenPresenter: upsellScreenPresenterSpy,
        toastStateStore: toastStateStore
    )

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
