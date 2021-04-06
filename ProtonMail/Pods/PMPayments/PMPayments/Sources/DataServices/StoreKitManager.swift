//
//  StoreKitManager.swift
//  PMPayments - Created on 21/08/2018.
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

import StoreKit
import Reachability
import PMLog
import PMCoreTranslation

public class StoreKitManager: NSObject, StoreKitManagerProtocol {

    // MARK: Public properties
    public static var `default` = StoreKitManager()
    public static let transactionFinishedNotification = Notification.Name("StoreKitManager.transactionFinished")
    public weak var delegate: StoreKitManagerDelegate?
    public var refreshHandler: (() -> Void)?
    public var appStoreLocalTest: Bool = false
    public var appStoreLocalReceipt: String = ""

    // MARK: Internal properties for testing proposes
    internal var paymentsApi: PaymentsApiProtocol = PaymentsApiImplementation()
    internal var paymentQueue: PaymentQueueProtocol = SKPaymentQueue.default()
    internal var request = SKProductsRequest(productIdentifiers: Set(AccountPlan.allCases.compactMap { $0.storeKitProductId }))
    internal var paymentsAlertManager = PaymentsAlertManager()
    internal var pendingRetryIn: Double = 30
    internal var errorRetryIn: Double = 10
    internal var alertViewDelay: Double = 1.0
    internal var receiptError: Error?
    internal var availableProducts: [SKProduct] = []

    // MARK: Private properties
    private let processAuthenticated: ProcessProtocol = ProcessAuthenticated()
    private let processUnathenticated: ProcessUnathenticatedProtocol = ProcessUnauthenticated()
    private let processAddCredits: ProcessProtocol = ProcessAddCredits()
    private lazy var commonTokenStorage = TokenStorage(tokenStorage: storeKitDelegate?.tokenStorage)

    private let queue = DispatchQueue(label: "StoreKitManager async queue")
    private let reachability = try? Reachability()
    private var transactionsQueue: OperationQueue = {
       let queue = OperationQueue()
        queue.qualityOfService = QualityOfService.userInteractive
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    private var transactionsMadeBeforeSignup = [SKPaymentTransaction]()
    private var transactionsFinishHandler: FinishCallback?
    private var successCompletion: SuccessCallback?
    private var deferredCompletion: FinishCallback?
    private lazy var errorCompletion: ErrorCallback = { error in
        DispatchQueue.main.asyncAfter(deadline: .now() + self.alertViewDelay) {
            self.errorCompletionAlertView(error: error)
        }
    }

    private lazy var confirmUserValidationBypass: (Error, @escaping () -> Void) -> Void = { [unowned self] error, completion in
        DispatchQueue.main.asyncAfter(deadline: .now() + self.alertViewDelay) {
            guard let currentUsername = self.delegate?.activeUsername else {
                self.errorCompletion(Errors.noActiveUsername)
                return
            }
            self.confirmUserValidationAlertView(error: error, userName: currentUsername, completion: completion)
        }
    }

    private override init() {
        super.init()
        try? reachability?.startNotifier()
        reachability?.whenReachable = { [weak self] _ in self?.networkReachable() }
        processAuthenticated.delegate = self
        processUnathenticated.delegate = self
        processAddCredits.delegate = self
    }

    deinit {
        reachability?.stopNotifier()
    }

    // MARK: Public interface

    public func subscribeToPaymentQueue() {
        paymentQueue.add(self)
    }

    public func updateAvailableProductsList() {
        request.delegate = self
        request.start()
    }

    public func priceLabelForProduct(identifier: String) -> (NSDecimalNumber, Locale)? {
        guard let product = self.availableProducts.first(where: { $0.productIdentifier == identifier }) else { return nil }
        return (product.price, product.priceLocale)
    }

    public func isReadyToPurchaseProduct() -> Bool {
        // no matter which user is logged in now, if there is any unfinished transaction - we do not want to give opportunity to start new purchase. BE currently can process only last transaction in Receipts, so we do not want to mess up the older ones.
        return (!self.hasUnfinishedPurchase()) && (self.applicationUserId() != nil)
    }

    public func currentTransaction() -> SKPaymentTransaction? {
        return paymentQueue.transactions.filter { $0.transactionState != .failed }.first
    }

    public func purchaseProduct(identifier: String,
                                successCompletion: @escaping SuccessCallback,
                                errorCompletion: @escaping ErrorCallback,
                                deferredCompletion: (() -> Void)? = nil) {

        let result = canPurchaseProduct(identifier: identifier)
        switch result {
        case .failure(let error):
            errorCompletion(error)
        case .success(let product):
            self.successCompletion = successCompletion
            self.errorCompletion = errorCompletion
            self.deferredCompletion = deferredCompletion

            let payment = SKMutablePayment(product: product)
            payment.quantity = 1
            if let userId = self.applicationUserId() {
                payment.applicationUsername = self.hash(userId: userId)
            }
            paymentQueue.add(payment)
            PMLog.debug("StoreKit: Purchase started")
        }
    }

    /// This method will be called after relogin and from the SKPaymentTransactionObserver
    public func continueRegistrationPurchase(finishHandler: FinishCallback? = nil) {
        processAllTransactions(finishHandler: finishHandler)
    }

    public func hasUnfinishedPurchase() -> Bool {
        return !paymentQueue.transactions.filter { $0.transactionState != .failed }.isEmpty
    }

    public func readReceipt() throws -> String {
        if isRunningTests, let receiptError = receiptError {
            throw receiptError
        }
        if appStoreLocalTest || isRunningTests {
            return appStoreLocalReceipt
        }
        guard let receiptUrl = Bundle.main.appStoreReceiptURL/*,
            !receiptUrl.lastPathComponent.contains("sandbox")*/ else {
            throw Errors.sandboxReceipt
        }
        PMLog.debug(receiptUrl.path) // make use of this thing so maybe compiler will not screw it up while optimising
        guard let receipt = try? Data(contentsOf: receiptUrl).base64EncodedString() else {
            throw Errors.receiptLost
        }
        return receipt
    }

    // MARK: Internal / private interface

    internal var processingType: ProcessingType {
        if applicationUserId() != nil {
            if delegate?.servicePlanDataService?.currentSubscription?.endDate?.isFuture ?? false {
                return .existingUserAddCredits
            }
            return .existingUserNewSubscription
        }
        return .registration
    }

    private func networkReachable() {
        processAllTransactions(finishHandler: transactionsFinishHandler)
    }
}

extension StoreKitManager: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.availableProducts = response.products
    }

    private func hash(userId: String) -> String {
        return userId.sha256
    }

    private func applicationUserId() -> String? {
        guard let userId = delegate?.userId, !userId.isEmpty else { return nil }
        return userId
    }
}

extension StoreKitManager: SKPaymentTransactionObserver {
    // this will be called right after the purchase and after relaunch
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {

////        // TEMPORARY SOLUTION: finish all pending operations if delegate is not set
//        transactions.forEach {
//            paymentQueue.finishTransaction($0)
//        }
//        return
//
        processAllTransactions(finishHandler: transactionsFinishHandler)
    }

    private func processAllTransactions(finishHandler: FinishCallback?) {
        self.transactionsQueue.cancelAllOperations()

        guard !paymentQueue.transactions.isEmpty else {
            finishHandler?()
            return
        }

        PMLog.debug("StoreKit transaction queue contains transaction(s). Will handle it now.")
        transactionsFinishHandler = finishHandler
        paymentQueue.transactions.forEach { transaction in
            self.addOperation { self.process(transaction: transaction) }
        }
    }

    private func process(transaction: SKPaymentTransaction, shouldVerifyPurchaseWasForSameAccount shouldVerify: Bool = true) {
        switch transaction.transactionState {
        case .failed:
            proceed(withFailed: transaction)
        case .purchased:
            // Flatten async calls inside `proceed()`
            let group = DispatchGroup()
            group.enter()

            try? processPurchased(transaction: transaction, shouldVerifyPurchaseWasForSameAccount: shouldVerify, group: group, completion: {
                group.leave()
            })

        case .deferred, .purchasing:
            self.deferredCompletion?()
        case .restored:
            break // never happens in our flow
        @unknown default:
            break
        }
    }

    private func proceed(withFailed transaction: SKPaymentTransaction) {
        paymentQueue.finishTransaction(transaction)
        let error = transaction.error as NSError?
        switch error {
        case .some(let error):
            if error.code == SKError.paymentCancelled.rawValue {
                self.errorCompletion(Errors.cancelled)
                self.refreshHandler?()
            } else {
                self.errorCompletion(error)
                self.refreshHandler?()
            }
        case .none:
            self.errorCompletion(Errors.transactionFailedByUnknownReason)
        }
    }

    private func processPurchased(transaction: SKPaymentTransaction, shouldVerifyPurchaseWasForSameAccount shouldVerify: Bool, group: DispatchGroup, completion: @escaping CompletionCallback) throws {
        do {
            guard delegate?.isSignedIn ?? false else {
                throw Errors.pleaseSignIn
            }
            guard delegate?.isUnlocked ?? false else {
                throw Errors.appIsLocked
            }
            try self.proceed(withPurchased: transaction, shouldVerifyPurchaseWasForSameAccount: shouldVerify, completion: completion)
        } catch Errors.haveTransactionOfAnotherUser { // user login error
            self.confirmUserValidationBypass(Errors.haveTransactionOfAnotherUser) {
                self.transactionsQueue.addOperation { self.process(transaction: transaction, shouldVerifyPurchaseWasForSameAccount: false) }
                group.leave()
            }
        } catch Errors.sandboxReceipt {  // receipt error
            self.errorCompletion(Errors.sandboxReceipt)
            paymentQueue.finishTransaction(transaction)
            group.leave()

        } catch Errors.receiptLost { // receipt error
            self.errorCompletion(Errors.receiptLost)
            paymentQueue.finishTransaction(transaction)
            group.leave()

        } catch Errors.noNewSubscriptionInSuccessfullResponse { // error on BE
            self.errorCompletion(Errors.noNewSubscriptionInSuccessfullResponse)
            paymentQueue.finishTransaction(transaction)
            group.leave()

        } catch let error { // other errors
            self.errorCompletion(error)
            group.leave()
        }

        group.wait()
    }

    private func proceed(withPurchased transaction: SKPaymentTransaction, shouldVerifyPurchaseWasForSameAccount: Bool = true, completion: @escaping CompletionCallback) throws {

        if shouldVerifyPurchaseWasForSameAccount, let transactionHashedUserId = transaction.payment.applicationUsername {
            try self.verifyCurrentCredentialsMatch(usernameFromTransaction: transactionHashedUserId)
        }

        guard let plan = AccountPlan(storeKitProductId: transaction.payment.productIdentifier) else {
            self.errorCompletion(Errors.alreadyPurchasedPlanDoesNotMatchBackend)
            return
        }

        switch processingType {
        case .existingUserNewSubscription:
            if transactionsMadeBeforeSignup.contains(transaction) {
                try processUnathenticated.processAuthenticatedBeforeSignup(transaction: transaction, plan: plan, completion: completion)
            } else {
                try self.processAuthenticated.process(transaction: transaction, plan: plan, completion: completion)
            }
        case .existingUserAddCredits:
            try processAddCredits.process(transaction: transaction, plan: plan, completion: completion)
        case .registration:
            try processUnathenticated.process(transaction: transaction, plan: plan, completion: completion)
        }
    }
}

extension StoreKitManager {
    /// Adds operation to queue plus adds additional operation that check if queue is empty and calls finish handler if available
    private func addOperation(block: @escaping CompletionCallback) {
        let mainOperation = BlockOperation(block: block)
        let finishOperation = BlockOperation(block: { [weak self] in
            self?.handleQueueFinish()
        })
        finishOperation.addDependency(mainOperation)
        finishOperation.name = "Finish check"
        self.transactionsQueue.addOperation(mainOperation)
        self.transactionsQueue.addOperation(finishOperation)
    }

    private func handleQueueFinish() {
        guard transactionsQueue.operationCount <= 1 else { // The last operation in queue is check for finished queue execution
            return
        }
        transactionsFinishHandler?()
        transactionsFinishHandler = nil
    }
}

extension StoreKitManager {
    private func verifyCurrentCredentialsMatch(usernameFromTransaction hashedTransactionUserId: String) throws {
        guard let userId = self.applicationUserId() else {
            throw Errors.noActiveUsername
        }
        guard hashedTransactionUserId == self.hash(userId: userId) else {
            throw Errors.haveTransactionOfAnotherUser
        }
    }

    private func errorCompletionAlertView(error: Error) {
        paymentsAlertManager.errorAlert(message: error.localizedDescription)
    }

    private func confirmUserValidationAlertView(error: Error, userName: String, completion: @escaping CompletionCallback) {
        let activateMsg = String(format: CoreString._do_you_want_to_bypass_validation, userName)
        let message = """
        \(error.localizedDescription)

        \(activateMsg)
        """
        let confirmButtonTitle = CoreString._yes_bypass_validation + userName
        paymentsAlertManager.userValidationAlert(message: message, confirmButtonTitle: confirmButtonTitle) { _ in
            completion()
        }
    }
}

extension StoreKitManager: ProcessDelegateProtocol {
    var storeKitDelegate: StoreKitManagerDelegate? { return delegate }
    var tokenStorage: PaymentTokenStorage? { return commonTokenStorage }
    var paymentsApiProtocol: PaymentsApiProtocol { return paymentsApi }
    var paymentQueueProtocol: PaymentQueueProtocol { return paymentQueue }
    var alertManager: PaymentsAlertManager { return paymentsAlertManager }
    var successCallback: StoreKitManager.SuccessCallback? { return successCompletion }
    var errorCallback: StoreKitManager.ErrorCallback { return errorCompletion }
    var transactionsBeforeSignup: [SKPaymentTransaction] {
        get { return transactionsMadeBeforeSignup }
        set { transactionsMadeBeforeSignup = newValue }
    }
    var pendingRetry: Double { return pendingRetryIn }
    var errorRetry: Double { return errorRetryIn }
    func getReceipt() throws -> String { return try readReceipt() }
}
