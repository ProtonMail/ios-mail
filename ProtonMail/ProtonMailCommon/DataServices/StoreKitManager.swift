//
//  StoreKitManager.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 21/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import StoreKit

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
    
    internal func purchaseProduct(withId id: String, username: String) throws {
        guard let product = self.availableProducts.first(where: { $0.productIdentifier == id }) else {
            throw Errors.unavailableProduct
        }
        let payment = SKMutablePayment(product: product)
        payment.quantity = 1
        payment.applicationUsername = self.hash(username: username)
        SKPaymentQueue.default().add(payment)
    }
    
    enum Errors: Error {
        case unavailableProduct
        case neverBeenPurchased
    }
}

extension StoreKitManager: SKProductsRequestDelegate {
    internal func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.availableProducts = response.products
    }
    
    private func hash(username: String) -> String {
        return username // FIXME: one-way hash function
    }
}

extension StoreKitManager: SKPaymentTransactionObserver {
    internal func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach(self.process)
    }
    
    private func process(_ transaction: SKPaymentTransaction) {
        switch transaction.transactionState {
        case .failed:
            break // alert, pass completion
        case .purchased:
            print(transaction)
            print(try! Data(contentsOf: Bundle.main.appStoreReceiptURL!).base64EncodedString())
            break // call server, pass completion
        case .deferred, .purchasing:
            break // show spinner
        case .restored:
            break // never
        }
    }
}
