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
import ProtonCore_Authentication
import ProtonCore_Log
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_Services

struct ResponseWrapper<T: Response> {
    
    private let t: T
    
    init(_ t: T) {
        self.t = t
    }
    
    func throwIfError() throws -> T {
        guard let responseError = t.error else { return t }
        throw responseError
    }
}

// global variable because generic types don't support stored static properties
private let awaitQueue = DispatchQueue(label: "ch.protonmail.ios.protoncore.payments.await", attributes: .concurrent)
enum AwaitInternalError: Error {
    case shouldNeverHappen
    case synchronousCallPerformedFromTheMainThread
}

class BaseApiRequest<T: Response>: Request {

    let api: APIService

    init(api: APIService) {
        self.api = api
    }
    
    func awaitResponse(responseObject: T) throws -> T {
        
        guard Thread.isMainThread == false else {
            assertionFailure("This is a blocking network request, should never be called from main thread")
            throw AwaitInternalError.synchronousCallPerformedFromTheMainThread
        }
        
        var result: Swift.Result<T, Error> = .failure(AwaitInternalError.shouldNeverHappen)

        let semaphore = DispatchSemaphore(value: 0)
        
        awaitQueue.async {
            self.api.exec(route: self,
                          responseObject: responseObject,
                          callCompletionBlockUsing: .asyncExecutor(dispatchQueue: awaitQueue)) { (response: T) in
                
                if let responseError = response.error {
                    result = .failure(responseError)
                } else {
                    result = .success(response)
                }
                semaphore.signal()
            }
        }
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        return try result.get()
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
    func methodsRequest(api: APIService) -> MethodRequest
    func tokenRequest(api: APIService, amount: Int, receipt: String) -> TokenRequest
    func tokenStatusRequest(api: APIService, token: PaymentToken) -> TokenStatusRequest
    func validateSubscriptionRequest(api: APIService, protonPlanName: String, isAuthenticated: Bool) -> ValidateSubscriptionRequest
    func getUser(api: APIService) throws -> User
}

class PaymentsApiImplementation: PaymentsApiProtocol {

    func statusRequest(api: APIService) -> StatusRequest {
        StatusRequest(api: api)
    }

    func buySubscriptionRequest(api: APIService, planId: String, amount: Int, amountDue: Int, paymentAction: PaymentAction) throws -> SubscriptionRequest {
            guard Thread.isMainThread == false else {
                assertionFailure("This is a blocking network request, should never be called from main thread")
                throw AwaitInternalError.synchronousCallPerformedFromTheMainThread
            }
            if amountDue == amount {
                // if amountDue is equal to amount, request subscription
                return SubscriptionRequest(api: api, planId: planId, amount: amount, paymentAction: paymentAction)
            } else {
                // if amountDue is not equal to amount, request credit for a full amount
                let creditReq = creditRequest(api: api, amount: amount, paymentAction: paymentAction)
                _ = try creditReq.awaitResponse(responseObject: CreditResponse())
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
    
    func methodsRequest(api: APIService) -> MethodRequest {
        MethodRequest(api: api)
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

    func getUser(api: APIService) throws -> User {
        
        guard Thread.isMainThread == false else {
            assertionFailure("This is a blocking network request, should never be called from main thread")
            throw AwaitInternalError.synchronousCallPerformedFromTheMainThread
        }
        
        var result: Swift.Result<User, Error> = .failure(AwaitInternalError.shouldNeverHappen)

        let semaphore = DispatchSemaphore(value: 0)
        
        awaitQueue.async {
            let authenticator = Authenticator(api: api)
            authenticator.getUserInfo { callResult in
                switch callResult {
                case .success(let user):
                    result = .success(user)
                case .failure(let error):
                    result = .failure(error)
                }
                semaphore.signal()
            }
        }

        _ = semaphore.wait(timeout: .distantFuture)
        
        return try result.get()
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

    func decodeResponse<T: Decodable>(_ response: Any, to _: T.Type, errorToReturn: RequestErrors) -> (Bool, T?) {
        do {
            if case Optional<Void>.none = response {
                throw errorToReturn.toResponseError(updating: error)
            }
            let data = try JSONSerialization.data(withJSONObject: response, options: [])
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .custom(decapitalizeFirstLetter)
            let object = try decoder.decode(T.self, from: data)
            return (true, object)
        } catch let decodingError {
            error = errorToReturn.toResponseError(updating: error)
            PMLog.debug("Failed to parse \(T.self): \(decodingError)")
            return (false, nil)
        }
    }
}

enum RequestErrors: LocalizedError, Equatable {
    case methodsDecode
    case subscriptionDecode
    case organizationDecode
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
