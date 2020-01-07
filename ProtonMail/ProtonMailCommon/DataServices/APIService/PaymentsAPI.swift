//
//  PaymentsAPI.swift
//  ProtonMail - Created on 29/08/2018.
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

extension ApiResponse {
    fileprivate struct Key : CodingKey {
        var stringValue: String
        var intValue: Int?
        
        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }
        
        init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
    }
    
    fileprivate func decapitalizeFirstLetter(_ path: [CodingKey]) -> CodingKey {
        let original: String = path.last!.stringValue
        let uncapitalized = original.prefix(1).lowercased() + original.dropFirst()
        return Key(stringValue: uncapitalized) ?? path.last!
    }
}

final class GetIAPStatusRequest: ApiRequestNew<GetIAPStatusResponse> {
    override func method() -> HTTPMethod {
        return .get
    }
    
    override func path() -> String {
        return PaymentsAPI.path + "/status"
    }
    
    override func apiVersion() -> Int {
        return PaymentsAPI.v_get_status
    }
}

final class GetIAPStatusResponse: ApiResponse {
    var isAvailable: Bool?
        
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        PMLog.D(response.json(prettyPrinted: true))
        self.isAvailable = response["Apple"] as? Bool
        return true
    }
}

final class GetPaymentMethodsRequest: ApiRequestNew<GetPaymentMethodsResponse> {
    override func method() -> HTTPMethod {
        return .get
    }
    
    override func path() -> String {
        return PaymentsAPI.path + "/methods"
    }
    
    override func apiVersion() -> Int {
        return PaymentsAPI.v_get_payment_methods
    }
}

final class GetPaymentMethodsResponse: ApiResponse {
    var methods: [PaymentMethod]?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        PMLog.D(response.json(prettyPrinted: true))
        do {
            let data = try JSONSerialization.data(withJSONObject: response["PaymentMethods"] as Any, options: [])
            let decoder = JSONDecoder()
            // this strategy is decapitalizing first letter of response's labels to get appropriate name of the ServicePlanDetails object
            decoder.keyDecodingStrategy = .custom(self.decapitalizeFirstLetter)
            self.methods = try decoder.decode(Array<PaymentMethod>.self, from: data)
            return true
        } catch let error {
            PMLog.D("Failed to parse PaymentMethods: \(error.localizedDescription)")
            return false
        }
    }
}

final class GetSubscriptionRequest: ApiRequestNew<GetSubscriptionResponse> {
    override func method() -> HTTPMethod {
        return .get
    }
    
    override func path() -> String {
        return PaymentsAPI.path + "/subscription"
    }
    
    override func apiVersion() -> Int {
        return PaymentsAPI.v_get_subscription
    }
}

final class GetAppleTier : ApiRequestNew<AppleTier> {
    var currency: String
    var country: String
    //TODO:: add tier later
    init(api: API, currency: String, country: String) {
        self.currency = currency
        self.country = country
        super.init(api: api)
    }
    override func path() -> String {
        return PaymentsAPI.path + "/apple"
    }
    
    override func apiVersion() -> Int {
        return PaymentsAPI.v_get_apple_tier
    }
    
    override func toDictionary() -> [String : Any]? {
        return [
            "Country": self.country,
            "Currency" : self.currency,
            "Tier" : 54
        ]
    }
}

final class AppleTier : ApiResponse {
    internal var _proceed : Decimal?
    var price : String?
    
    var proceed : Decimal {
        get {
            return self._proceed ?? Decimal(0)
        }
    }
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        PMLog.D(response.json(prettyPrinted: true))
        if let proceedPrice = response["Proceeds"] as? String {
            self._proceed = Decimal(string: proceedPrice)
        } else if let proceeds = response["Proceeds"] as? [String : Any],
            //the resposne when not pass the tier
            let proceedPrice = proceeds["Tier 54"] as? String {
            self._proceed = Decimal(string: proceedPrice)
        }
        
        return true
    }
}


final class GetSubscriptionResponse: ApiResponse {
    var subscription: ServicePlanSubscription?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        PMLog.D(response.json(prettyPrinted: true))
        guard let response = response["Subscription"] as? [String : Any],
            let startRaw = response["PeriodStart"] as? Int,
            let endRaw = response["PeriodEnd"] as? Int else
        {
            return false
        }
        
        let plansParser = GetServicePlansResponse()
        guard plansParser.ParseResponse(response) else {
            return false
        }
        
        let plans = plansParser.availableServicePlans
        let start = Date(timeIntervalSince1970: Double(startRaw))
        let end = Date(timeIntervalSince1970: Double(endRaw))
        self.subscription = ServicePlanSubscription(start: start, end: end, planDetails: plans, defaultPlanDetails: nil, paymentMethods: nil)
        
        return true
    }
}

final class GetDefaultServicePlanRequest: ApiRequestNew<GetDefaultServicePlanResponse> {
    override func method() -> HTTPMethod {
        return .get
    }
    
    override func path() -> String {
        return PaymentsAPI.path + "/plans/default"
    }
    
    override func apiVersion() -> Int {
        return PaymentsAPI.v_get_default_plan
    }
}

final class GetDefaultServicePlanResponse: ApiResponse {
    internal var servicePlans: [ServicePlanDetails]?
    
    var defaultMailPlan : ServicePlanDetails? {
        get {
            return self.servicePlans?.filter({ (details) -> Bool in
                return details.title.contains(check: "ProtonMail Free")
            }).first
        }
    }
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        PMLog.D(response.json(prettyPrinted: true))
        do {
            let data = try JSONSerialization.data(withJSONObject: response["Plans"] as Any, options: [])
            let decoder = JSONDecoder()
            // this strategy is decapitalizing first letter of response's labels to get appropriate name of the ServicePlanDetails object
            decoder.keyDecodingStrategy = .custom(self.decapitalizeFirstLetter)
            self.servicePlans = try decoder.decode(Array<ServicePlanDetails>.self, from: data)
            return true
        } catch let error {
            PMLog.D("Failed to parse ServicePlans: \(error.localizedDescription)")
            return false
        }
    }
}

final class GetServicePlansRequest: ApiRequestNew<GetServicePlansResponse> {
    override func method() -> HTTPMethod {
        return .get
    }
    
    override func path() -> String {
        return PaymentsAPI.path + "/plans"
    }
    
    override func apiVersion() -> Int {
        return PaymentsAPI.v_get_plans
    }
    
    override func toDictionary() -> [String : Any]? {
        return  ["Currency": "USD", "Cycle": 12]
    }
}

final class GetServicePlansResponse: ApiResponse {
    internal var availableServicePlans: [ServicePlanDetails]?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        PMLog.D(response.json(prettyPrinted: true))
        do {
            let data = try JSONSerialization.data(withJSONObject: response["Plans"] as Any, options: [])
            let decoder = JSONDecoder()
            // this strategy is decapitalizing first letter of response's labels to get appropriate name of the ServicePlanDetails object
            decoder.keyDecodingStrategy = .custom(self.decapitalizeFirstLetter)
            self.availableServicePlans = try decoder.decode(Array<ServicePlanDetails>.self, from: data)
            return true
        } catch let error {
            PMLog.D("Failed to parse ServicePlans: \(error.localizedDescription)")
            return false
        }
    }
}
//PostCreditResponse
class PostCreditRequest<T : ApiResponse>: ApiRequestNew<T> {
    private let reciept: String
    
    init(api: API, reciept: String) {
        self.reciept = reciept
        super.init(api: api)
    }
    
    override func method() -> HTTPMethod {
        return .post
    }
    
    override func path() -> String {
        return PaymentsAPI.path + "/credit"
    }
    
    override func apiVersion() -> Int {
        return PaymentsAPI.v_post_credit
    }
    
    override func toDictionary() -> [String : Any]? {
        return [
            "Amount": 4800,
            "Currency": "USD",
            "Payment": ["Type": "apple",
                        "Details": [ "Receipt": self.reciept ]
            ]
        ]
    }
}

final class PostCreditResponse: ApiResponse {
    var newSubscription: ServicePlanSubscription?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        PMLog.D(response.json(prettyPrinted: true))
        guard let code = response["Code"] as? Int, code == 1000 else {
            return false
        }
        return true
    }
}

final class PostRecieptRequest: PostCreditRequest<PostRecieptResponse> {
    private let reciept: String
    private let planId: String
    
    init(api: API,
         reciept: String,
         andActivatePlanWithId planId: String)
    {
        self.reciept = reciept
        self.planId = planId
        super.init(api:api, reciept: self.reciept)
    }
    
    override func method() -> HTTPMethod {
        return .post
    }
    
    override func path() -> String {
        return PaymentsAPI.path + "/subscription"
    }
    
    override func apiVersion() -> Int {
        return PaymentsAPI.v_post_subscription
    }
    
    override func toDictionary() -> [String : Any]? {
        var params = super.toDictionary()
        params?["PlanIDs"] = [planId]
        params?["Cycle"] = 12
        return params
    }
}

final class PostRecieptResponse: ApiResponse {
    var newSubscription: ServicePlanSubscription?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        PMLog.D(response.json(prettyPrinted: true))
        
        guard let code = response["Code"] as? Int, code == 1000 else {
            return false
        }
        
        let subscriptionParser = GetSubscriptionResponse()
        guard subscriptionParser.ParseResponse(response) else {
            return false
        }
        self.newSubscription = subscriptionParser.subscription
        
        return true
    }
}
