//
//  StoreKitManager.swift
//  ProtonMail - Created on 21/08/2018.
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
import AwaitKit

class StoreKitManager: NSObject {
    static var `default` = StoreKitManager()
    
    var user: UserManager? {
        return sharedServices.get(by: UsersManager.self).user(at: 0)
    }
    
    private override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: .reachabilityChanged, object: nil)
    }
    private lazy var isOffline: Bool = {
        return sharedInternetReachability.currentReachabilityStatus() == .NotReachable
    }()
    private var productIds = Set([ServicePlan.plus.storeKitProductId!])
    private var availableProducts: [SKProduct] = []
    private var request: SKProductsRequest!
    private var transactionsQueue: OperationQueue = {
       let queue = OperationQueue()
        queue.qualityOfService = QualityOfService.userInteractive
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    internal var refreshHandler: (()->Void)?
    private var successCompletion: (()->Void)?
    private var deferredCompletion: (()->Void)?
    private lazy var errorCompletion: (Error)->Void = { error in
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            let alert = UIAlertController(title: LocalString._error_occured, message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(.init(title: LocalString._general_ok_action, style: .cancel, handler: nil))
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    private lazy var confirmUserValidationBypass: (Error, @escaping ()->Void)->Void = { error, completion in
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            guard let currentUsername = self.user?.defaultEmail else {
                self.errorCompletion(Errors.noActiveUsernameInUserDataService)
                return
            }

            let message = """
            \(error.localizedDescription)
            \(LocalString._do_you_want_to_bypass_validation)\(currentUsername)?
            """
            let alert = UIAlertController(title: LocalString._warning, message: message, preferredStyle: .alert)
            alert.addAction(.init(title: LocalString._yes_bypass_validation + currentUsername,
                                  style: .destructive,
                                  handler: { _ in completion()} ))
            alert.addAction(.init(title: LocalString._no_dont_bypass_validation, style: .cancel, handler: nil))
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
        return (!self.hasUnfinishedPurchase()) && (self.applicationUsername() != nil)
    }
    
    internal func hasUnfinishedPurchase() -> Bool {
        return !SKPaymentQueue.default().transactions.filter { $0.transactionState != .failed }.isEmpty
    }
    
    internal func purchaseProduct(withId id: String,
                                  successCompletion: @escaping ()->Void,
                                  errorCompletion: @escaping (Error)->Void,
                                  deferredCompletion: @escaping ()->Void)
    {
        guard let username = self.applicationUsername() else {
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
    
    @objc internal func reachabilityChanged(_ note : Notification) {
        guard let current = note.object as? Reachability else {
            return
        }
        switch current.currentReachabilityStatus() {
        case .ReachableViaWiFi where self.isOffline,
             .ReachableViaWWAN where self.isOffline:
            self.processAllTransactions()
            self.isOffline = false
            
        case .NotReachable:
            self.isOffline = true
            
        default: break
        }
    }
}

extension StoreKitManager {
    enum Errors: LocalizedError {
        case unavailableProduct
        case receiptLost
        case haveTransactionOfAnotherUser
        case alreadyPurchasedPlanDoesNotMatchBackend
        case sandboxReceipt
        case noHashedUsernameArrivedInTransaction
        case noActiveUsernameInUserDataService
        case transactionFailedByUnknownReason
        case noNewSubscriptionInSuccessfullResponse
        case appIsLocked
        case pleaseSignIn
        
        var errorDescription: String? {
            switch self {
            case .unavailableProduct: return LocalString._unavailable_product
            case .receiptLost: return LocalString._reciept_lost
            case .haveTransactionOfAnotherUser: return LocalString._another_user_transaction
            case .alreadyPurchasedPlanDoesNotMatchBackend: return LocalString._backend_mismatch
            case .sandboxReceipt: return LocalString._sandbox_receipt
            case .noHashedUsernameArrivedInTransaction: return LocalString._no_hashed_username_arrived_in_transaction
            case .noActiveUsernameInUserDataService: return LocalString._no_active_username_in_user_data_service
            case .transactionFailedByUnknownReason: return LocalString._transaction_failed_by_unknown_reason
            case .noNewSubscriptionInSuccessfullResponse: return LocalString._no_new_subscription_in_response
            case .appIsLocked: return LocalString._unlock_to_proceed_with_iap
            case .pleaseSignIn: return LocalString._please_sign_in_iap
            }
        }
    }
}

extension StoreKitManager: SKProductsRequestDelegate {
    internal func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.availableProducts = response.products
    }
    
    private func hash(username: String) -> String {
        return username.sha256
    }
    
    private func applicationUsername() -> String? {
        guard let username = sharedServices.get(by: UsersManager.self).user(at: 0)?.userInfo.userId, !username.isEmpty else {
            return nil
        }
        return username
    }
    
    // this method attempts to match pre-1.11.1 hash which was calculated from case-insensitive username with optional "@protonmail.com" suffix for as much users as possible. Others should contact CS
    private func hashLegacy(username: String, mayMatch hash: String) -> Bool {
        if hash == username.sha256 ||
            hash == username.lowercased().sha256 ||
            hash == username.uppercased().sha256 ||
            hash == (username + "@protonmail.com").sha256 ||
            hash == (username + "@protonmail.ch").sha256 ||
            hash == (username + "@ProtonMail.ch").sha256 ||
            hash == (username + "@ProtonMail.ch").sha256 ||
            hash == (username + "@pm.me").sha256 ||
            hash == (username + "@PM.me").sha256 ||
            hash == (username + "@PM.ME").sha256
        {
            return true
        }
        
        var capitalizedUsername = username
        let firstLetter = capitalizedUsername.removeFirst()
        capitalizedUsername = String(firstLetter).uppercased() + capitalizedUsername
        
        if hash == capitalizedUsername.sha256 ||
            hash == (capitalizedUsername + "@protonmail.com").sha256 ||
            hash == (capitalizedUsername + "@protonmail.ch").sha256 ||
            hash == (capitalizedUsername + "@ProtonMail.ch").sha256 ||
            hash == (capitalizedUsername + "@ProtonMail.ch").sha256 ||
            hash == (capitalizedUsername + "@PM.ME").sha256 ||
            hash == (capitalizedUsername + "@PM.me").sha256 ||
            hash == (capitalizedUsername + "@pm.me").sha256
        {
            return true
        }
        
        return false
    }
}

extension StoreKitManager: SKPaymentTransactionObserver {
    // this will be called right after the purchase and after relaunch
    internal func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        self.processAllTransactions()
    }
    
    // this will be called after relogin and from the method above
    internal func processAllTransactions() {
        self.transactionsQueue.cancelAllOperations()
        SKPaymentQueue.default().transactions.forEach { transaction in
            self.transactionsQueue.addOperation { self.process(transaction) }
        }
    }
    
    private func process(_ transaction: SKPaymentTransaction, shouldVerifyPurchaseWasForSameAccount shouldVerify: Bool = true) {
        switch transaction.transactionState {
        case .failed:
            self.proceed(withFailed: transaction)
            
        case .purchased:
            do {
                guard sharedServices.get(by: UsersManager.self).hasUsers() else {
                    throw Errors.pleaseSignIn
                }
                guard UnlockManager.shared.isUnlocked() else {
                    throw Errors.appIsLocked
                }
                try self.proceed(withPurchased: transaction, shouldVerifyPurchaseWasForSameAccount: shouldVerify)
                
            } catch Errors.noHashedUsernameArrivedInTransaction { // storekit bug
                self.confirmUserValidationBypass(Errors.noHashedUsernameArrivedInTransaction) {
                    self.transactionsQueue.addOperation { self.process(transaction, shouldVerifyPurchaseWasForSameAccount: false) }
                }
                
            } catch Errors.haveTransactionOfAnotherUser { // user login error
                self.confirmUserValidationBypass(Errors.haveTransactionOfAnotherUser) {
                    self.transactionsQueue.addOperation { self.process(transaction, shouldVerifyPurchaseWasForSameAccount: false) }
                }
            } catch Errors.sandboxReceipt {  // receipt error
                self.errorCompletion(Errors.sandboxReceipt)
                SKPaymentQueue.default().finishTransaction(transaction)
                
            } catch Errors.receiptLost { // receipt error
                self.errorCompletion(Errors.receiptLost)
                SKPaymentQueue.default().finishTransaction(transaction)

            } catch Errors.noNewSubscriptionInSuccessfullResponse { // error on BE
                self.errorCompletion(Errors.noNewSubscriptionInSuccessfullResponse)
                SKPaymentQueue.default().finishTransaction(transaction)
            } catch let error { // other errors
                self.errorCompletion(error)
            }
            
        case .deferred, .purchasing:
            self.deferredCompletion?()
        case .restored:
            break // never happens in our flow
        }
    }
    
    private func proceed(withFailed transaction: SKPaymentTransaction) {
        SKPaymentQueue.default().finishTransaction(transaction)
        let error = transaction.error as NSError?
        switch error {
        case .some(SKError.paymentCancelled):
            self.refreshHandler?()
        case .some(let error):
            self.errorCompletion(error)
            self.refreshHandler?()
        case .none:
            self.errorCompletion(Errors.transactionFailedByUnknownReason)
        }
    }
    
    private func proceed(withPurchased transaction: SKPaymentTransaction,
                                      shouldVerifyPurchaseWasForSameAccount: Bool = true) throws
    {
        if shouldVerifyPurchaseWasForSameAccount {
            try self.verifyCurrentCredentialsMatch(usernameFromTransaction: transaction.payment.applicationUsername)
        }
        let receipt = try self.readReceipt()
        let planId = try servicePlan(for: transaction.payment.productIdentifier)
        guard let user = sharedServices.get(by: UsersManager.self).firstUser else {
            throw Errors.noActiveUsernameInUserDataService
        }
        
        do {  // payments/subscription
            let serverUpdateApi = PostRecieptRequest(api: user.apiService, reciept: receipt, andActivatePlanWithId: planId)
            let serverUpdateRes = try await(serverUpdateApi.run())
            if let newSubscription = serverUpdateRes.newSubscription {
                user.sevicePlanService.currentSubscription = newSubscription
                self.successCompletion?()
                SKPaymentQueue.default().finishTransaction(transaction)
            } else {
                throw Errors.noNewSubscriptionInSuccessfullResponse
            }
            
        } catch let error as NSError where error.code == 22101 {
            // Amount mismatch - try report only credits without activating the plan
            do {  // payments/credits
                let serverUpdateApi = PostCreditRequest<PostCreditResponse>(api: user.apiService, reciept: receipt)
                let _ = try await(serverUpdateApi.run())
                SKPaymentQueue.default().finishTransaction(transaction)
                
                _ = user.userService.fetchUserInfo().done(on: .main) { _ in
                    user.sevicePlanService.currentSubscription = user.sevicePlanService.currentSubscription
                }
                
                self.successCompletion?()
                
            } catch let error as NSError where error.code == 22916 {
                // Apple payment already registered
                SKPaymentQueue.default().finishTransaction(transaction)
            } catch let error {
                self.errorCompletion(error)
            }
            
        } catch let error as NSError where error.code == 22914 {
            // Sandbox receipt sent to prod BE
            SKPaymentQueue.default().finishTransaction(transaction)
            self.errorCompletion(error)
                
        } catch let error as NSError where error.code == 22916 {
            // Apple payment already registered
            SKPaymentQueue.default().finishTransaction(transaction)
                
        } catch let error {
            throw error // local errors
        }
    }
}

extension StoreKitManager {
    private func verifyCurrentCredentialsMatch(usernameFromTransaction applicationUsername: String?) throws {
        guard let currentUsername = self.applicationUsername() else {
            throw Errors.noActiveUsernameInUserDataService
        }
        guard let hashedUsername = applicationUsername else {
            throw Errors.noHashedUsernameArrivedInTransaction
        }
        guard hashedUsername == self.hash(username: currentUsername) ||
            self.hashLegacy(username: self.user?.defaultEmail.components(separatedBy: "@").first ?? "", mayMatch: hashedUsername) else
        {
            throw Errors.haveTransactionOfAnotherUser
        }
    }
    
    func readReceipt() throws -> String {
        guard let receiptUrl = Bundle.main.appStoreReceiptURL,
            !receiptUrl.lastPathComponent.contains("sandbox") else
        {
            throw Errors.sandboxReceipt
        }
        PMLog.D(receiptUrl.path) // make use of this thing so maybe compiler will not screw it up while optimising
        guard let receipt = try? Data(contentsOf: receiptUrl).base64EncodedString() else {
            throw Errors.receiptLost
        }
        
        return receipt
    }
    
    func servicePlan(for productId: String) throws -> String {
        guard let servicePlanService = sharedServices.get(by: UsersManager.self).firstUser?.sevicePlanService else {
            throw Errors.noActiveUsernameInUserDataService
        }
        guard let plan = ServicePlan(storeKitProductId: productId),
            let details = servicePlanService.detailsOfServicePlan(named: plan.rawValue),
            let planId = details.iD else
        {
            throw Errors.alreadyPurchasedPlanDoesNotMatchBackend
        }
        return planId
    }
}
