//
//  PaymentsManager.swift
//  ProtonCore_PaymentsUI - Created on 01/06/2021.
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import ProtonCore_Payments

final class PaymentsManager {

    enum PaymentCallback {
        case purchasedPlan(accountPlan: AccountPlan, processingPlan: AccountPlan? = nil)
        case purchaseError(error: Error, processingPlan: AccountPlan? = nil)
    }
    
    private let storeKitManager = StoreKitManager.default

    init(appStoreLocalReceipt: String? = nil) {
        if let localReceipt = appStoreLocalReceipt {
            storeKitManager.appStoreLocalTest = true
            storeKitManager.appStoreLocalReceipt = localReceipt
        } else {
            storeKitManager.appStoreLocalTest = false
        }
    }

    func buyPlan(accountPlan: AccountPlan, finishCallback: @escaping (PaymentCallback) -> Void) {
        if accountPlan == .free {
            finishCallback(.purchasedPlan(accountPlan: .free))
            return
        }
        guard let productId = accountPlan.storeKitProductId else {
            finishCallback(.purchaseError(error: StoreKitManager.Errors.unavailableProduct))
            return
        }
        
        if let unfinishedPurchasePlan = self.unfinishedPurchasePlan {
            // purchase already started, don't start it again
            finishCallback(.purchasedPlan(accountPlan: unfinishedPurchasePlan))
            return
        }

        storeKitManager.purchaseProduct(identifier: productId) { _ in
            DispatchQueue.main.async {
                finishCallback(.purchasedPlan(accountPlan: accountPlan, processingPlan: accountPlan))
            }
        } errorCompletion: { error in
            DispatchQueue.main.async {
                finishCallback(.purchaseError(error: error, processingPlan: self.unfinishedPurchasePlan))
            }
        }
    }
    
    var unfinishedPurchasePlan: AccountPlan? {
        guard storeKitManager.hasUnfinishedPurchase(), let transaction = StoreKitManager.default.currentTransaction() else { return nil }
        return AccountPlan(storeKitProductId: transaction.payment.productIdentifier)
    }
}
