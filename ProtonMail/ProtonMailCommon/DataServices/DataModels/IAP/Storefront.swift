//
//  Storefront.swift
//  ProtonMail - Created on 18/12/2018.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

import Foundation

class Storefront: NSObject {
    var plan: ServicePlan
    var details: ServicePlanDetails?
    var others: [ServicePlan]
    var title: String
    var canBuyMoreCredits: Bool
    @objc dynamic var subscription: Subscription?
    @objc dynamic var isProductPurchasable: Bool
    
    private var subscriptionObserver: NSKeyValueObservation!
    
    init(plan: ServicePlan) {
        self.plan = plan
        self.details = plan.fetchDetails()!
        self.others = []
        self.title = plan.subheader.0
        
        self.isProductPurchasable = ( plan == .plus
                                        && ServicePlanDataService.shared.currentSubscription?.plan == .free
                                        && StoreKitManager.default.readyToPurchaseProduct() )
        self.canBuyMoreCredits = false
        super.init()
    }
    
    init(subscription: Subscription) {
        self.subscription = subscription
        self.plan = subscription.plan
        self.details = subscription.details
        self.others = Array<ServicePlan>(arrayLiteral: .free, .plus).filter({ $0 != subscription.plan })
        
        self.title = LocalString._menu_service_plan_title
        self.isProductPurchasable = false
        
        // only plus, payed via apple, expired
        self.canBuyMoreCredits = ( subscription.plan == .plus
                                    && !subscription.hadOnlinePayments
                                    && subscription.end?.compare(Date()) == .orderedAscending )
        super.init()

        self.subscriptionObserver = ServicePlanDataService.shared.observe(\.currentSubscription) { [unowned self] shared, change in
            guard let newSubscription = shared.currentSubscription else { return }
            self.plan = newSubscription.plan
            self.details = newSubscription.details
            self.others = Array<ServicePlan>(arrayLiteral: .free, .plus).filter({ $0 != newSubscription.plan })
            self.subscription = shared.currentSubscription
        }
    }
    
    init(creditsFor subscription: Subscription) {
        self.subscription = subscription
        self.plan = subscription.plan
        self.title = LocalString._buy_more_credits
        self.others = []
        
        self.isProductPurchasable = ( subscription.plan == .plus
                                        && !subscription.hadOnlinePayments
                                        && subscription.end?.compare(Date()) == .orderedAscending
                                        && StoreKitManager.default.readyToPurchaseProduct() )
        self.canBuyMoreCredits = false
        super.init()
    }
    
    func buyProduct() {
        guard let productId = self.plan.storeKitProductId else { return }
        self.isProductPurchasable = false
        
        let successCompletion: ()->Void = {
            // TODO: nice animation
        }
        let errorCompletion: (Error)->Void = { [weak self] error in
            DispatchQueue.main.async {
                self?.isProductPurchasable = true
                
                let alert = UIAlertController(title: LocalString._error_occured, message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(.init(title: LocalString._general_ok_action, style: .cancel, handler: nil))
                UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }
        let deferredCompletion: ()->Void = {
            // TODO: nothing special
        }
        let canceledCompletion: ()->Void = { [weak self] in
            DispatchQueue.main.async {
                self?.isProductPurchasable = StoreKitManager.default.readyToPurchaseProduct()
            }
        }
        StoreKitManager.default.refreshHandler = canceledCompletion
        StoreKitManager.default.purchaseProduct(withId: productId, successCompletion: successCompletion, errorCompletion: errorCompletion, deferredCompletion: deferredCompletion)
    }
}

