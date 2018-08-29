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
    
    private var productIds = Set(["2SB5Z68H26.ch.protonmail.protonmail.Test_ProtonMail_Plus_3",
                                  "2SB5Z68H26.ch.protonmail.protonmail.1432732885",
                                  "ch.protonmail.protonmail.1432732885",
                                  "1432732885",
                                  "Test_ProtonMail_Plus_3",
                                  "ch.protonmail.protonmail.Test_ProtonMail_Plus_3"])
    private var availableProducts: [SKProduct] = []
    private var request: SKProductsRequest!
    
    private var successCompletion: (()->Void)?
    private var errorCompletion: ((Error)->Void)?
    private var deferredCompletion: (()->Void)?
    
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
    
    internal func readyToPurchaseProduct(id productId: String,
                          username: String) -> Bool
    {
        let newestTransaction = SKPaymentQueue.default().transactions.filter {
            $0.payment.productIdentifier == productId
                && $0.payment.applicationUsername == self.hash(username: username)
            }.reduce(nil) { (previous, next) -> SKPaymentTransaction? in
                guard let previous = previous else { return next }
                return previous.transactionDate < next.transactionDate ? next : previous
        }
        guard let state = newestTransaction?.transactionState else {
            return true
        }
        return [SKPaymentTransactionState.failed,
                SKPaymentTransactionState.purchased,
                SKPaymentTransactionState.restored].contains(state)
    }
    
    internal func purchaseProduct(withId id: String,
                                  username: String,
                                  successCompletion: ()->Void,
                                  errorCompletion: (Error)->Void,
                                  deferredCompletion: ()->Void)
    {
        guard let product = self.availableProducts.first(where: { $0.productIdentifier == id }) else {
            errorCompletion(Errors.unavailableProduct)
            return
        }
        let payment = SKMutablePayment(product: product)
        payment.quantity = 1
        payment.applicationUsername = self.hash(username: username)
        SKPaymentQueue.default().add(payment)
    }
    
    enum Errors: Error {
        case unavailableProduct
        case neverBeenPurchased
        case transactionFailed
        case recieptLost
        case haveTransactionOfAnotherUser
    }
}

extension StoreKitManager: SKProductsRequestDelegate {
    internal func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.availableProducts = response.products
    }
    
    private func hash(username: String) -> String {
        return username.sha256
    }
}

extension StoreKitManager: SKPaymentTransactionObserver {
    internal func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        DispatchQueue.global().async {
            transactions.forEach(self.process)
        }
    }
    
    private func process(_ transaction: SKPaymentTransaction) {
        switch transaction.transactionState {
        case .failed:
            self.errorCompletion?(transaction.error ?? Errors.transactionFailed)
            SKPaymentQueue.default().finishTransaction(transaction)
            
        case .purchased:
            guard let hashedUsername = transaction.payment.applicationUsername,
                let currentUsername = sharedUserDataService.username,
                hashedUsername == self.hash(username: currentUsername) else
            {
                self.errorCompletion?(Errors.haveTransactionOfAnotherUser)
                return
            }
            
            guard let reciept = try? Data(contentsOf: Bundle.main.appStoreReceiptURL!).base64EncodedString() else {
                self.errorCompletion?(Errors.recieptLost)
                SKPaymentQueue.default().finishTransaction(transaction)
                return
            }
            
            do {
                guard let plan = ServicePlan(storeKitProductId: transaction.payment.productIdentifier) else {
                    throw Errors.unavailableProduct
                }
                let serverUpdateApi = PostRecieptRequest(reciept: reciept, andActivatePlanWithId: plan.backendId)
                let serverUpdateRes = try await(serverUpdateApi.run())
                if let newSubscription = serverUpdateRes.newSubscription {
                    ServicePlanDataService.currentSubscription = newSubscription
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
                        self.errorCompletion?(error)
                    }
                    
                case 22120:
                    // There is already an active operation - need to try later, so do nothing now
                    break
                    
                case 00000:   // FIXME: number of error
                    // Already reported this receipt - can finish transaction
                    SKPaymentQueue.default().finishTransaction(transaction)
                    
                default:
                    break
                }
            }
            
            
        case .deferred:
            self.deferredCompletion?()
            
        case .restored:
            break // never happens in our flow
            
        case .purchasing:
            break // nothing to do here
        }
    }
}
