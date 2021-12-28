//
//  PaymentsAPI.swift
//  ProtonCore-Payments - Created on 29/08/2018.
//
//  Copyright (c) 2019 Proton Technologies AG
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

import Foundation
import AwaitKit
import PromiseKit
import ProtonCore_Authentication
import ProtonCore_Log
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_Services

class BaseApiRequest<T: Response>: Request {

    let api: APIService

    init(api: APIService) {
        self.api = api
    }

    func run() -> Promise<T> where T: Response {
        api.run(route: self)
    }

    var path: String { "/payments" }

    var method: HTTPMethod { .get }

    var header: [String: Any] { [:] }

    var parameters: [String: Any]? { nil }

    var isAuth: Bool { true }

    var authCredential: AuthCredential? { nil }

    var autoRetry: Bool { true }
}

let decodeError = NSError(domain: "Payment decode error", code: 0, userInfo: nil)

protocol PaymentsApiProtocol {
    func statusRequest(api: APIService) -> StatusRequest
    func buySubscriptionRequest(
        api: APIService, planId: String, amount: Int, amountDue: Int, paymentAction: PaymentAction
    ) throws -> SubscriptionRequest
    func buySubscriptionForZeroRequest(api: APIService, planId: String) -> SubscriptionRequest
    func getSubscriptionRequest(api: APIService) -> GetSubscriptionRequest
    func organizationsRequest(api: APIService) -> OrganizationsRequest
    func defaultPlanRequest(api: APIService) -> DefaultPlanRequest
    func plansRequest(api: APIService) -> PlansRequest
    func creditRequest(api: APIService, amount: Int, paymentAction: PaymentAction) -> CreditRequest<CreditResponse>
    func tokenRequest(api: APIService, amount: Int, receipt: String) -> TokenRequest
    func tokenStatusRequest(api: APIService, token: PaymentToken) -> TokenStatusRequest
    func validateSubscriptionRequest(api: APIService, protonPlanName: String, isAuthenticated: Bool) -> ValidateSubscriptionRequest
    func getUser(api: APIService, completion: @escaping (Swift.Result<User, Error>) -> Void)
}

class PaymentsApiImplementation: PaymentsApiProtocol {

    func statusRequest(api: APIService) -> StatusRequest {
        StatusRequest(api: api)
    }

    func buySubscriptionRequest(api: APIService, planId: String, amount: Int, amountDue: Int, paymentAction: PaymentAction) throws -> SubscriptionRequest {
            if amountDue == amount {
                // if amountDue is equal to amount, request subscription
                return SubscriptionRequest(api: api, planId: planId, amount: amount, paymentAction: paymentAction)
            } else {
                // if amountDue is not equal to amount, request credit for a full amount
                let creditReq = creditRequest(api: api, amount: amount, paymentAction: paymentAction)
                _ = try AwaitKit.await(creditReq.run())
                // then request subscription for amountDue = 0
                return SubscriptionRequest(api: api, planId: planId, amount: 0, paymentAction: paymentAction)
            }
    }

    func buySubscriptionForZeroRequest(api: APIService, planId: String) -> SubscriptionRequest {
        SubscriptionRequest(api: api, planId: planId)
    }

    func getSubscriptionRequest(api: APIService) -> GetSubscriptionRequest {
        GetSubscriptionRequest(api: api)
    }

    func organizationsRequest(api: APIService) -> OrganizationsRequest {
        OrganizationsRequest(api: api)
    }

    func defaultPlanRequest(api: APIService) -> DefaultPlanRequest {
        DefaultPlanRequest(api: api)
    }

    func plansRequest(api: APIService) -> PlansRequest {
        PlansRequest(api: api)
    }

    func creditRequest(api: APIService, amount: Int, paymentAction: PaymentAction) -> CreditRequest<CreditResponse> {
        CreditRequest<CreditResponse>(api: api, amount: amount, paymentAction: paymentAction)
    }

    func tokenRequest(api: APIService, amount: Int, receipt: String) -> TokenRequest {
        TokenRequest(api: api, amount: amount, receipt: receipt)
    }

    func tokenStatusRequest(api: APIService, token: PaymentToken) -> TokenStatusRequest {
        TokenStatusRequest(api: api, token: token)
    }

    func validateSubscriptionRequest(api: APIService, protonPlanName: String, isAuthenticated: Bool) -> ValidateSubscriptionRequest {
        ValidateSubscriptionRequest(api: api,
                                    protonPlanName: protonPlanName,
                                    isAuthenticated: isAuthenticated)
    }

    func getUser(api: APIService, completion: @escaping (Swift.Result<User, Error>) -> Void) {
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

extension Response {
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

    func decodeResponse<T: Decodable>(_ response: Any, to _: T.Type) -> (Bool, T?) {
        do {
            let data = try JSONSerialization.data(withJSONObject: response, options: [])
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .custom(decapitalizeFirstLetter)
            let object = try decoder.decode(T.self, from: data)
            return (true, object)
        } catch let decodingError {
            error = RequestErrors.defaultPlanDecode.toResponseError(updating: error)
            PMLog.debug("Failed to parse \(T.self): \(decodingError)")
            return (false, nil)
        }
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

extension RequestErrors {
    func toResponseError(updating error: ResponseError?) -> ResponseError {
        error?.withUpdated(underlyingError: self)
            ?? ResponseError(httpCode: nil, responseCode: nil, userFacingMessage: localizedDescription, underlyingError: self as NSError)
    }
}

extension ResponseError {
    var toRequestErrors: RequestErrors? {
        let requestError = underlyingError as? RequestErrors
        return requestError
    }
}
