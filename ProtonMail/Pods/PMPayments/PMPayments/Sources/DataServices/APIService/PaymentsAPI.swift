//
//  PaymentsAPI.swift
//  PMPayments - Created on 29/08/2018.
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
import AwaitKit
import PMAuthentication

class BaseApiRequest<T: ApiResponse>: ApiRequestNew<T> {
    override func method() -> HTTPMethod {
        return .get
    }

    override func apiVersion() -> Int {
        return 3
    }

    override func path() -> String {
        return "/payments"
    }
}

let decodeError = NSError(domain: "Payment decode error", code: 0, userInfo: nil)

protocol PaymentsApiProtocol {
    func statusRequest(api: APIService) -> StatusRequest
    func methodsRequest(api: APIService) -> MethodsRequest
    func buySubscriptionRequest(api: APIService, planId: String, amount: Int, paymentAction: PaymentAction) throws -> SubscriptionRequest?
    func getSubscriptionRequest(api: APIService) -> GetSubscriptionRequest
    func appleRequest(api: APIService, currency: String, country: String) -> AppleRequest
    func defaultPlanRequest(api: APIService) -> DefaultPlanRequest
    func plansRequest(api: APIService) -> PlansRequest
    func creditRequest(api: APIService, amount: Int, paymentAction: PaymentAction) -> CreditRequest<CreditResponse>
    func tokenRequest(api: APIService, amount: Int, receipt: String) -> TokenRequest
    func tokenStatusRequest(api: APIService, token: PaymentToken) -> TokenStatusRequest
    func validateSubscriptionRequest(api: APIService, planId: String) -> ValidateSubscriptionRequest
    func getUser(api: APIService, completion: @escaping (Result<User, Error>) -> Void)
}

class PaymentsApiImplementation: PaymentsApiProtocol {
    func statusRequest(api: APIService) -> StatusRequest {
        return StatusRequest(api: api)
    }

    func methodsRequest(api: APIService) -> MethodsRequest {
        return MethodsRequest(api: api)
    }

    func buySubscriptionRequest(api: APIService, planId: String, amount: Int, paymentAction: PaymentAction) throws -> SubscriptionRequest? {
        var validateSubscriptionProcessing = true
        do {
            // validate subscription to get amountDue
            let validateReq = validateSubscriptionRequest(api: api, planId: planId)
            let res = try await(validateReq.run())
            validateSubscriptionProcessing = false
            guard let validateSubscription = res.validateSubscription else { throw(decodeError) }
            if validateSubscription.amountDue == amount {
                // if amountDue is equal to amount, request subscription
                return SubscriptionRequest(api: api, planId: planId, amount: validateSubscription.amountDue, paymentAction: paymentAction)
            } else {
                // if amountDue is not equal to amount, request credit for a full amount
                let creditReq = creditRequest(api: api, amount: amount, paymentAction: paymentAction)
                _ = try await(creditReq.run())
                // then request subscription for amountDue = 0
                return SubscriptionRequest(api: api, planId: planId, amount: 0, paymentAction: paymentAction)
            }
        } catch {
            if validateSubscriptionProcessing {
                return nil
            } else {
                throw error
            }
        }
    }

    func getSubscriptionRequest(api: APIService) -> GetSubscriptionRequest {
        return GetSubscriptionRequest(api: api)
    }

    func appleRequest(api: APIService, currency: String, country: String) -> AppleRequest {
        return AppleRequest(api: api, currency: currency, country: country)
    }

    func defaultPlanRequest(api: APIService) -> DefaultPlanRequest {
        return DefaultPlanRequest(api: api)
    }

    func plansRequest(api: APIService) -> PlansRequest {
        return PlansRequest(api: api)
    }

    func creditRequest(api: APIService, amount: Int, paymentAction: PaymentAction) -> CreditRequest<CreditResponse> {
        return CreditRequest<CreditResponse>(api: api, amount: amount, paymentAction: paymentAction)
    }

    func tokenRequest(api: APIService, amount: Int, receipt: String) -> TokenRequest {
        return TokenRequest(api: api, amount: amount, receipt: receipt)
    }

    func tokenStatusRequest(api: APIService, token: PaymentToken) -> TokenStatusRequest {
        return TokenStatusRequest(api: api, token: token)
    }

    func validateSubscriptionRequest(api: APIService, planId: String) -> ValidateSubscriptionRequest {
        return ValidateSubscriptionRequest(api: api, planId: planId)
    }

    func getUser(api: APIService, completion: @escaping (Result<User, Error>) -> Void) {
        let authenticator = Authenticator(api: api)
        authenticator.getUserInfo { result in
            switch result {
            case .success(let user):
                return completion(.success(user))
            case .failure(let error):
                return completion(.failure(error))
            }
        }
    }
}

extension ApiResponse {
    private struct Key: CodingKey {
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

    func decapitalizeFirstLetter(_ path: [CodingKey]) -> CodingKey {
        let original: String = path.last!.stringValue
        let uncapitalized = original.prefix(1).lowercased() + original.dropFirst()
        return Key(stringValue: uncapitalized) ?? path.last!
    }
}

enum RequestErrors: LocalizedError, Equatable {
    case methodsDecode
    case subscriptionDecode
    case defaultPlanDecode
    case plansDecode
    case creditDecode
    case tokenDecode
    case tokenStatusDecode
    case validateSubscriptionDecode
}
