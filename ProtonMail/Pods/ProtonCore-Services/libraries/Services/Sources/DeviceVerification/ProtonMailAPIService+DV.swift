//
//  ProtonMailAPIService+DV.swift
//  ProtonCore-Services - Created on 03/15/23.
//
//  Copyright (c) 2023 Proton Technologies AG
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

// MARK: - Handling device verification

extension PMAPIService {

    /// This function is responsible for handling device verification for an API request. It first checks if there is an ongoing device verification process or not. If there is an ongoing process, it waits for it to finish and then retries the request. If there is no ongoing process, it calls the deviceVerificationProcess function.
    func deviceVerificationHandler<T>(responseHandlerData: PMResponseHandlerData, completion: PMAPIService.APIResponseCompletion<T>, response: JSONDictionary) where T: APIDecodableResponse {
        let customAuthCredential = responseHandlerData.customAuthCredential.map(AuthCredential.init(copying:))

        // return completion if humanDelegate in not present
        guard self.humanDelegate != nil else {
            completion.call(task: responseHandlerData.task, response: .left(response))
            return
        }

        // device verification required
        if self.isDeviceVerifyProcessing.transform({ $0 }) {
            // wait until ongoing device verification is finished
            dvSynchronizingQueue.async {
                self.dvDispatchGroup.wait()
                // recall request again
                self.dvCompletionQueue.async {
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
            // device verification none ui
            self.deviceVerificationProcess(method: responseHandlerData.method,
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

    /// This function initiates the device verification process. It first parses the response object and checks if the API requires device verification. If it does, the function sets a flag (isDeviceVerifyProcessing) to indicate that a device verification process is ongoing. Then, it calls the onDeviceVerify delegate method, which should be implemented by the upper layer. Once the device verification is completed, the API request is retried with the new headers containing the solved challenge.
    private func deviceVerificationProcess<T>(method: HTTPMethod,
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
        let responseDict = response.serialized
        let (dvResponse, _) = Response.parseNetworkCallResults(
            responseObject: DeviceVerificationResponse(),
            originalResponse: task?.response,
            responseDict: response, error: nil
        )
        _ = dvResponse.ParseResponse(responseDict)
        // return completion if humanDelegate in not present
        guard let detailsParameters = dvResponse.parameters else {
            completion.call(task: task, error: self.getResponseError(task: task, response: response, error: nil) as NSError)
            return
        }

        self.isDeviceVerifyProcessing.mutate { $0 = true }

        // device verification required delegate
        dvSynchronizingQueue.async {
            self.dvDispatchGroup.enter()
            self.dvCompletionQueue.async {
                let solvedChallenge = self.humanDelegate?.onDeviceVerify(parameters: detailsParameters)
                guard let solvedChallenge = solvedChallenge, !solvedChallenge.isEmpty else {
                    completion.call(task: task, error: self.getResponseError(task: task, response: response, error: nil) as NSError)
                    self.releaseDeviceVerificationMutex()
                    return
                }

                var newHeaders = headers ?? [:]
                newHeaders.merge(["X-PM-DV": solvedChallenge]) { (_, new) in new }

                let retryCompletion = self.createRetryCompletion(completion)
                self.startRequest(method: method,
                                  path: path,
                                  parameters: parameters,
                                  headers: newHeaders,
                                  authenticated: authenticated,
                                  authRetry: authRetry,
                                  authRetryRemains: authRetryRemains - 1,
                                  customAuthCredential: customAuthCredential,
                                  nonDefaultTimeout: nonDefaultTimeout,
                                  retryPolicy: retryPolicy,
                                  onDataTaskCreated: onDataTaskCreated,
                                  completion: retryCompletion)
            }
        }
    }

    private func releaseDeviceVerificationMutex() {
        if isDeviceVerifyProcessing.transform({ $0 }) {
            isDeviceVerifyProcessing.mutate({ $0 = false })
            dvDispatchGroup.leave()
        }
    }

    private func createRetryCompletion<T>(_ completion: APIResponseCompletion<T>) -> APIResponseCompletion<T> where T: APIDecodableResponse {
        switch completion {
        case .left(let jsonCompletion):
            let dvCompletion: JSONCompletion = { task, jsonResult in
                jsonCompletion(task, jsonResult)
                self.releaseDeviceVerificationMutex()
            }
            return .left(dvCompletion)
        case .right(let decodableCompletion):
            let dvCompletion: DecodableCompletion<T> = { task, result in
                decodableCompletion(task, result)
                self.releaseDeviceVerificationMutex()
            }
            return .right(dvCompletion)
        }
    }
}
