//
//  StoreKitProtocols.swift
//  ProtonCore-Payments - Created on 2/12/2020.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import StoreKit
import ProtonCore_DataModel
import ProtonCore_Services

public protocol PaymentTokenStorage {
    func add(_ token: PaymentToken)
    func get() -> PaymentToken?
    func clear()
}

public protocol StoreKitManagerDelegate: AnyObject {
    var tokenStorage: PaymentTokenStorage? { get }
    var isUnlocked: Bool { get }
    var isSignedIn: Bool { get }
    var activeUsername: String? { get }
    var userId: String? { get }
}

public protocol StoreKitManagerProtocol: NSObjectProtocol {
    typealias SuccessCallback = (PaymentToken?) -> Void
    typealias ErrorCallback = (Error) -> Void // StoreKitErrors?
    typealias FinishCallback = () -> Void

    func subscribeToPaymentQueue()
    func unsubscribeFromPaymentQueue()
    func isValidPurchase(storeKitProductId: String, completion: @escaping (Bool) -> Void)
    func purchaseProduct(plan: InAppPurchasePlan,
                         amountDue: Int,
                         successCompletion: @escaping SuccessCallback,
                         errorCompletion: @escaping ErrorCallback,
                         deferredCompletion: FinishCallback?)
    func continueRegistrationPurchase(finishHandler: FinishCallback?)
    func updateAvailableProductsList(completion: @escaping (Error?) -> Void)
    func hasUnfinishedPurchase() -> Bool
    func hasIAPInProgress() -> Bool
    func readReceipt() throws -> String
    func getNotifiedWhenTransactionsWaitingForTheSignupAppear(completion: @escaping ([InAppPurchasePlan]) -> Void) -> [InAppPurchasePlan]
    func stopBeingNotifiedWhenTransactionsWaitingForTheSignupAppear()
    func currentTransaction() -> SKPaymentTransaction?
    func priceLabelForProduct(storeKitProductId: String) -> (NSDecimalNumber, Locale)?
    var inAppPurchaseIdentifiers: ListOfIAPIdentifiers { get }
    var delegate: StoreKitManagerDelegate? { get set }
    var reportBugAlertHandler: BugAlertHandler { get }
}

public typealias BugAlertHandler = ((String?) -> Void)?

public extension StoreKitManagerProtocol {

    func purchaseProduct(plan: InAppPurchasePlan,
                         amountDue: Int,
                         successCompletion: @escaping SuccessCallback,
                         errorCompletion: @escaping ErrorCallback) {
        purchaseProduct(plan: plan,
                        amountDue: amountDue,
                        successCompletion: successCompletion,
                        errorCompletion: errorCompletion,
                        deferredCompletion: nil)
    }
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
    case registration
}

typealias ProcessCompletionCallback = (ProcessCompletionResult) -> Void

enum ProcessCompletionResult {
    case finished
    case paymentToken(PaymentToken)
    case errored(StoreKitManagerErrors)
    case erroredWithUnspecifiedError(Error)
}

struct PlanToBeProcessed {
    let protonIdentifier: String
    let amount: Int
    let amountDue: Int
}

protocol ProcessProtocol: AnyObject {
    func process(
        transaction: SKPaymentTransaction,
        plan: PlanToBeProcessed,
        completion: @escaping ProcessCompletionCallback
    ) throws
}

protocol ProcessUnathenticatedProtocol: ProcessProtocol {
    func processAuthenticatedBeforeSignup(
        transaction: SKPaymentTransaction,
        plan: PlanToBeProcessed,
        completion: @escaping ProcessCompletionCallback
    ) throws
}

protocol ProcessDependencies: AnyObject {
    var storeKitDelegate: StoreKitManagerDelegate? { get }
    var tokenStorage: PaymentTokenStorage { get }
    var paymentsApiProtocol: PaymentsApiProtocol { get }
    var alertManager: PaymentsAlertManager { get }
    var updateSubscription: (Subscription) -> Void { get }
    var finishTransaction: (SKPaymentTransaction) -> Void { get }
    var apiService: APIService { get }
    func addTransactionsBeforeSignup(transaction: SKPaymentTransaction)
    func removeTransactionsBeforeSignup(transaction: SKPaymentTransaction)
    var pendingRetry: Double { get }
    var errorRetry: Double { get }
    func getReceipt() throws -> String
    var bugAlertHandler: BugAlertHandler { get }
}

extension SKPaymentQueue: PaymentQueueProtocol {

}
