//
//  ProcessAddCredits.swift
//  PMPayments - Created on 25/12/2020.
//
//
//  Copyright (c) 2020 Proton Technologies AG
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

import StoreKit
import AwaitKit
import PMLog

class ProcessAddCredits: ProcessProtocol {

    weak var delegate: ProcessDelegateProtocol?

    func process(transaction: SKPaymentTransaction, plan: AccountPlan, completion: @escaping CompletionCallback) throws {
        guard let delegate = delegate, let storeKitDelegate = delegate.storeKitDelegate, let apiService = storeKitDelegate.apiService else {
            throw StoreKitManager.Errors.transactionFailedByUnknownReason }
        guard let receipt = try? delegate.getReceipt() else {
            PMLog.debug("StoreKit: Proton token not found! Apple receipt not found!")
            return
        }
        do {
            let tokenApi = delegate.paymentsApiProtocol.tokenRequest(api: apiService, amount: plan.yearlyCost, receipt: receipt)
            let tokenRes = try await(tokenApi.run())
            guard let token = tokenRes.paymentToken else { return }
            do {
                let serverUpdateApi = delegate.paymentsApiProtocol.creditRequest(api: apiService, amount: plan.yearlyCost, paymentAction: .token(token: token.token))
                _ = try await(serverUpdateApi.run())
                PMLog.debug("StoreKit: credits added")
                delegate.paymentQueueProtocol.finishTransaction(transaction)
                delegate.successCallback?(nil)
                completion()
            } catch let error where error.isApplePaymentAlreadyRegisteredError {
                PMLog.debug("StoreKit: apple payment already registered (3)")
                delegate.paymentQueueProtocol.finishTransaction(transaction)
                delegate.tokenStorage?.clear()
                delegate.successCallback?(nil)
                completion()
            } catch let error {
                delegate.errorCallback(error)
                completion()
            }
        } catch let error {
            delegate.errorCallback(error)
            completion()
        }
    }
}
