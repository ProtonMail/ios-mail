//
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

@testable import InboxIAP

import InboxCoreUI
import PaymentsNG
import SwiftUI
import Testing

@MainActor
final class PurchaseActionPerformerTests {
    private let planPurchasing = PlanPurchasingSpy()
    private let toastStateStore = ToastStateStore(initialState: .initial)
    private let isBusy = Binding.constant(false)
    private let storeKitProductID = "iosmail_mail2022_12_usd_auto_renewing"

    private lazy var sut = PurchaseActionPerformer(
        planPurchasing: planPurchasing
    )

    // MARK: Error toasts and screen dismissal

    @Test
    func whenTransactionIsSuccessful_dismissesTheScreen() async {
        await confirmation(expectedCount: 1) { dismissCalled in
            await sut.purchase(storeKitProductID: storeKitProductID, isBusy: isBusy, toastStateStore: toastStateStore) {
                dismissCalled()
            }
        }
    }

    @Test
    func whenTransactionFails_showsErrorAndDoesNotDismissTheScreen() async {
        planPurchasing.stubbedError = ProtonPlansManagerError.transactionUnknownError

        await confirmation(expectedCount: 0) { dismissCalled in
            await sut.purchase(storeKitProductID: storeKitProductID, isBusy: isBusy, toastStateStore: toastStateStore) {
                dismissCalled()
            }
        }

        #expect(toastStateStore.state.toasts.count == 1)
    }

    @Test
    func whenTransactionIsCancelledByUser_doesNotShowErrorAndDoesNotDismissTheScreen() async {
        planPurchasing.stubbedError = ProtonPlansManagerError.transactionCancelledByUser

        await confirmation(expectedCount: 0) { dismissCalled in
            await sut.purchase(storeKitProductID: storeKitProductID, isBusy: isBusy, toastStateStore: toastStateStore) {
                dismissCalled()
            }
        }

        #expect(toastStateStore.state.toasts == [])
    }
}
