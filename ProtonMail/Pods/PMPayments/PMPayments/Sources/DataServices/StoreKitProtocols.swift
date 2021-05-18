//
//  StoreKitProtocols.swift
//  PMPayments - Created on 2/12/2020.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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

import Foundation
import StoreKit
import PMCommon

typealias CompletionCallback = () -> Void

public protocol PaymentTokenStorage {
    func add(_ token: PaymentToken)
    func get() -> PaymentToken?
    func clear()
}

public protocol StoreKitManagerDelegate: class {
    var apiService: APIService? { get }
    var tokenStorage: PaymentTokenStorage? { get }
    var isUnlocked: Bool { get }
    var isSignedIn: Bool { get }
    var activeUsername: String? { get }
    var userId: String? { get }
    var servicePlanDataService: ServicePlanDataService? { get }
}

public protocol StoreKitManagerProtocol: NSObjectProtocol {
    typealias SuccessCallback = (PaymentToken?) -> Void
    typealias ErrorCallback = (Error) -> Void
    typealias FinishCallback = () -> Void

    func subscribeToPaymentQueue()
    func isValidPurchase(identifier: String) -> Bool
    func purchaseProduct(identifier: String, successCompletion: @escaping SuccessCallback, errorCompletion: @escaping ErrorCallback, deferredCompletion: FinishCallback?)
    func continueRegistrationPurchase(finishHandler: FinishCallback?)
    func updateAvailableProductsList()
    func isReadyToPurchaseProduct() -> Bool
    func currentTransaction() -> SKPaymentTransaction?
    func priceLabelForProduct(identifier: String) -> (NSDecimalNumber, Locale)?
}

protocol PaymentQueueProtocol {
    static func `default`() -> Self
    func add(_ payment: SKPayment)
    func restoreCompletedTransactions()
    func restoreCompletedTransactions(withApplicationUsername username: String?)
    func finishTransaction(_ transaction: SKPaymentTransaction)
    func start(_ downloads: [SKDownload])
    func pause(_ downloads: [SKDownload])
    func resume(_ downloads: [SKDownload])
    func cancel(_ downloads: [SKDownload])
    func add(_ observer: SKPaymentTransactionObserver)
    func remove(_ observer: SKPaymentTransactionObserver)
    var transactions: [SKPaymentTransaction] { get }
}

enum ProcessingType {
    case existingUserNewSubscription
    case existingUserAddCredits
    case registration
}

protocol ProcessProtocol: class {
    func process(transaction: SKPaymentTransaction, plan: AccountPlan, completion: @escaping () -> Void) throws
    var delegate: ProcessDelegateProtocol? { get set }
}

protocol ProcessUnathenticatedProtocol: ProcessProtocol {
    func processAuthenticatedBeforeSignup(transaction: SKPaymentTransaction, plan: AccountPlan, completion: @escaping () -> Void) throws
}

protocol ProcessDelegateProtocol: class {
    var storeKitDelegate: StoreKitManagerDelegate? { get }
    var tokenStorage: PaymentTokenStorage? { get }
    var paymentsApiProtocol: PaymentsApiProtocol { get }
    var paymentQueueProtocol: PaymentQueueProtocol { get }
    var alertManager: PaymentsAlertManager { get }
    var successCallback: StoreKitManager.SuccessCallback? { get }
    var errorCallback: StoreKitManager.ErrorCallback { get }
    var transactionsBeforeSignup: [SKPaymentTransaction] { get set }
    var pendingRetry: Double { get }
    var errorRetry: Double { get }
    func getReceipt() throws -> String
}

extension SKPaymentQueue: PaymentQueueProtocol {

}
