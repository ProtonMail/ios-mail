//
//  ProtonMailAPIService+HVFU.swift
//  ProtonCore-Services - Created on 5/22/20.
//
//  Copyright (c) 2022 Proton Technologies AG
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

// swiftlint:disable function_parameter_count

import Foundation
import ProtonCore_Doh
import ProtonCore_Log
import ProtonCore_Networking
import ProtonCore_Utilities

// MARK: - Handling human verification

extension PMAPIService {
    
    func humanVerificationHandler(method: HTTPMethod,
                                  path: String,
                                  parameters: Any?,
                                  headers: [String: Any]?,
                                  authenticated: Bool = true,
                                  authRetry: Bool = true,
                                  authRetryRemains: Int = 3,
                                  customAuthCredential: AuthCredential? = nil,
                                  nonDefaultTimeout: TimeInterval?,
                                  error: NSError,
                                  response: Any?,
                                  task: URLSessionDataTask?,
                                  responseDict: [String: Any],
                                  completion: CompletionBlock?) {
        
        let customAuthCredential = customAuthCredential.map(AuthCredential.init(copying:))
        
        // return completion if humanDelegate in not present
        guard self.humanDelegate != nil else {
            completion?(task, responseDict, error)
            return
        }
        
        // human verification required
        if self.isHumanVerifyUIPresented.transform({ $0 == true }) {
            // wait until ongoing human verification is finished
            DispatchQueue.global(qos: .default).async {
                self.hvDispatchGroup.wait()
                // recall request again
                self.request(method: method,
                             path: path,
                             parameters: parameters,
                             headers: headers,
                             authenticated: authenticated,
                             authRetryRemains: authRetryRemains - 1,
                             customAuthCredential: customAuthCredential,
                             nonDefaultTimeout: nonDefaultTimeout,
                             completion: completion)
            }
        } else {
            // human verification UI
            self.humanVerificationUIHandler(method: method,
                                            path: path,
                                            parameters: parameters,
                                            headers: headers,
                                            authenticated: authenticated,
                                            authRetry: authRetry,
                                            authRetryRemains: authRetryRemains,
                                            customAuthCredential: customAuthCredential,
                                            nonDefaultTimeout: nonDefaultTimeout,
                                            error: error,
                                            response: response,
                                            task: task,
                                            responseDict: responseDict,
                                            completion: completion)
        }
    }
    
    private func humanVerificationUIHandler(method: HTTPMethod,
                                            path: String,
                                            parameters: Any?,
                                            headers: [String: Any]?,
                                            authenticated: Bool = true,
                                            authRetry: Bool = true,
                                            authRetryRemains: Int = 3,
                                            customAuthCredential: AuthCredential? = nil,
                                            nonDefaultTimeout: TimeInterval?,
                                            error: NSError,
                                            response: Any?,
                                            task: URLSessionDataTask?,
                                            responseDict: [String: Any],
                                            completion: CompletionBlock?) {
        
        // get human verification methods
        let (hvResponse, _) = Response.parseNetworkCallResults(
            responseObject: HumanVerificationResponse(), originalResponse: task?.response, responseDict: responseDict, error: error
        )
        if let response = response as? [String: Any] {
            _ = hvResponse.ParseResponse(response)
        }
        self.isHumanVerifyUIPresented.mutate { $0 = true }
        
        // human verification required delegate
        DispatchQueue.global(qos: .default).async {
            self.hvDispatchGroup.enter()
            DispatchQueue.main.async {
                var currentURL: URL?
                if var url = URLComponents(string: path) {
                    url.query = nil
                    currentURL = url.url
                }
                self.humanDelegate?.onHumanVerify(parameters: hvResponse.parameters, currentURL: currentURL, error: error) { finishReason in
                    
                    switch finishReason {
                    case .close:
                        // finish request with existing completion block
                        completion?(task, responseDict, error)
                        if self.isHumanVerifyUIPresented.transform({ $0 == true }) {
                            self.isHumanVerifyUIPresented.mutate({ $0 = false })
                            self.hvDispatchGroup.leave()
                        }
                        
                    case .closeWithError(let code, let description):
                        // finish request with existing completion block
                        var newResponse: [String: Any] = responseDict
                        newResponse["Error"] = description
                        newResponse["Code"] = code
                        completion?(task, newResponse, error)
                        if self.isHumanVerifyUIPresented.transform({ $0 == true }) {
                            self.isHumanVerifyUIPresented.mutate({ $0 = false })
                            self.hvDispatchGroup.leave()
                        }
                        
                    case .verification(let header, let verificationCodeBlock):
                        verificationHandler(header: header, verificationCodeBlock: verificationCodeBlock)
                    }
                }
            }
        }
        
        func verificationHandler(header: HumanVerifyFinishReason.HumanVerifyHeader, verificationCodeBlock: SendVerificationCodeBlock?) {
            // human verification completion
            let hvCompletion: CompletionBlock = { task, response, error in
                // check if error code is one of the HV codes
                if let error = error, self.invalidHVCodes.first(where: { error.code == $0 }) != nil {
                    let responseError = self.getResponseError(task: task, response: response, error: error)
                    verificationCodeBlock?(false, responseError, nil)
                } else {
                    let code = response?["Code"] as? Int
                    var result = false
                    if code == APIErrorCode.responseOK {
                        result = true
                    } else {
                        // check if response "Code" is one of the HV codes
                        result = !(self.invalidHVCodes.first { code == $0 } != nil)
                    }
                    let responseError = result ? nil : self.getResponseError(task: task, response: response, error: error)
                    verificationCodeBlock?(result, responseError) {
                        // finish request with new completion block
                        completion?(task, response, error)
                        if self.isHumanVerifyUIPresented.transform({ $0 == true }) {
                            self.isHumanVerifyUIPresented.mutate({ $0 = false })
                            self.hvDispatchGroup.leave()
                        }
                    }
                }
            }
            
            // merge headers
            var newHeaders = headers ?? [:]
            newHeaders.merge(header) { (_, new) in new }
            
            // retry request
            self.request(method: method,
                         path: path,
                         parameters: parameters,
                         headers: newHeaders,
                         authenticated: authenticated,
                         authRetry: authRetry,
                         authRetryRemains: authRetryRemains,
                         customAuthCredential: customAuthCredential,
                         nonDefaultTimeout: nonDefaultTimeout,
                         completion: hvCompletion)
        }
    }

    private func getResponseError(task: URLSessionDataTask?, response: [String: Any]?, error: NSError?) -> ResponseError {
        return ResponseError(httpCode: (task?.response as? HTTPURLResponse)?.statusCode,
                             responseCode: response?["Code"] as? Int,
                             userFacingMessage: response?["Error"] as? String,
                             underlyingError: error)
    }
    
    private var invalidHVCodes: [Int] {
        // set of HV related codes which should be shown in HV UI
        return [APIErrorCode.invalidVerificationCode,
                APIErrorCode.tooManyVerificationCodes,
                APIErrorCode.tooManyFailedVerificationAttempts,
                APIErrorCode.humanVerificationAddressAlreadyTaken]
    }
}
