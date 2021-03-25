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
import PMCommon


//Payments API
//Doc: FIXME
struct PaymentsAPI {
    static let path : String = "/payments"
}

//TODO:: this need to remove because the networking already have this
extension Response {
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

//GetIAPStatusResponse
final class GetIAPStatusRequest: Request {
    
    var path: String {
        return PaymentsAPI.path + "/status"
    }
}

final class GetIAPStatusResponse: Response {
    var isAvailable: Bool?
        
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        PMLog.D(response.json(prettyPrinted: true))
        self.isAvailable = response["Apple"] as? Bool
        return true
    }
}

//GetPaymentMethodsResponse
final class GetPaymentMethodsRequest: Request {
    
    var path: String {
        return PaymentsAPI.path + "/methods"
    }
}

final class GetPaymentMethodsResponse: Response {
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

//GetSubscriptionResponse
final class GetSubscriptionRequest: Request {
    
    var path: String {
        return PaymentsAPI.path + "/subscription"
    }
}

//AppleTier
final class GetAppleTier : Request {
    var currency: String
    var country: String
    
    //TODO:: add tier later
    init(currency: String, country: String) {
        self.currency = currency
        self.country = country
    }
    
    var path: String {
        return PaymentsAPI.path + "/apple"
    }

    var parameters: [String : Any]? {
        return [
            "Country": self.country,
            "Currency" : self.currency,
            "Tier" : 54
        ]
    }
}

final class AppleTier : Response {
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


final class GetSubscriptionResponse: Response {
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

//GetDefaultServicePlanResponse
final class GetDefaultServicePlanRequest: Request {

    var path: String {
        return PaymentsAPI.path + "/plans/default"
    }
}

final class GetDefaultServicePlanResponse: Response {
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

//GetServicePlansResponse
final class GetServicePlansRequest: Request {
    
    var path: String {
        return PaymentsAPI.path + "/plans"
    }
    
    var parameters: [String : Any]? {
        return  ["Currency": "USD", "Cycle": 12]
    }
}

final class GetServicePlansResponse: Response {
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
class PostCreditRequest : Request {
    private let reciept: String
    
    init(reciept: String) {
        self.reciept = reciept
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    var path: String {
        return PaymentsAPI.path + "/credit"
    }
    
    var parameters: [String : Any]? {
        return [
            "Amount": 4800,
            "Currency": "USD",
            "Payment": ["Type": "apple",
                        "Details": [ "Receipt": self.reciept ]
            ]
        ]
    }
}

final class PostCreditResponse: Response {
    var newSubscription: ServicePlanSubscription?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        PMLog.D(response.json(prettyPrinted: true))
        guard let code = response["Code"] as? Int, code == 1000 else {
            return false
        }
        return true
    }
}
//PostRecieptResponse
final class PostRecieptRequest: PostCreditRequest {
    private let reciept: String
    private let planId: String
    
    init(reciept: String,
         andActivatePlanWithId planId: String)
    {
        self.reciept = reciept
        self.planId = planId
        super.init(reciept: self.reciept)
    }
    
    override var method: HTTPMethod {
        return .post
    }
    
    override var path: String {
        return PaymentsAPI.path + "/subscription"
    }
    
    override var parameters: [String : Any]? {
        var params = super.parameters
        params?["PlanIDs"] = [planId]
        params?["Cycle"] = 12
        return params
    }
}

final class PostRecieptResponse: Response {
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
