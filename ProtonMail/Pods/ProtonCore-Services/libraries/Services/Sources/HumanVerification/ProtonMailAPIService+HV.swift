//
//  ProtonMailAPIService+HV.swift
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

import Foundation
import ProtonCoreDoh
import ProtonCoreLog
import ProtonCoreNetworking
import ProtonCoreUtilities

// MARK: - Handling human verification

extension PMAPIService {

    var hvSynchronizingQueue: DispatchQueue { .global(qos: .userInitiated) }
    var hvCompletionQueue: DispatchQueue { .main }

    func humanVerificationHandler<T>(responseHandlerData: PMResponseHandlerData, completion: PMAPIService.APIResponseCompletion<T>, response: JSONDictionary) where T: APIDecodableResponse {

        let customAuthCredential = responseHandlerData.customAuthCredential.map(AuthCredential.init(copying:))

        // return completion if humanDelegate in not present
        guard self.humanDelegate != nil else {
            completion.call(task: responseHandlerData.task, error: self.getResponseError(task: responseHandlerData.task, response: response, error: nil) as NSError)
            return
        }

        // human verification required
        if self.isHumanVerifyUIPresented.transform({ $0 }) {
            // wait until ongoing human verification is finished
            hvSynchronizingQueue.async {
                self.hvDispatchGroup.wait()
                // recall request again
                self.hvCompletionQueue.async {
                    self.startRequest(method: responseHandlerData.method,
                                      path: responseHandlerData.path,
                                      parameters: responseHandlerData.parameters,
                                      headers: responseHandlerData.headers,
                                      authenticated: responseHandlerData.authenticated,
                                      authRetryRemains: responseHandlerData.authRetryRemains - 1,
                                      customAuthCredential: customAuthCredential,
                                      nonDefaultTimeout: responseHandlerData.nonDefaultTimeout,
                                      retryPolicy: responseHandlerData.retryPolicy,
                                      onDataTaskCreated: responseHandlerData.onDataTaskCreated,
                                      completion: completion)
                }
            }
        } else {
            // human verification UI
            self.humanVerificationUIHandler(method: responseHandlerData.method,
                                            path: responseHandlerData.path,
                                            parameters: responseHandlerData.parameters,
                                            headers: responseHandlerData.headers,
                                            authenticated: responseHandlerData.authenticated,
                                            authRetry: responseHandlerData.authRetry,
                                            authRetryRemains: responseHandlerData.authRetryRemains,
                                            customAuthCredential: customAuthCredential,
                                            nonDefaultTimeout: responseHandlerData.nonDefaultTimeout,
                                            retryPolicy: responseHandlerData.retryPolicy,
                                            task: responseHandlerData.task,
                                            response: response,
                                            onDataTaskCreated: responseHandlerData.onDataTaskCreated,
                                            completion: completion)
        }
    }

    // swiftlint:disable:next function_body_length
    private func humanVerificationUIHandler<T>(method: HTTPMethod,
                                               path: String,
                                               parameters: Any?,
                                               headers: [String: Any]?,
                                               authenticated: Bool = true,
                                               authRetry: Bool = true,
                                               authRetryRemains: Int = 3,
                                               customAuthCredential: AuthCredential? = nil,
                                               nonDefaultTimeout: TimeInterval?,
                                               retryPolicy: ProtonRetryPolicy.RetryMode,
                                               task: URLSessionDataTask?,
                                               response: JSONDictionary,
                                               onDataTaskCreated: @escaping (URLSessionDataTask) -> Void,
                                               completion: APIResponseCompletion<T>) where T: APIDecodableResponse {

        // process response to extract the human verification methods
        let responseDict = response.serialized

        let (hvResponse, _) = Response.parseNetworkCallResults(
            responseObject: HumanVerificationResponse(), originalResponse: task?.response,
            responseDict: responseDict, error: nil
        )
        _ = hvResponse.ParseResponse(responseDict)

        self.isHumanVerifyUIPresented.mutate { $0 = true }

        // human verification required delegate
        hvSynchronizingQueue.async {
            self.hvDispatchGroup.enter()
            self.hvCompletionQueue.async {
                var currentURL: URL?
                if var url = URLComponents(string: path) {
                    url.query = nil
                    currentURL = url.url
                }
                self.humanDelegate?.onHumanVerify(parameters: hvResponse.parameters, currentURL: currentURL) { finishReason in

                    switch finishReason {
                    case .close:
                        // finish request with existing completion block
                        completion.call(task: task, error: self.getResponseError(task: task, response: response, error: nil) as NSError)
                        if self.isHumanVerifyUIPresented.transform({ $0 }) {
                            self.isHumanVerifyUIPresented.mutate({ $0 = false })
                            self.hvDispatchGroup.leave()
                        }

                    case .closeWithError(let code, let description):
                        // finish request with existing completion block
                        var newResponse = response
                        newResponse.code = code
                        newResponse.errorMessage = description
                        completion.call(task: task, error: self.getResponseError(task: task, response: newResponse, error: nil) as NSError)
                        if self.isHumanVerifyUIPresented.transform({ $0 }) {
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

            // TODO: deduplicate

            switch completion {
            case .left(let jsonCompletion):

                let hvCompletion: JSONCompletion = { task, jsonResult in
                    // check if error code is one of the HV codes
                    switch jsonResult {
                    case .failure(let error):
                        if self.invalidHVCodes.first(where: { error.code == $0 }) != nil {
                            let responseError = self.getResponseError(task: task, response: [:], error: error)
                            verificationCodeBlock?(false, responseError, nil)
                        } else {
                            verificationCodeBlock?(true, nil) {
                                // finish request with new completion block
                                jsonCompletion(task, jsonResult)
                                if self.isHumanVerifyUIPresented.transform({ $0 }) {
                                    self.isHumanVerifyUIPresented.mutate({ $0 = false })
                                    self.hvDispatchGroup.leave()
                                }
                            }
                        }
                    case .success(let jsonDict):
                        let code = jsonDict["Code"] as? Int
                        var result = false
                        if code == APIErrorCode.responseOK {
                            result = true
                        } else {
                            // check if response "Code" is one of the HV codes
                            result = !(self.invalidHVCodes.first { code == $0 } != nil)
                        }
                        if result {
                            let responseError = result ? nil : self.getResponseError(task: task, response: jsonDict, error: nil)
                            verificationCodeBlock?(result, responseError) {
                                // finish request with new completion block
                                jsonCompletion(task, jsonResult)
                                if self.isHumanVerifyUIPresented.transform({ $0 }) {
                                    self.isHumanVerifyUIPresented.mutate({ $0 = false })
                                    self.hvDispatchGroup.leave()
                                }
                            }
                        } else {
                            let responseError = self.getResponseError(task: task, response: responseDict, error: nil)
                            verificationCodeBlock?(false, responseError, nil)
                        }
                    }
                }

                // merge headers
                var newHeaders = headers ?? [:]
                newHeaders.merge(header) { (_, new) in new }

                // retry request
                self.startRequest(method: method,
                                  path: path,
                                  parameters: parameters,
                                  headers: newHeaders,
                                  authenticated: authenticated,
                                  authRetry: authRetry,
                                  authRetryRemains: authRetryRemains,
                                  customAuthCredential: customAuthCredential,
                                  nonDefaultTimeout: nonDefaultTimeout,
                                  retryPolicy: retryPolicy,
                                  onDataTaskCreated: onDataTaskCreated,
                                  completion: Either<JSONCompletion, DecodableCompletion<T>>.left(hvCompletion))

            case .right(let decodableCompletion):

                let hvCompletion: DecodableCompletion<T> = { task, decodableResult in
                    // check if error code is one of the HV codes
                    switch decodableResult {
                    case .failure(let error):
                        if self.invalidHVCodes.first(where: { error.code == $0 }) != nil {
                            let responseError = self.getResponseError(task: task, response: [:], error: error)
                            verificationCodeBlock?(false, responseError, nil)
                        } else {
                            verificationCodeBlock?(true, nil) {
                                // finish request with new completion block
                                decodableCompletion(task, decodableResult)
                                if self.isHumanVerifyUIPresented.transform({ $0 }) {
                                    self.isHumanVerifyUIPresented.mutate({ $0 = false })
                                    self.hvDispatchGroup.leave()
                                }
                            }
                        }
                    case .success:
                        verificationCodeBlock?(true, nil) {
                            // finish request with new completion block
                            decodableCompletion(task, decodableResult)
                            if self.isHumanVerifyUIPresented.transform({ $0 }) {
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
                self.startRequest(method: method,
                                  path: path,
                                  parameters: parameters,
                                  headers: newHeaders,
                                  authenticated: authenticated,
                                  authRetry: authRetry,
                                  authRetryRemains: authRetryRemains,
                                  customAuthCredential: customAuthCredential,
                                  nonDefaultTimeout: nonDefaultTimeout,
                                  retryPolicy: retryPolicy,
                                  onDataTaskCreated: onDataTaskCreated,
                                  completion: Either<JSONCompletion, DecodableCompletion<T>>.right(hvCompletion))

            }
        }
    }

    private var invalidHVCodes: [Int] {
        // set of HV related codes which should be shown in HV UI
        return [APIErrorCode.invalidVerificationCode,
                APIErrorCode.tooManyVerificationCodes,
                APIErrorCode.tooManyFailedVerificationAttempts,
                APIErrorCode.humanVerificationAddressAlreadyTaken]
    }
}
