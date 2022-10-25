//
//  StoreKitManager.swift
//  ProtonCore-Payments - Created on 21/08/2018.
//
//  Copyright (c) 2022 Proton Technologies AG
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

import StoreKit
import Reachability
import ProtonCore_CoreTranslation
import ProtonCore_Log
import ProtonCore_Hash
import ProtonCore_Services

final class StoreKitManager: NSObject, StoreKitManagerProtocol {

    typealias Errors = StoreKitManagerErrors

    // MARK: Public properties
    public weak var delegate: StoreKitManagerDelegate?
    public var refreshHandler: (ProcessCompletionResult) -> Void

    public var inAppPurchaseIdentifiers: ListOfIAPIdentifiers {
        get { inAppPurchaseIdentifiersGet() }
        set { inAppPurchaseIdentifiersSet(newValue) }
    }
    private let inAppPurchaseIdentifiersGet: ListOfIAPIdentifiersGet
    private let inAppPurchaseIdentifiersSet: ListOfIAPIdentifiersSet
    let planService: ServicePlanDataServiceProtocol
    private let paymentsAlertManager: PaymentsAlertManager
    private let paymentsApi: PaymentsApiProtocol
    let apiService: APIService
    let canExtendSubscription: Bool
    var reportBugAlertHandler: BugAlertHandler

    var paymentQueue: PaymentQueueProtocol = SKPaymentQueue.default()
    private(set) var request: SKProductsRequest?
    private var updateAvailableProductsListCompletionBlock: ((Error?) -> Void)?

    var pendingRetryIn: Double = 30
    var errorRetryIn: Double = 2
    var alertViewDelay: Double = 1.0
    var receiptError: Error?
    var availableProducts: [SKProduct] = []

    // MARK: Private properties
    private lazy var processAuthenticated = ProcessAuthenticated(dependencies: self)
    private lazy var processUnathenticated = ProcessUnauthenticated(dependencies: self)
    private lazy var processAddCredits = ProcessAddCredits(dependencies: self)
    private lazy var validationManager = ValidationManager(dependencies: self)
    private lazy var commonTokenStorage = TokenStorage(tokenStorage: storeKitDelegate?.tokenStorage)

    private let reachability: Reachability?
    private var transactionsQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = QualityOfService.userInteractive
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    private var transactionsMadeBeforeSignup = [SKPaymentTransaction]()
    private var notifyWhenTransactionsWaitingForTheSignupAppear: ([InAppPurchasePlan]) -> Void = { _ in }
    func getNotifiedWhenTransactionsWaitingForTheSignupAppear(completion: @escaping ([InAppPurchasePlan]) -> Void) -> [InAppPurchasePlan] {
        let currentTransactions = transactionsMadeBeforeSignup.compactMap {
            InAppPurchasePlan(storeKitProductId: $0.payment.productIdentifier)
        }
        notifyWhenTransactionsWaitingForTheSignupAppear = completion
        return currentTransactions
    }
    func stopBeingNotifiedWhenTransactionsWaitingForTheSignupAppear() {
        notifyWhenTransactionsWaitingForTheSignupAppear = { _ in }
    }

    private var transactionsFinishHandler: FinishCallback?

    struct UserInitiatedPurchaseCache: Hashable {
        let storeKitProductId: String
        let hashedUserId: String?
    }

    final class ThreadSafeAsyncCache {

        private let accessQueue = DispatchQueue(label: "ThreadSafeCache queue")

        typealias Key = UserInitiatedPurchaseCache
        var amountDue: [Key: Int] = [:]
        var successCompletion: [Key: SuccessCallback] = [:]
        var deferredCompletion: [Key: FinishCallback?] = [:]
        var errorCompletion: [Key: ErrorCallback?] = [:]

        func set<K, V>(value: V, for key: K, in dict: ReferenceWritableKeyPath<ThreadSafeAsyncCache, [K: V]>) {
            accessQueue.async { self[keyPath: dict][key] = value }
        }

        func removeValue<K, V>(
            for key: K, in dict: ReferenceWritableKeyPath<ThreadSafeAsyncCache, [K: V]>, completion: @escaping (V?) -> Void
        ) {
            accessQueue.async { completion(self[keyPath: dict].removeValue(forKey: key)) }
        }

        func removeValueSynchronously<K, V>(for key: K,
                                            in dict: ReferenceWritableKeyPath<ThreadSafeAsyncCache, [K: V]>) -> V? {
            accessQueue.sync { self[keyPath: dict].removeValue(forKey: key) }
        }

        func removeValue<K, V>(for key: K,
                               in dict: ReferenceWritableKeyPath<ThreadSafeAsyncCache, [K: V]>,
                               defaultValue: V,
                               completion: @escaping (V) -> Void) {
            removeValue(for: key, in: dict) { valueIfExists in
                if let value = valueIfExists {
                    completion(value)
                } else {
                    completion(defaultValue)
                }
            }
        }
    }

    private var threadSafeCache: ThreadSafeAsyncCache = .init()

    private func callSuccessCompletion(for cache: UserInitiatedPurchaseCache, with result: PaymentSucceeded) {
        threadSafeCache.removeValue(for: cache, in: \.successCompletion, defaultValue: defaultSuccessCallback) { $0(result) }
    }

    private func callDeferredCompletion(for cache: UserInitiatedPurchaseCache) {
        threadSafeCache.removeValue(for: cache, in: \.deferredCompletion, defaultValue: nil) { $0?() }
    }

    private func callErrorCompletion(for cache: UserInitiatedPurchaseCache, with error: Error) {
        threadSafeCache.removeValue(for: cache, in: \.errorCompletion, defaultValue: defaultErrorCallback) { $0?(error) }
    }
    
    private func getSuccessCompletion(for cache: UserInitiatedPurchaseCache, completion: @escaping (SuccessCallback?) -> Void) {
        threadSafeCache.removeValue(for: cache, in: \.successCompletion, completion: completion)
    }

    private func getErrorCompletion(for cache: UserInitiatedPurchaseCache, completion: @escaping (ErrorCallback?) -> Void) {
        threadSafeCache.removeValue(for: cache, in: \.errorCompletion, defaultValue: defaultErrorCallback, completion: completion)
    }
    
    private lazy var defaultSuccessCallback: SuccessCallback = { [weak self] result in
        guard let self = self else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + self.alertViewDelay) { [weak self] in
            self?.successCompletionAlertView(result: result)
        }
    }

    private lazy var defaultErrorCallback: ErrorCallback = { [weak self] error in
        guard let self = self else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + self.alertViewDelay) { [weak self] in
            self?.errorCompletionAlertView(error: error)
        }
    }

    private lazy var confirmUserValidationBypass: (UserInitiatedPurchaseCache, Error, @escaping () -> Void) -> Void = { [weak self] cacheKey, error, completion in
        guard let self = self else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + self.alertViewDelay) { [weak self] in
            guard let currentUsername = self?.delegate?.activeUsername else {
                self?.callErrorCompletion(for: cacheKey, with: Errors.noActiveUsername)
                return
            }
            self?.confirmUserValidationAlertView(error: error, userName: currentUsername, completion: completion)
        }
    }
    
    private var processingType: ProcessingType {
        guard applicationUserId() == nil else {
            if planService.currentSubscription?.endDate?.isFuture ?? false {
                return .existingUserAddCredits
            }
            return .existingUserNewSubscription
        }
        return .registration
    }
    
    private var removedTransactions: (([SKPaymentTransaction]) -> Void)?
    
    private func finishTransaction(transaction: SKPaymentTransaction, finishCallback: (() -> Void)?) {
        paymentQueue.finishTransaction(transaction)
        removedTransactions = { transactions in
            if transactions.contains(transaction) {
                finishCallback?()
            }
        }
    }

    init(inAppPurchaseIdentifiersGet: @escaping ListOfIAPIdentifiersGet,
         inAppPurchaseIdentifiersSet: @escaping ListOfIAPIdentifiersSet,
         planService: ServicePlanDataServiceProtocol,
         paymentsApi: PaymentsApiProtocol,
         apiService: APIService,
         canExtendSubscription: Bool,
         paymentsAlertManager: PaymentsAlertManager,
         reportBugAlertHandler: BugAlertHandler,
         refreshHandler: @escaping (ProcessCompletionResult) -> Void,
         reachability: Reachability? = try? Reachability()) {
        self.inAppPurchaseIdentifiersGet = inAppPurchaseIdentifiersGet
        self.inAppPurchaseIdentifiersSet = inAppPurchaseIdentifiersSet
        self.planService = planService
        self.paymentsApi = paymentsApi
        self.apiService = apiService
        self.canExtendSubscription = canExtendSubscription
        self.paymentsAlertManager = paymentsAlertManager
        self.reportBugAlertHandler = reportBugAlertHandler
        self.refreshHandler = refreshHandler
        self.reachability = reachability
        super.init()
        reachability?.whenReachable = { [weak self] _ in self?.networkReachable() }
        try? reachability?.startNotifier()
    }

    deinit {
        unsubscribeFromPaymentQueue()
        reachability?.stopNotifier()
    }

    public func subscribeToPaymentQueue() {
        unsubscribeFromPaymentQueue()
        paymentQueue.add(self)
    }
    
    public func unsubscribeFromPaymentQueue() {
        paymentQueue.remove(self)
    }

    public func updateAvailableProductsList(completion: @escaping (Error?) -> Void) {
        updateAvailableProductsListCompletionBlock = { error in DispatchQueue.main.async { completion(error) } }
        request = SKProductsRequest(productIdentifiers: inAppPurchaseIdentifiersGet())
        request?.delegate = self
        request?.start()
    }

    public func priceLabelForProduct(storeKitProductId: String) -> (NSDecimalNumber, Locale)? {
        guard let product = availableProducts.first(where: { $0.productIdentifier == storeKitProductId })
        else { return nil }
        return (product.price, product.priceLocale)
    }

    public func currentTransaction() -> SKPaymentTransaction? {
        return paymentQueue.transactions.filter {
            $0.transactionState != .failed && $0.transactionState != .purchasing && $0.transactionState != .deferred
        }.first
    }

    public func isValidPurchase(storeKitProductId: String, completion: @escaping (Bool) -> Void) {
        let planService = planService
        planService.updateServicePlans(callBlocksOnParticularQueue: nil) { [weak self] in
            guard planService.isIAPAvailable else {
                completion(false)
                return
            }
            planService.updateCurrentSubscription(callBlocksOnParticularQueue: nil) { [weak self] in
                completion(self?.validationManager.isValidPurchase(storeKitProductId: storeKitProductId) ?? false)
            } failure: { _ in
                completion(false)
            }
        } failure: { _ in
            completion(false)
        }
    }

    public func purchaseProduct(plan: InAppPurchasePlan,
                                amountDue: Int,
                                successCompletion: @escaping SuccessCallback,
                                errorCompletion: @escaping ErrorCallback,
                                deferredCompletion: (() -> Void)? = nil) {

        guard let storeKitProductId = plan.storeKitProductId,
              let product = availableProducts.first(where: { $0.productIdentifier == storeKitProductId })
        else { return errorCompletion(Errors.unavailableProduct) }

        planService.updateServicePlans(callBlocksOnParticularQueue: nil) { [weak self] in
            guard let self = self else {
                errorCompletion(Errors.transactionFailedByUnknownReason)
                return
            }
            guard self.planService.isIAPAvailable,
                  let details = self.planService.detailsOfServicePlan(named: plan.protonName),
                  details.isPurchasable else {
                errorCompletion(Errors.unavailableProduct)
                return
            }

            guard let userId = self.applicationUserId() else {
                self.purchaseProductWithoutAnAuthorizedUser(storeKitProduct: product,
                                                            amountDue: amountDue,
                                                            successCompletion: successCompletion,
                                                            errorCompletion: errorCompletion,
                                                            deferredCompletion: deferredCompletion)
                return
            }

            self.purchaseProductBeingAuthorized(plan: plan,
                                                storeKitProduct: product,
                                                amountDue: amountDue,
                                                userId: userId,
                                                successCompletion: successCompletion,
                                                errorCompletion: errorCompletion,
                                                deferredCompletion: deferredCompletion)

        } failure: { error in
            errorCompletion(error)
        }
    }

    private func purchaseProductWithoutAnAuthorizedUser(storeKitProduct: SKProduct,
                                                        amountDue: Int,
                                                        successCompletion: @escaping SuccessCallback,
                                                        errorCompletion: @escaping ErrorCallback,
                                                        deferredCompletion: (() -> Void)?) {
        let amountDueCacheKey = UserInitiatedPurchaseCache(storeKitProductId: storeKitProduct.productIdentifier,
                                                           hashedUserId: nil)
        threadSafeCache.set(value: amountDue, for: amountDueCacheKey, in: \.amountDue)
        initiateStoreKitInAppPurchaseFlow(storeKitProduct: storeKitProduct,
                                           hashedUserId: nil,
                                           successCompletion: successCompletion,
                                           errorCompletion: errorCompletion,
                                           deferredCompletion: deferredCompletion)
    }

    // swiftlint:disable function_parameter_count
    private func purchaseProductBeingAuthorized(plan: InAppPurchasePlan,
                                                storeKitProduct: SKProduct,
                                                amountDue: Int,
                                                userId: String,
                                                successCompletion: @escaping SuccessCallback,
                                                errorCompletion: @escaping ErrorCallback,
                                                deferredCompletion: (() -> Void)?) {

        let hashedUserId = hash(userId: userId)

        let amountDueCacheKey = UserInitiatedPurchaseCache(storeKitProductId: storeKitProduct.productIdentifier, hashedUserId: hashedUserId)
        
        threadSafeCache.set(value: amountDue, for: amountDueCacheKey, in: \.amountDue)

        planService.updateCurrentSubscription(callBlocksOnParticularQueue: nil) { [weak self] in
            guard let self = self else {
                errorCompletion(Errors.transactionFailedByUnknownReason)
                return
            }
            
            guard self.planService.currentSubscription?.hasExistingProtonSubscription == false || (!self.planService.hasPaymentMethods && self.planService.currentSubscription?.hasExistingProtonSubscription == true && self.canExtendSubscription && !self.planService.willRenewAutomatically(plan: plan)) else {
                errorCompletion(Errors.invalidPurchase)
                return
            }

            self.initiateStoreKitInAppPurchaseFlow(storeKitProduct: storeKitProduct,
                                                   hashedUserId: hashedUserId,
                                                   successCompletion: successCompletion,
                                                   errorCompletion: errorCompletion,
                                                   deferredCompletion: deferredCompletion)
        } failure: { error in
            errorCompletion(error)
        }
    }

    private func applicationUserId() -> String? {
        guard let userId = delegate?.userId, !userId.isEmpty else { return nil }
        return userId
    }

    private func hash(userId: String) -> String {
        userId.sha256
    }

    private func initiateStoreKitInAppPurchaseFlow(storeKitProduct: SKProduct,
                                                   hashedUserId: String?,
                                                   successCompletion: @escaping SuccessCallback,
                                                   errorCompletion: @escaping ErrorCallback,
                                                   deferredCompletion: (() -> Void)? = nil) {

        let callbackCacheKey = UserInitiatedPurchaseCache(storeKitProductId: storeKitProduct.productIdentifier,
                                                          hashedUserId: hashedUserId)
        threadSafeCache.set(value: successCompletion, for: callbackCacheKey, in: \.successCompletion)
        threadSafeCache.set(value: deferredCompletion, for: callbackCacheKey, in: \.deferredCompletion)
        threadSafeCache.set(value: errorCompletion, for: callbackCacheKey, in: \.errorCompletion)

        let payment = SKMutablePayment(product: storeKitProduct)
        payment.quantity = 1
        payment.applicationUsername = hashedUserId
        paymentQueue.add(payment)
        PMLog.debug("StoreKit: Purchase started")
    }

    /// This method will be called after relogin and from the SKPaymentTransactionObserver
    public func retryProcessingAllPendingTransactions(finishHandler: FinishCallback? = nil) {
        processAllStoreKitTransactionsCurrentlyFoundInThePaymentQueue(finishHandler: finishHandler)
    }

    public func hasUnfinishedPurchase() -> Bool {
        return !paymentQueue.transactions.filter { $0.transactionState != .failed }.isEmpty
    }
    
    public func hasIAPInProgress() -> Bool {
        return paymentQueue.transactions.filter {
            $0.transactionState == .purchasing || $0.transactionState == .deferred
        }.isEmpty == false
    }

    public func readReceipt() throws -> String {
        if isRunningTests {
            if let receiptError = receiptError {
                throw receiptError
            } else {
                return "Test"
            }
        }
        guard let receiptUrl = Bundle.main.appStoreReceiptURL,
              let receipt = try? Data(contentsOf: receiptUrl).base64EncodedString()
        else { throw Errors.receiptLost }
        return receipt
    }

    private func networkReachable() {
        processAllStoreKitTransactionsCurrentlyFoundInThePaymentQueue(finishHandler: transactionsFinishHandler)
    }
}

extension StoreKitManager: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if !response.invalidProductIdentifiers.isEmpty {
            PMLog.error("Some IAP identifiers are reported as invalid by the AppStore: \(response.invalidProductIdentifiers)")
        }
        inAppPurchaseIdentifiersSet(Set(response.products.map(\.productIdentifier)))
        availableProducts = response.products
        updateAvailableProductsListCompletionBlock?(nil)
        updateAvailableProductsListCompletionBlock = nil
        self.request = nil
    }

    func request(_: SKRequest, didFailWithError error: Error) {
        #if targetEnvironment(simulator)
        if let skerror = error as? SKError, skerror.code == .unknown {
            updateAvailableProductsListCompletionBlock?(nil)
        } else {
            updateAvailableProductsListCompletionBlock?(error)
        }
        #else
        updateAvailableProductsListCompletionBlock?(error)
        #endif
        updateAvailableProductsListCompletionBlock = nil
        self.request = nil
    }
}

extension StoreKitManager: SKPaymentTransactionObserver {
    // this will be called right after the purchase and after relaunch
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        processAllStoreKitTransactionsCurrentlyFoundInThePaymentQueue(finishHandler: transactionsFinishHandler)
    }

    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        removedTransactions?(transactions)
    }
    
    private func processAllStoreKitTransactionsCurrentlyFoundInThePaymentQueue(finishHandler: FinishCallback?) {
        self.transactionsQueue.cancelAllOperations()

        guard !paymentQueue.transactions.isEmpty else {
            finishHandler?()
            return
        }

        PMLog.debug("StoreKit transaction queue contains transaction(s). Will handle it now.")
        transactionsFinishHandler = finishHandler
        paymentQueue.transactions.forEach { [weak self] transaction in
            self?.addStoreKitTransactionProcessingOperation { [weak self] in
                self?.processStoreKitTransaction(transaction: transaction, shouldVerifyPurchaseWasForSameAccount: true)
            }
        }
    }

    private func processStoreKitTransaction(transaction: SKPaymentTransaction,
                                            shouldVerifyPurchaseWasForSameAccount shouldVerify: Bool) {

        let storeKitProductId = transaction.payment.productIdentifier
        let cacheKey = UserInitiatedPurchaseCache(storeKitProductId: storeKitProductId, hashedUserId: applicationUserId().map(hash(userId:)))

        switch transaction.transactionState {
        case .failed:
            processFailedStoreKitTransaction(transaction, cacheKey: cacheKey)
        case .purchased:
            // Flatten async calls inside `proceed()`
            let group = DispatchGroup()
            group.enter()

            processPurchasedStoreKitTransaction(
                transaction, cacheKey: cacheKey, shouldVerifyPurchaseWasForSameAccount: shouldVerify, group: group
            ) { [weak self] result in
                switch result {
                case .finished(let result):
                    self?.callSuccessCompletion(for: cacheKey, with: result)
                case .errored(let storeKitError):
                    self?.callErrorCompletion(for: cacheKey, with: storeKitError)
                case .erroredWithUnspecifiedError(let error):
                    self?.callErrorCompletion(for: cacheKey, with: error)
                }
                group.leave()
            }

        case .deferred, .purchasing:
            callDeferredCompletion(for: cacheKey)
        case .restored:
            break // never happens in our flow
        @unknown default:
            break
        }
    }

    private func processFailedStoreKitTransaction(_ transaction: SKPaymentTransaction, cacheKey: UserInitiatedPurchaseCache) {
        finishTransaction(transaction, nil)
        let error = transaction.error as NSError?
        let refreshHandler = refreshHandler
        switch error {
        case .some(let error):
            if error.code == SKError.paymentCancelled.rawValue {
                getSuccessCompletion(for: cacheKey) {
                    $0?(.cancelled)
                    // no need for a refresh on cancellation, nothing changed
                }
            } else if error.code == SKError.paymentNotAllowed.rawValue {
                getErrorCompletion(for: cacheKey) {
                    let error = Errors.notAllowed
                    $0?(error)
                    refreshHandler(.errored(error))
                }
            } else if error.code == SKError.unknown.rawValue {
                getErrorCompletion(for: cacheKey) {
                    let error = Errors.unknown(code: error.code, originalError: error)
                    $0?(error)
                    refreshHandler(.errored(error))
                }
            } else {
                getErrorCompletion(for: cacheKey) {
                    $0?(error)
                    refreshHandler(.errored(.unknown(code: error.code, originalError: error)))
                }
            }
        case .none:
            getErrorCompletion(for: cacheKey) { $0?(Errors.transactionFailedByUnknownReason) }
        }
    }

    private func processPurchasedStoreKitTransaction(_ transaction: SKPaymentTransaction,
                                                     cacheKey: UserInitiatedPurchaseCache,
                                                     shouldVerifyPurchaseWasForSameAccount: Bool,
                                                     group: DispatchGroup,
                                                     completion: @escaping ProcessCompletionCallback) {
        do {
            guard delegate?.isSignedIn ?? false else {
                throw Errors.pleaseSignIn
            }
            guard delegate?.isUnlocked ?? false else {
                throw Errors.appIsLocked
            }

            if shouldVerifyPurchaseWasForSameAccount, let transactionHashedUserId = transaction.payment.applicationUsername {
                try verifyCurrentCredentialsMatch(usernameFromTransaction: transactionHashedUserId)
            }

            try informProtonBackendAboutPurchasedTransaction(transaction, cacheKey: cacheKey, completion: completion)

        } catch Errors.haveTransactionOfAnotherUser { // user login error
            confirmUserValidationBypass(cacheKey, Errors.haveTransactionOfAnotherUser) { [weak self] in
                self?.transactionsQueue.addOperation { [weak self] in
                    self?.processStoreKitTransaction(transaction: transaction, shouldVerifyPurchaseWasForSameAccount: false)
                }
                group.leave()
            }

        } catch Errors.receiptLost { // receipt error
            callErrorCompletion(for: cacheKey, with: Errors.receiptLost)
            finishTransaction(transaction, nil)
            group.leave()

        } catch Errors.noNewSubscriptionInSuccessfullResponse { // error on BE
            callErrorCompletion(for: cacheKey, with: Errors.noNewSubscriptionInSuccessfullResponse)
            finishTransaction(transaction, nil)
            group.leave()

        } catch let error { // other errors
            callErrorCompletion(for: cacheKey, with: error)
            group.leave()
        }

        group.wait()
    }

    private func informProtonBackendAboutPurchasedTransaction(_ transaction: SKPaymentTransaction,
                                                              cacheKey: UserInitiatedPurchaseCache,
                                                              completion: @escaping ProcessCompletionCallback) throws {

        guard let plan = InAppPurchasePlan(storeKitProductId: transaction.payment.productIdentifier)
        else { throw Errors.alreadyPurchasedPlanDoesNotMatchBackend }

        if planService.detailsOfServicePlan(named: plan.protonName) == nil {
            try planService.updateServicePlans()
        }

        guard let details = planService.detailsOfServicePlan(named: plan.protonName),
              let amount = details.pricing(for: plan.period),
              let protonIdentifier = details.iD
        else { throw Errors.alreadyPurchasedPlanDoesNotMatchBackend }

        let amountDue: Int
        if let cachedAmountDue = threadSafeCache.removeValueSynchronously(for: cacheKey, in: \.amountDue) {
            amountDue = cachedAmountDue
        } else {
            let validateSubscriptionRequest = paymentsApi.validateSubscriptionRequest(
                api: apiService, protonPlanName: details.name, isAuthenticated: applicationUserId() != nil
            )
            let response = try? validateSubscriptionRequest.awaitResponse(responseObject: ValidateSubscriptionResponse())
            let fetchedAmountDue = response?.validateSubscription?.amountDue
            amountDue = fetchedAmountDue ?? amount
        }

        let planToBeProcessed = PlanToBeProcessed(protonIdentifier: protonIdentifier, amount: amount, amountDue: amountDue)

        switch processingType {
        case .existingUserNewSubscription:
            if transactionsMadeBeforeSignup.contains(transaction) {
                try processUnathenticated.processAuthenticatedBeforeSignup(
                    transaction: transaction, plan: planToBeProcessed, completion: completion
                )
            } else {
                try processAuthenticated.process(
                    transaction: transaction, plan: planToBeProcessed, completion: completion
                )
            }
        case .existingUserAddCredits:
            try processAddCredits.process(transaction: transaction, plan: planToBeProcessed, completion: completion)
        case .registration:
            try processUnathenticated.process(
                transaction: transaction, plan: planToBeProcessed, completion: completion
            )
        }
    }
}

extension StoreKitManager {
    /// Adds operation to queue plus adds additional operation that check if queue is empty and calls finish handler if available
    private func addStoreKitTransactionProcessingOperation(block: @escaping () -> Void) {
        let mainOperation = BlockOperation(block: block)
        let finishOperation = BlockOperation(block: { [weak self] in
            self?.handleQueueFinish()
        })
        finishOperation.addDependency(mainOperation)
        finishOperation.name = "Finish check"
        transactionsQueue.addOperation(mainOperation)
        transactionsQueue.addOperation(finishOperation)
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
        guard let userId = applicationUserId() else {
            throw Errors.noActiveUsername
        }
        guard hashedTransactionUserId == hash(userId: userId) else {
            throw Errors.haveTransactionOfAnotherUser
        }
    }
    
    private func successCompletionAlertView(result: PaymentSucceeded) {
        guard case .resolvingIAPToCreditsCausedByError = result else { return }
        paymentsAlertManager.creditsAppliedAlert { [weak self] in
            guard let self = self else { return }
            self.reportBugAlertHandler?(try? self.readReceipt())
            self.refreshHandler(.finished(result))
        } cancelAction: { [weak self] in
            self?.refreshHandler(.finished(result))
        }
    }

    private func errorCompletionAlertView(error: Error) {
        paymentsAlertManager.errorAlert(message: error.userFacingMessageInPayments)
    }

    private func confirmUserValidationAlertView(error: Error, userName: String, completion: @escaping () -> Void) {
        let activateMsg = String(format: CoreString._do_you_want_to_bypass_validation, userName)
        let message = """
        \(error.userFacingMessageInPayments)

        \(activateMsg)
        """
        let confirmButtonTitle = CoreString._yes_bypass_validation + userName
        paymentsAlertManager.userValidationAlert(message: message, confirmButtonTitle: confirmButtonTitle) {
            completion()
        }
    }
}

extension StoreKitManager: ProcessDependencies {
    var storeKitDelegate: StoreKitManagerDelegate? { return delegate }
    var tokenStorage: PaymentTokenStorage { return commonTokenStorage }
    var paymentsApiProtocol: PaymentsApiProtocol { return paymentsApi }
    var alertManager: PaymentsAlertManager { return paymentsAlertManager }
    var updateSubscription: (Subscription) -> Void { { [weak self] in self?.planService.currentSubscription = $0 } }
    func updateCurrentSubscription(success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
        planService.updateCurrentSubscription(success: success, failure: failure)
    }
    
    var finishTransaction: (SKPaymentTransaction, (() -> Void)?) -> Void { {
        self.finishTransaction(transaction: $0, finishCallback: $1)
    } }
    
    func addTransactionsBeforeSignup(transaction: SKPaymentTransaction) {
        // TODO: should it be thread safe?
        transactionsMadeBeforeSignup.append(transaction)
        notifyWhenTransactionsWaitingForTheSignupAppear(
            transactionsMadeBeforeSignup.compactMap { InAppPurchasePlan(storeKitProductId: $0.payment.productIdentifier) }
        )
    }
    func removeTransactionsBeforeSignup(transaction: SKPaymentTransaction) {
        // TODO: should it be thread safe?
        transactionsMadeBeforeSignup.removeAll(where: { $0 == transaction })
        notifyWhenTransactionsWaitingForTheSignupAppear(
            transactionsMadeBeforeSignup.compactMap { InAppPurchasePlan(storeKitProductId: $0.payment.productIdentifier) }
        )
    }
    var pendingRetry: Double { return pendingRetryIn }
    var errorRetry: Double { return errorRetryIn }
    func getReceipt() throws -> String { return try readReceipt() }
    var bugAlertHandler: BugAlertHandler { return reportBugAlertHandler }
    var refreshCompletionHandler: (ProcessCompletionResult) -> Void { return refreshHandler }
}

extension StoreKitManager: ValidationManagerDependencies {
    var products: [SKProduct] { availableProducts }
}
