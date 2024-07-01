// Copyright (c) 2024 Proton Technologies AG
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

import ProtonCorePayments
import ProtonCoreTestingToolkitUnitTestsCore
import StoreKit

final class MockStoreKitManager: NSObject, StoreKitManagerProtocol {
    var inAppPurchaseIdentifiers: ProtonCorePayments.ListOfIAPIdentifiers {
        fatalError("not implemented")
    }

    var delegate: (any ProtonCorePayments.StoreKitManagerDelegate)?

    var reportBugAlertHandler: ProtonCorePayments.BugAlertHandler {
        fatalError("not implemented")
    }

    var canExtendSubscription: Bool {
        fatalError("not implemented")
    }

    var refreshHandler: (ProtonCorePayments.ProcessCompletionResult) -> Void = { _ in }

    func subscribeToPaymentQueue() {
        fatalError("not implemented")
    }

    func unsubscribeFromPaymentQueue() {
        fatalError("not implemented")
    }

    func isValidPurchase(storeKitProductId: String, completion: @escaping (Bool) -> Void) {
        fatalError("not implemented")
    }

    func purchaseProduct(
        plan: ProtonCorePayments.InAppPurchasePlan,
        amountDue: Int,
        successCompletion: @escaping SuccessCallback,
        errorCompletion: @escaping ErrorCallback,
        deferredCompletion: FinishCallback?
    ) {
        fatalError("not implemented")
    }

    func retryProcessingAllPendingTransactions(finishHandler: FinishCallback?) {
        fatalError("not implemented")
    }

    func updateAvailableProductsList(completion: @escaping ((any Error)?) -> Void) {
        fatalError("not implemented")
    }

    func hasUnfinishedPurchase() -> Bool {
        fatalError("not implemented")
    }

    func hasIAPInProgress() -> Bool {
        fatalError("not implemented")
    }

    func readReceipt() throws -> String {
        fatalError("not implemented")
    }

    func getNotifiedWhenTransactionsWaitingForTheSignupAppear(
        completion: @escaping ([ProtonCorePayments.InAppPurchasePlan]) -> Void
    ) -> [ProtonCorePayments.InAppPurchasePlan] {
        fatalError("not implemented")
    }

    func stopBeingNotifiedWhenTransactionsWaitingForTheSignupAppear() {
        fatalError("not implemented")
    }

    func currentTransaction() -> SKPaymentTransaction? {
        fatalError("not implemented")
    }

    @FuncStub(MockStoreKitManager.priceLabelForProduct, initialReturn: nil) var priceLabelForProductStub
    func priceLabelForProduct(storeKitProductId: String) -> (NSDecimalNumber, Locale)? {
        priceLabelForProductStub(storeKitProductId)
    }
}
