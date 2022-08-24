//
//  ProtonMailAPIService+Request.swift
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

// MARK: - Performing the network request

extension PMAPIService {
    
    public func request(method: HTTPMethod,
                        path: String,
                        parameters: Any?,
                        headers: [String: Any]?,
                        authenticated: Bool,
                        autoRetry: Bool,
                        customAuthCredential: AuthCredential?,
                        nonDefaultTimeout: TimeInterval?,
                        completion: CompletionBlock?) {
        
        self.request(method: method, path: path, parameters: parameters,
                     headers: headers, authenticated: authenticated, authRetry: autoRetry, authRetryRemains: 10,
                     customAuthCredential: customAuthCredential, nonDefaultTimeout: nonDefaultTimeout, completion: completion)
        
    }
    
    // new requestion function
    // TODO:: the retry count need to improved
    //         -- retry count should depends on what error you receive.
    //         -- auth retry should seperate from normal retry.
    func request(method: HTTPMethod,
                 path: String,
                 parameters: Any?,
                 headers: [String: Any]?,
                 authenticated: Bool = true,
                 authRetry: Bool = true,
                 authRetryRemains: Int = 3,
                 customAuthCredential: AuthCredential? = nil,
                 nonDefaultTimeout: TimeInterval?,
                 completion: CompletionBlock?) {
        if let customAuthCredential = customAuthCredential {
            performRequestHavingFetchedCredentials(method: method,
                                                   path: path,
                                                   parameters: parameters,
                                                   headers: headers,
                                                   authenticated: authenticated,
                                                   authRetry: authRetry,
                                                   authRetryRemains: authRetryRemains,
                                                   fetchingCredentialsResult: .found(credentials: AuthCredential(copying: customAuthCredential)),
                                                   nonDefaultTimeout: nonDefaultTimeout,
                                                   completion: completion)
        } else {
            fetchAuthCredentials { result in
                self.performRequestHavingFetchedCredentials(method: method,
                                                            path: path,
                                                            parameters: parameters,
                                                            headers: headers,
                                                            authenticated: authenticated,
                                                            authRetry: authRetry,
                                                            authRetryRemains: authRetryRemains,
                                                            fetchingCredentialsResult: result,
                                                            nonDefaultTimeout: nonDefaultTimeout,
                                                            completion: completion)
            }
        }
    }
    
    private func performRequestHavingFetchedCredentials(method: HTTPMethod,
                                                        path: String,
                                                        parameters: Any?,
                                                        headers: [String: Any]?,
                                                        authenticated: Bool,
                                                        authRetry: Bool,
                                                        authRetryRemains: Int,
                                                        fetchingCredentialsResult: AuthCredentialFetchingResult,
                                                        nonDefaultTimeout: TimeInterval?,
                                                        completion: CompletionBlock?) {

        if authenticated, fetchingCredentialsResult == .wrongConfigurationNoDelegate || fetchingCredentialsResult == .notFound {
            let error = fetchingCredentialsResult.toNSError
            self.debugError(error)
            completion?(nil, nil, error)
            return
        }
        
        let authCredential: AuthCredential?
        let accessToken: String?
        let UID: String?
        if case .found(let credentials) = fetchingCredentialsResult {
            authCredential = credentials
            accessToken = credentials.accessToken
            // TODO: was that the previous behaviour as well
            UID = credentials.sessionID
        } else {
            authCredential = nil
            accessToken = nil
            UID = nil
        }
        
        let url = self.doh.getCurrentlyUsedHostUrl() + path
        
        do {
            
            let request = try self.createRequest(
                url: url, method: method, parameters: parameters, nonDefaultTimeout: nonDefaultTimeout,
                headers: headers, UID: UID, accessToken: accessToken
            )
            
            try self.session.request(with: request) { task, res, originalError in
                var error = originalError
                self.debug(task, res, originalError)
                self.updateServerTime(task?.response)
                
                if let tlsErrorDescription = self.session.failsTLS(request: request) {
                    error = NSError.protonMailError(APIErrorCode.tls, localizedDescription: tlsErrorDescription)
                }
                self.doh.handleErrorResolvingProxyDomainAndSynchronizingCookiesIfNeeded(
                    host: url, sessionId: UID, response: task?.response, error: error) { shouldRetry in
                    
                    if shouldRetry {
                        // retry. will use the proxy domain automatically if it was successfully fetched
                        self.request(method: method,
                                     path: path,
                                     parameters: parameters,
                                     headers: headers,
                                     authenticated: authenticated,
                                     authRetry: authRetry,
                                     authRetryRemains: authRetryRemains,
                                     customAuthCredential: authCredential,
                                     nonDefaultTimeout: nonDefaultTimeout,
                                     completion: completion)
                    } else {
                        // finish the request if it should not be retried
                        if self.doh.errorIndicatesDoHSolvableProblem(error: error) {
                            self.serviceDelegate?.onDohTroubleshot()
                        }
                        self.handleNetworkRequestBeingFinished(task,
                                                               res,
                                                               error,
                                                               method: method,
                                                               path: path,
                                                               parameters: parameters,
                                                               headers: headers,
                                                               authenticated: authenticated,
                                                               authRetry: authRetry,
                                                               authRetryRemains: authRetryRemains,
                                                               authCredential: authCredential,
                                                               nonDefaultTimeout: nonDefaultTimeout,
                                                               completion: completion)
                    }
                }
            }
        } catch let error {
            completion?(nil, nil, error as NSError)
        }
    }
    
    private func handleNetworkRequestBeingFinished(_ task: URLSessionDataTask?,
                                                   _ response: Any?,
                                                   _ error: Error?,
                                                   method: HTTPMethod,
                                                   path: String,
                                                   parameters: Any?,
                                                   headers: [String: Any]?,
                                                   authenticated: Bool,
                                                   authRetry: Bool,
                                                   authRetryRemains: Int,
                                                   authCredential: AuthCredential?,
                                                   nonDefaultTimeout: TimeInterval?,
                                                   completion: CompletionBlock?) {
        if let error = error as NSError? {
            handleNetworkRequestFailing(error, task, authenticated, authRetry, authCredential, method, path, parameters, authRetryRemains, nonDefaultTimeout, completion, response, headers)
        } else {
            handleNetworkRequestSucceeding(error, task, authenticated, authRetry, authCredential, method, path, parameters, authRetryRemains, nonDefaultTimeout, completion, response, headers)
        }
    }
    
    private func handleNetworkRequestFailing(
        _ error: NSError, _ task: URLSessionDataTask?, _ authenticated: Bool, _ authRetry: Bool,
        _ authCredential: AuthCredential?, _ method: HTTPMethod, _ path: String, _ parameters: Any?, _ authRetryRemains: Int,
        _ nonDefaultTimeout: TimeInterval?, _ completion: CompletionBlock?, _ response: Any?, _ headers: [String: Any]?
    ) {
        self.debugError(error)
        // PMLog.D(api: error)
        var httpCode: Int = 200
        if let detail = task?.response as? HTTPURLResponse {
            httpCode = detail.statusCode
        } else {
            httpCode = error.code
        }
        
        if authenticated, httpCode == 401, authRetry, let authCredential = authCredential {
            
            handleRefreshingCredentials(authCredential, method, path, parameters, authenticated, authRetry, authRetryRemains, nonDefaultTimeout, completion, error, task)
            
        } else if let responseDict = response as? [String: Any], let responseCode = responseDict["Code"] as? Int {
            
            let errorMessage = responseDict["Error"] as? String ?? ""
            let displayError = NSError.protonMailError(responseCode,
                                                       localizedDescription: errorMessage,
                                                       localizedFailureReason: errorMessage,
                                                       localizedRecoverySuggestion: nil)
            
            handleProtonResponseCode(responseDict, responseCode, method, path, parameters, headers, authenticated, authRetry, authRetryRemains, authCredential, nonDefaultTimeout, response, task, displayError, completion)
            
        } else {
            completion?(task, nil, error)
        }
    }
    
    func handleNetworkRequestSucceeding(
        _ error: Error?, _ task: URLSessionDataTask?, _ authenticated: Bool, _ authRetry: Bool,
        _ authCredential: AuthCredential?, _ method: HTTPMethod, _ path: String, _ parameters: Any?, _ authRetryRemains: Int,
        _ nonDefaultTimeout: TimeInterval?, _ completion: CompletionBlock?, _ response: Any?, _ headers: [String: Any]?
    ) {
        
        guard let response = response else {
            completion?(task, [:], nil)
            return
        }
        
        guard let responseDictionary = response as? [String: Any],
                let responseCode = responseDictionary["Code"] as? Int
        else {
            let err = NSError.protonMailError(0, localizedDescription: "Unable to parse successful response")
            self.debugError(err)
            completion?(task, nil, err)
            return
        }
        
        var error: NSError?
        if responseCode != 1000 && responseCode != 1001 {
            let errorMessage = responseDictionary["Error"] as? String
            error = NSError.protonMailError(responseCode,
                                            localizedDescription: errorMessage ?? "",
                                            localizedFailureReason: errorMessage,
                                            localizedRecoverySuggestion: nil)
        }
        
        if authenticated, responseCode == 401, authRetry, let authCredential = authCredential {
            
            handleRefreshingCredentials(authCredential, method, path, parameters, authenticated, authRetry, authRetryRemains, nonDefaultTimeout, completion, error, task)
            
        } else {
            handleProtonResponseCode(responseDictionary, responseCode, method, path, parameters, headers, authenticated, authRetry, authRetryRemains, authCredential, nonDefaultTimeout, response, task, error, completion)
        }
        self.debugError(error)
    }
    
    private func handleRefreshingCredentials(
        _ authCredential: AuthCredential, _ method: HTTPMethod, _ path: String, _ parameters: Any?, _ authenticated: Bool,
        _ authRetry: Bool, _ authRetryRemains: Int, _ nonDefaultTimeout: TimeInterval?, _ completion: CompletionBlock?,
        _ error: NSError?, _ task: URLSessionDataTask?
    ) {
        
        guard !path.isRefreshPath, authRetryRemains > 0 else {
            completion?(task, nil, error)
            return
        }
        
        refreshAuthCredential(credentialsCausing401: authCredential) { result in
            switch result {
            case .refreshed(let credentials):
                self.performRequestHavingFetchedCredentials(method: method,
                                                            path: path,
                                                            parameters: parameters,
                                                            headers: [:],
                                                            authenticated: authenticated,
                                                            authRetry: authRetry,
                                                            authRetryRemains: authRetryRemains - 1,
                                                            fetchingCredentialsResult: .found(credentials: credentials),
                                                            nonDefaultTimeout: nonDefaultTimeout,
                                                            completion: completion)
            case .logout(let underlyingError):
                let error = underlyingError.underlyingError
                    ?? NSError.protonMailError(underlyingError.bestShotAtReasonableErrorCode,
                                               localizedDescription: underlyingError.localizedDescription)
                completion?(task, nil, error)
            case .refreshingError(let underlyingError):
                let error = NSError.protonMailError(underlyingError.codeInNetworking,
                                                    localizedDescription: underlyingError.localizedDescription)
                completion?(task, nil, error)
            case .wrongConfigurationNoDelegate, .noCredentialsToBeRefreshed, .unknownError:
                let error = NSError.protonMailError(0, localizedDescription: "User was logged out")
                completion?(task, nil, error)
            }
        }
    }
    
    fileprivate func handleProtonResponseCode(
        _ responseDict: [String: Any], _ responseCode: Int, _ method: HTTPMethod, _ path: String, _ parameters: Any?,
        _ headers: [String: Any]?, _ authenticated: Bool, _ authRetry: Bool, _ authRetryRemains: Int,
        _ authCredential: AuthCredential?, _ nonDefaultTimeout: TimeInterval?, _ response: Any?,
        _ task: URLSessionDataTask?, _ error: NSError?, _ completion: CompletionBlock?
    ) {
        if responseCode == APIErrorCode.humanVerificationRequired, let error = error {
            // human verification required
            self.humanVerificationHandler(method: method,
                                          path: path,
                                          parameters: parameters,
                                          headers: headers,
                                          authenticated: authenticated,
                                          authRetry: authRetry,
                                          authRetryRemains: authRetryRemains,
                                          customAuthCredential: authCredential,
                                          nonDefaultTimeout: nonDefaultTimeout,
                                          error: error,
                                          response: response,
                                          task: task,
                                          responseDict: responseDict,
                                          completion: completion)
        } else if responseCode == APIErrorCode.badAppVersion || responseCode == APIErrorCode.badApiVersion {
            self.forceUpgradeHandler(responseDictionary: responseDict)
            completion?(task, responseDict, error)
        } else if responseCode == APIErrorCode.API_offline {
            completion?(task, responseDict, error)
        } else {
            completion?(task, responseDict, error)
        }
    }
    
}

// MARK: - Helper methods for creating the request, debugging etc.

extension PMAPIService {
    
    func createRequest(url: String,
                       method: HTTPMethod,
                       parameters: Any?,
                       nonDefaultTimeout: TimeInterval?,
                       headers: [String: Any]?,
                       UID: String?,
                       accessToken: String?) throws -> SessionRequest {
        
        let defaultTimeout = doh.status == .off ? 60.0 : 30.0
        let requestTimeout = nonDefaultTimeout ?? defaultTimeout
        let request = try session.generate(with: method, urlString: url, parameters: parameters, timeout: requestTimeout)
        
        if let additionalHeaders = serviceDelegate?.additionalHeaders {
            additionalHeaders.forEach { header, value in
                request.setValue(header: header, value)
            }
        }
       
        if let header = headers {
            for (k, v) in header {
                request.setValue(header: k, "\(v)")
            }
        }
        
        if let accessToken = accessToken, !accessToken.isEmpty {
            request.setValue(header: "Authorization", "Bearer \(accessToken)")
        }
        
        if let UID = UID, !UID.isEmpty {
            request.setValue(header: "x-pm-uid", UID)
        }
        
        var appversion = "iOS_\(Bundle.main.majorVersion)"
        if let delegateAppVersion = serviceDelegate?.appVersion, !delegateAppVersion.isEmpty {
            appversion = delegateAppVersion
        }
        request.setValue(header: "Accept", "application/vnd.protonmail.v1+json")
        request.setValue(header: "x-pm-appversion", appversion)
        
        var locale = "en_US"
        if let lc = serviceDelegate?.locale, !lc.isEmpty {
            locale = lc
        }
        request.setValue(header: "x-pm-locale", locale)
        
        var ua = UserAgent.default.ua ?? "Unknown"
        if let delegateAgent = serviceDelegate?.userAgent, !delegateAgent.isEmpty {
            ua = delegateAgent
        }
        request.setValue(header: "User-Agent", ua)
        
        return request
    }
    
    func updateServerTime(_ response: URLResponse?) {
        guard let urlres = response as? HTTPURLResponse,
              let allheader = urlres.allHeaderFields as? [String: Any],
              let strData = allheader["Date"] as? String,
              let date = DateParser.parse(time: strData)
        else { return }
        
        let timeInterval = date.timeIntervalSince1970
        self.serviceDelegate?.onUpdate(serverTime: Int64(timeInterval))
    }
    
    func debug(_ task: URLSessionTask?, _ response: Any?, _ error: NSError?) {
        #if DEBUG_CORE_INTERNALS
        if let request = task?.originalRequest, let httpResponse = task?.response as? HTTPURLResponse {
            PMLog.debug("""
                        
                        
                        [REQUEST]
                        url: \(request.url!)
                        method: \(request.httpMethod ?? "-")
                        headers: \((request.allHTTPHeaderFields as [String: Any]?)?.json(prettyPrinted: true) ?? "")
                        body: \(request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? "-")
                        
                        [RESPONSE]
                        url: \(httpResponse.url!)
                        code: \(httpResponse.statusCode)
                        headers: \((httpResponse.allHeaderFields as? [String: Any])?.json(prettyPrinted: true) ?? "")
                        body: \((response as? [String: Any])?.json(prettyPrinted: true) ?? "")
                        
                        """)
        }
        debugError(error)
        #endif
    }
    
    func debugError(_ error: Error?) {
        #if DEBUG_CORE_INTERNALS
        guard let error = error else { return }
        PMLog.debug("""
                    
                    [ERROR]
                    code: \(error.bestShotAtReasonableErrorCode)
                    message: \(error.messageForTheUser)
                    """)
        #endif
    }
    
}
