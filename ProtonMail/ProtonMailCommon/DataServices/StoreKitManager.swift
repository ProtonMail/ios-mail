//
//  StoreKitManager.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 21/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import StoreKit
import AwaitKit

class StoreKitManager: NSObject {
    static var `default` = StoreKitManager()
    private override init() {
        super.init()
    }
    
    private var productIds = Set([ServicePlan.plus.storeKitProductId!])
    private var availableProducts: [SKProduct] = []
    private var request: SKProductsRequest!
    private var transactionsQueue: OperationQueue = {
       let queue = OperationQueue()
        queue.qualityOfService = QualityOfService.userInteractive
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    private var successCompletion: (()->Void)?
    private var deferredCompletion: (()->Void)?
    private var errorCompletion: (Error)->Void = { error in
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            let alert = UIAlertController(title: LocalString._error_occured, message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(.init(title: LocalString._general_ok_action, style: .cancel, handler: nil))
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    internal func subscribeToPaymentQueue() {
        SKPaymentQueue.default().add(self)
    }
    
    internal func updateAvailableProductsList() {
        request = SKProductsRequest(productIdentifiers: self.productIds)
        request.delegate = self
        request.start()
    }
    
    internal func priceLabelForProduct(id: String) -> (NSDecimalNumber, Locale)? {
        guard let product = self.availableProducts.first(where: { $0.productIdentifier == id }) else {
            return nil
        }
        return (product.price, product.priceLocale)
    }
    
    internal func readyToPurchaseProduct() -> Bool {
        // no matter which user is logged in now, if there is any unfinished transaction - we do not want to give opportunity to start new purchase. BE currently can process only last transaction in Receipts, so we do not want to mess up the older ones.
        return SKPaymentQueue.default().transactions.isEmpty
    }
    
    internal func purchaseProduct(withId id: String,
                                  successCompletion: @escaping ()->Void,
                                  errorCompletion: @escaping (Error)->Void,
                                  deferredCompletion: @escaping ()->Void)
    {
        guard let username = sharedUserDataService.username else {
            errorCompletion(Errors.noActiveUsernameInUserDataService)
            return
        }
        
        guard let product = self.availableProducts.first(where: { $0.productIdentifier == id }) else {
            errorCompletion(Errors.unavailableProduct)
            return
        }
        
        self.successCompletion = successCompletion
        self.errorCompletion = errorCompletion
        self.deferredCompletion = deferredCompletion
        
        let payment = SKMutablePayment(product: product)
        payment.quantity = 1
        payment.applicationUsername = self.hash(username: username)
        SKPaymentQueue.default().add(payment)
    }
    
    enum Errors: LocalizedError {
        case unavailableProduct
        case recieptLost
        case haveTransactionOfAnotherUser
        case alreadyPurchasedPlanDoesNotMatchBackend
        case sandboxReceipt
        case noHashedUsernameArrivedInTransaction
        case noActiveUsernameInUserDataService
        case transactionFailedByUnknownReason
        
        var errorDescription: String? {
            switch self {
            case .unavailableProduct: return LocalString._unavailable_product
            case .recieptLost: return LocalString._reciept_lost
            case .haveTransactionOfAnotherUser: return LocalString._another_user_transaction
            case .alreadyPurchasedPlanDoesNotMatchBackend: return LocalString._backend_mismatch
            case .sandboxReceipt: return LocalString._sandbox_receipt
            case .noHashedUsernameArrivedInTransaction: return LocalString._no_hashed_username_arrived_in_transaction
            case .noActiveUsernameInUserDataService: return LocalString._no_active_username_in_user_data_service
            case .transactionFailedByUnknownReason: return LocalString._transaction_failed_by_unknown_reason
            }
        }
    }
}

extension StoreKitManager: SKProductsRequestDelegate {
    internal func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.availableProducts = response.products
    }
    
    private func hash(username: String) -> String {
        let lowercase = username.lowercased()
        let stripCom = lowercase.replacingOccurrences(of: "@protonmail.com", with: "")
        let stripCh = stripCom.replacingOccurrences(of: "@protonmail.ch", with: "")
        return stripCh.sha256
    }
}

extension StoreKitManager: SKPaymentTransactionObserver {
    // this will be called right after the purchase and after relaunch
    internal func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        self.processTransactions()
    }
    
    // this will be called after relogin and from the method above
    internal func processTransactions() {
        self.transactionsQueue.cancelAllOperations()
        SKPaymentQueue.default().transactions.forEach { transaction in
            self.transactionsQueue.addOperation { self.process(transaction) }
        }
    }
    
    // TODO: break down into multiple methods
    private func process(_ transaction: SKPaymentTransaction) {
        switch transaction.transactionState {
        case .failed:
            let error = transaction.error as NSError?
            switch error {
            case .some(SKError.paymentCancelled): break // no need to do anything
            case .some(let error): self.errorCompletion(error)
            case .none: self.errorCompletion(Errors.transactionFailedByUnknownReason)
            }
            SKPaymentQueue.default().finishTransaction(transaction)
            
        case .purchased:
            guard let hashedUsername = transaction.payment.applicationUsername else {
                self.errorCompletion(Errors.noHashedUsernameArrivedInTransaction)
                return
            }
            guard let currentUsername = sharedUserDataService.username else {
                self.errorCompletion(Errors.noActiveUsernameInUserDataService)
                return
            }
            guard hashedUsername == self.hash(username: currentUsername) else {
                self.errorCompletion(Errors.haveTransactionOfAnotherUser)
                return
            }
            
            guard let receiptUrl = Bundle.main.appStoreReceiptURL,
                !receiptUrl.lastPathComponent.contains("sandbox") else
            {
                self.errorCompletion(Errors.sandboxReceipt)
                SKPaymentQueue.default().finishTransaction(transaction)
                return
            }
            
            guard let reciept = try? Data(contentsOf: receiptUrl).base64EncodedString() else {
                self.errorCompletion(Errors.recieptLost)
                SKPaymentQueue.default().finishTransaction(transaction)
                return
            }
            do {
                guard let plan = ServicePlan(storeKitProductId: transaction.payment.productIdentifier),
                    let details = plan.fetchDetails(),
                    let planId = details.iD else
                {
                    throw Errors.alreadyPurchasedPlanDoesNotMatchBackend
                }
                let serverUpdateApi = PostRecieptRequest(reciept: reciept, andActivatePlanWithId: planId)
                let serverUpdateRes = try await(serverUpdateApi.run())
                if let newSubscription = serverUpdateRes.newSubscription {
                    ServicePlanDataService.shared.currentSubscription = newSubscription
                }
                self.successCompletion?()
                SKPaymentQueue.default().finishTransaction(transaction)
            } catch let error {
                switch (error as NSError).code {
                case 22101:
                    // Amount mismatch - try report only credits without activating the plan
                    do {
                        let serverUpdateApi = PostCreditRequest(reciept: reciept)
                        let _ = try await(serverUpdateApi.run())
                        self.successCompletion?()
                        SKPaymentQueue.default().finishTransaction(transaction)
                    } catch let error {
                        if (error as NSError).code == 22915 { // Apple payment already registered
                            SKPaymentQueue.default().finishTransaction(transaction)
                        } else {
                            self.errorCompletion(error)
                        }
                    }
//                case 22914: //TODO:: need to handle this properly
//                    SKPaymentQueue.default().finishTransaction(transaction)
//                    self.successCompletion?()
                default:
                    self.errorCompletion(error)
                }
            }
        case .deferred, .purchasing:
            self.deferredCompletion?()
            
        case .restored:
            break // never happens in our flow
        }
    }
}
