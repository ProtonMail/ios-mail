//
//  PaymentsAPI.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 29/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

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

final class GetPaymentMethodsRequest: ApiRequestNew<GetPaymentMethodsResponse> {
    override func method() -> APIService.HTTPMethod {
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
    override func method() -> APIService.HTTPMethod {
        return .get
    }
    
    override func path() -> String {
        return PaymentsAPI.path + "/subscription"
    }
    
    override func apiVersion() -> Int {
        return PaymentsAPI.v_get_subscription
    }
}

final class GetSubscriptionResponse: ApiResponse {
    var subscription: Subscription?
    
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
        self.subscription = Subscription(start: start, end: end, planDetails: plans, paymentMethods: nil)
        
        return true
    }
}

final class GetDefaultServicePlanRequest: ApiRequestNew<GetDefaultServicePlanResponse> {
    override func method() -> APIService.HTTPMethod {
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
    internal var servicePlan: ServicePlanDetails?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        PMLog.D(response.json(prettyPrinted: true))
        do {
            let data = try JSONSerialization.data(withJSONObject: response["Plans"] as Any, options: [])
            let decoder = JSONDecoder()
            // this strategy is decapitalizing first letter of response's labels to get appropriate name of the ServicePlanDetails object
            decoder.keyDecodingStrategy = .custom(self.decapitalizeFirstLetter)
            self.servicePlan = try decoder.decode(ServicePlanDetails.self, from: data)
            return true
        } catch let error {
            PMLog.D("Failed to parse ServicePlans: \(error.localizedDescription)")
            return false
        }
    }
}

final class GetServicePlansRequest: ApiRequestNew<GetServicePlansResponse> {
    override func method() -> APIService.HTTPMethod {
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

final class PostCreditRequest: ApiRequestNew<PostCreditResponse> {
    private let reciept: String
    
    init(reciept: String) {
        self.reciept = reciept
        super.init()
    }
    
    override func method() -> APIService.HTTPMethod {
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
    var newSubscription: Subscription?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        PMLog.D(response.json(prettyPrinted: true))
        guard let code = response["Code"] as? Int, code == 1000 else {
            return false
        }
        return true
    }
}

final class PostRecieptRequest: ApiRequestNew<PostRecieptResponse> {
    private let reciept: String
    private let planId: String
    
    init(reciept: String,
         andActivatePlanWithId planId: String)
    {
        self.reciept = reciept
        self.planId = planId
        super.init()
    }
    
    override func method() -> APIService.HTTPMethod {
        return .post
    }
    
    override func path() -> String {
        return PaymentsAPI.path + "/subscription"
    }
    
    override func apiVersion() -> Int {
        return PaymentsAPI.v_post_subscription
    }
    
    override func toDictionary() -> [String : Any]? {
        var params = PostCreditRequest(reciept: self.reciept).toDictionary()
        params?["PlanIDs"] = [planId]
        params?["Cycle"] = 12
        return params
    }
}

final class PostRecieptResponse: ApiResponse {
    var newSubscription: Subscription?
    
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
