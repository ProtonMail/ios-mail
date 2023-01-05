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
import ProtonCore_CoreTranslation
import ProtonCore_Doh
import ProtonCore_Log
import ProtonCore_Networking
import ProtonCore_Utilities

extension Result {
    
    var value: Success? {
        guard case .success(let valueObject) = self else { return nil }
        return valueObject
    }
    
    var error: Failure? {
        guard case .failure(let errorObject) = self else { return nil }
        return errorObject
    }
}

// MARK: - Performing the network request

extension PMAPIService {
    
    // never used anywhere, jsut a placeholder for generics so we can keep single implementation for both JSONDictionary and Decodable
    struct DummyAPIDecodableResponseOnlyForSatisfyingGenericsResolving: APIDecodableResponse {}
    
    public func request(method: HTTPMethod,
                        path: String,
                        parameters: Any?,
                        headers: [String: Any]?,
                        authenticated: Bool,
                        autoRetry: Bool,
                        customAuthCredential: AuthCredential?,
                        nonDefaultTimeout: TimeInterval?,
                        retryPolicy: ProtonRetryPolicy.RetryMode,
                        jsonCompletion: @escaping JSONCompletion) {
        startRequest(
            method: method, path: path, parameters: parameters, headers: headers, authenticated: authenticated, authRetry: autoRetry,
            authRetryRemains: 10, customAuthCredential: customAuthCredential.map(AuthCredential.init(copying:)), nonDefaultTimeout: nonDefaultTimeout,
            retryPolicy: retryPolicy,
            completion: Either<JSONCompletion, DecodableCompletion<DummyAPIDecodableResponseOnlyForSatisfyingGenericsResolving>>.left(
                transformJSONCompletion(jsonCompletion)
            )
        )
    }
    
    public func request<T>(method: HTTPMethod,
                           path: String,
                           parameters: Any?,
                           headers: [String: Any]?,
                           authenticated: Bool,
                           autoRetry: Bool,
                           customAuthCredential: AuthCredential?,
                           nonDefaultTimeout: TimeInterval?,
                           retryPolicy: ProtonRetryPolicy.RetryMode,
                           decodableCompletion: @escaping DecodableCompletion<T>) where T: APIDecodableResponse {
        startRequest(
            method: method, path: path, parameters: parameters, headers: headers, authenticated: authenticated, authRetry: autoRetry,
            authRetryRemains: 10, customAuthCredential: customAuthCredential.map(AuthCredential.init(copying:)), nonDefaultTimeout: nonDefaultTimeout, retryPolicy: retryPolicy, completion: .right(decodableCompletion)
        )
    }
    
    // new requestion function
    // TODO:: the retry count need to improved
    //         -- retry count should depends on what error you receive.
    func startRequest<T>(method: HTTPMethod,
                         path: String,
                         parameters: Any?,
                         headers: [String: Any]?,
                         authenticated: Bool = true,
                         authRetry: Bool = true,
                         authRetryRemains: Int = 3,
                         customAuthCredential: AuthCredential? = nil,
                         nonDefaultTimeout: TimeInterval?,
                         retryPolicy: ProtonRetryPolicy.RetryMode,
                         completion: APIResponseCompletion<T>) where T: APIDecodableResponse {

        if !authenticated {
            performRequestHavingFetchedCredentials(method: method,
                                                   path: path,
                                                   parameters: parameters,
                                                   headers: headers,
                                                   authenticated: authenticated,
                                                   authRetry: authRetry,
                                                   authRetryRemains: authRetryRemains,
                                                   fetchingCredentialsResult: .notFound,
                                                   nonDefaultTimeout: nonDefaultTimeout,
                                                   retryPolicy: retryPolicy,
                                                   completion: completion)
        } else if let customAuthCredential = customAuthCredential {
            performRequestHavingFetchedCredentials(method: method,
                                                   path: path,
                                                   parameters: parameters,
                                                   headers: headers,
                                                   authenticated: authenticated,
                                                   authRetry: authRetry,
                                                   authRetryRemains: authRetryRemains,
                                                   fetchingCredentialsResult: .found(credentials: AuthCredential(copying: customAuthCredential)),
                                                   nonDefaultTimeout: nonDefaultTimeout,
                                                   retryPolicy: retryPolicy,
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
                                                            retryPolicy: retryPolicy,
                                                            completion: completion)
            }
        }
    }
    
    private func performRequestHavingFetchedCredentials<T>(method: HTTPMethod,
                                                           path: String,
                                                           parameters: Any?,
                                                           headers: [String: Any]?,
                                                           authenticated: Bool,
                                                           authRetry: Bool,
                                                           authRetryRemains: Int,
                                                           fetchingCredentialsResult: AuthCredentialFetchingResult,
                                                           nonDefaultTimeout: TimeInterval?,
                                                           retryPolicy: ProtonRetryPolicy.RetryMode,
                                                           completion: APIResponseCompletion<T>) where T: APIDecodableResponse {

        if authenticated, let error = fetchingCredentialsResult.toNSError {
            self.debugError(error)
            completion.call(task: nil, error: error)
            return
        }
        
        let authCredential: AuthCredential?
        let accessToken: String?
        let UID: String?
        if case .found(let credentials) = fetchingCredentialsResult {
            authCredential = credentials
            accessToken = credentials.accessToken
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
                headers: headers, UID: UID, accessToken: accessToken, retryPolicy: retryPolicy
            )

            let sessionRequestCall: (@escaping (URLSessionDataTask?, ResponseFromSession<T>) -> Void) -> Void
            switch completion {
            case .left:
                sessionRequestCall = { continuation in
                    let cookies = self.session.sessionConfiguration.httpCookieStorage?.cookies(for: URL(string: url)!) ?? []
                    let headers = HTTPCookie.requestHeaderFields(with: cookies)
                    PMLog.debug("[COOKIES][REQUEST][SERVICE] \(headers)")
                    self.session.request(with: request) { (task, result: Result<JSONDictionary, SessionResponseError>) in
                        self.debug(task, result.value, result.error?.underlyingError)
                        continuation(task, .left(result))
                    }
                }
            case .right:
                let decoder = jsonDecoder
                sessionRequestCall = { continuation in
                    let cookies = self.session.sessionConfiguration.httpCookieStorage?.cookies(for: URL(string: url)!) ?? []
                    let headers = HTTPCookie.requestHeaderFields(with: cookies)
                    PMLog.debug("[COOKIES][REQUEST][SERVICE] \(headers)")
                    self.session.request(with: request, jsonDecoder: decoder) { (task, result: Result<T, SessionResponseError>) in
                        self.debug(task, result.value, result.error?.underlyingError)
                        continuation(task, .right(result))
                    }
                }
            }
            
            sessionRequestCall { task, responseFromSession in
                var error: NSError? = responseFromSession.possibleError()?.underlyingError
                self.updateServerTime(task?.response)
                
                var response = responseFromSession
                    .mapLeft { $0.mapError { $0.underlyingError } }
                    .mapRight { $0.mapError { $0.underlyingError } }
                
                if let tlsErrorDescription = self.session.failsTLS(request: request) {
                    error = NSError.protonMailError(APIErrorCode.tls, localizedDescription: tlsErrorDescription)
                }
                let requestHeaders = task?.originalRequest?.allHTTPHeaderFields ?? request.request?.allHTTPHeaderFields ?? [:]
                self.doh.handleErrorResolvingProxyDomainAndSynchronizingCookiesIfNeeded(
                    host: url, requestHeaders: requestHeaders, sessionId: UID, response: task?.response, error: error, callCompletionBlockUsing: .asyncMainExecutor) { shouldRetry in
                    
                    if shouldRetry {
                        // retry. will use the proxy domain automatically if it was successfully fetched
                        self.startRequest(method: method,
                                          path: path,
                                          parameters: parameters,
                                          headers: headers,
                                          authenticated: authenticated,
                                          authRetry: authRetry,
                                          authRetryRemains: authRetryRemains,
                                          customAuthCredential: authCredential,
                                          nonDefaultTimeout: nonDefaultTimeout,
                                          retryPolicy: retryPolicy,
                                          completion: completion)
                    } else {
                        // finish the request if it should not be retried
                        if self.doh.errorIndicatesDoHSolvableProblem(error: error) {
                            let apiBlockedError = NSError.protonMailError(APIErrorCode.potentiallyBlocked,
                                                                          localizedDescription: CoreString._net_api_might_be_blocked_message)
                            response = response.mapLeft { _ in .failure(apiBlockedError) }.mapRight { _ in .failure(apiBlockedError) }
                        }
                        self.handleNetworkRequestBeingFinished(task,
                                                               response,
                                                               method: method,
                                                               path: path,
                                                               parameters: parameters,
                                                               headers: headers,
                                                               authenticated: authenticated,
                                                               authRetry: authRetry,
                                                               authRetryRemains: authRetryRemains,
                                                               authCredential: authCredential,
                                                               nonDefaultTimeout: nonDefaultTimeout,
                                                               retryPolicy: retryPolicy,
                                                               completion: completion)
                    }
                }
            }
        } catch let error {
            completion.call(task: nil, error: error as NSError)
        }
    }
    
    private func handleNetworkRequestBeingFinished<T>(_ task: URLSessionDataTask?,
                                                      _ response: ResponseInPMAPIService<T>,
                                                      method: HTTPMethod,
                                                      path: String,
                                                      parameters: Any?,
                                                      headers: [String: Any]?,
                                                      authenticated: Bool,
                                                      authRetry: Bool,
                                                      authRetryRemains: Int,
                                                      authCredential: AuthCredential?,
                                                      nonDefaultTimeout: TimeInterval?,
                                                      retryPolicy: ProtonRetryPolicy.RetryMode,
                                                      completion: APIResponseCompletion<T>) where T: APIDecodableResponse {
        switch response {
        case .left(.success(let jsonDict)):
            handleJSONResponse(task, jsonDict, authenticated, authRetry, authCredential, method, path, parameters, authRetryRemains, nonDefaultTimeout, retryPolicy, completion, headers)
        case .right(.success(let object)):
            completion.call(task: task, response: .right(object))
        case .left(.failure(let error)), .right(.failure(let error)):
            handleAPIError(task, error, authenticated, authRetry, authCredential, method, path, parameters, authRetryRemains, nonDefaultTimeout, retryPolicy, completion, headers)
        }
    }
    
    private func handleAPIError<T>(
        _ task: URLSessionDataTask?, _ error: API.APIError, _ authenticated: Bool, _ authRetry: Bool,
        _ authCredential: AuthCredential?, _ method: HTTPMethod, _ path: String, _ parameters: Any?, _ authRetryRemains: Int,
        _ nonDefaultTimeout: TimeInterval?, _ retryPolicy: ProtonRetryPolicy.RetryMode, _ completion: APIResponseCompletion<T>, _ headers: [String: Any]?
    ) where T: APIDecodableResponse {
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
            
        } else if let responseError = error as? ResponseError, let responseCode = responseError.responseCode {
            
            handleProtonResponseCode(task, .right(responseError), responseCode, method, path, parameters, headers, authenticated, authRetry, authRetryRemains, authCredential, nonDefaultTimeout, retryPolicy, completion)

        } else {
            completion.call(task: task, error: error)
        }
    }
    
    func handleJSONResponse<T>(
        _ task: URLSessionDataTask?, _ response: JSONDictionary, _ authenticated: Bool, _ authRetry: Bool,
        _ authCredential: AuthCredential?, _ method: HTTPMethod, _ path: String, _ parameters: Any?, _ authRetryRemains: Int,
        _ nonDefaultTimeout: TimeInterval?, _ retryPolicy: ProtonRetryPolicy.RetryMode,
        _ completion: APIResponseCompletion<T>, _ headers: [String: Any]?
    ) where T: APIDecodableResponse {
        
        guard !response.isEmpty else {
            completion.call(task: task, response: .left(response))
            return
        }
        
        guard let responseCode = response.code else {
            let err = NSError.protonMailError(0, localizedDescription: "Unable to parse successful response")
            self.debugError(err)
            completion.call(task: task, error: err)
            return
        }
        
        var error: NSError?
        if responseCode != 1000 && responseCode != 1001 {
            let errorMessage = response.errorMessage
            error = NSError.protonMailError(responseCode,
                                            localizedDescription: errorMessage ?? "",
                                            localizedFailureReason: errorMessage,
                                            localizedRecoverySuggestion: nil)
        }
        
        if authenticated, responseCode == 401, authRetry, let authCredential = authCredential {
            
            handleRefreshingCredentials(authCredential, method, path, parameters, authenticated, authRetry, authRetryRemains, nonDefaultTimeout, completion, error, task)
            
        } else {
            handleProtonResponseCode(task, .left(response), responseCode, method, path, parameters, headers, authenticated, authRetry, authRetryRemains, authCredential, nonDefaultTimeout, retryPolicy, completion)
        }
        self.debugError(error)
    }
    
    private func handleRefreshingCredentials<T>(
        _ authCredential: AuthCredential, _ method: HTTPMethod, _ path: String, _ parameters: Any?, _ authenticated: Bool,
        _ authRetry: Bool, _ authRetryRemains: Int, _ nonDefaultTimeout: TimeInterval?, _ completion: APIResponseCompletion<T>,
        _ error: NSError?, _ task: URLSessionDataTask?
    ) where T: APIDecodableResponse {
        
        guard !path.isRefreshPath, authRetryRemains > 0 else {
            // TODO: provide better error?
            completion.call(task: task, error: error ?? NSError.protonMailError(0, localizedDescription: ""))
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
                                                            retryPolicy: .userInitiated,
                                                            completion: completion)
            case .logout(let underlyingError):
                let error = underlyingError.underlyingError
                    ?? NSError.protonMailError(underlyingError.bestShotAtReasonableErrorCode,
                                               localizedDescription: underlyingError.localizedDescription)
                completion.call(task: task, error: error)
            case .refreshingError(let underlyingError):
                let error = NSError.protonMailError(underlyingError.codeInNetworking,
                                                    localizedDescription: underlyingError.localizedDescription)
                completion.call(task: task, error: error)
            case .wrongConfigurationNoDelegate, .noCredentialsToBeRefreshed:
                let error = NSError.protonMailError(0, localizedDescription: "User was logged out")
                completion.call(task: task, error: error)
            }
        }
    }
    
    fileprivate func handleProtonResponseCode<T>(
        _ task: URLSessionDataTask?, _ response: Either<JSONDictionary, ResponseError>, _ responseCode: Int, _ method: HTTPMethod, _ path: String, _ parameters: Any?,
        _ headers: [String: Any]?, _ authenticated: Bool, _ authRetry: Bool, _ authRetryRemains: Int,
        _ authCredential: AuthCredential?, _ nonDefaultTimeout: TimeInterval?, _ retryPolicy: ProtonRetryPolicy.RetryMode,
        _ completion: APIResponseCompletion<T>
    ) where T: APIDecodableResponse {

        if responseCode == APIErrorCode.humanVerificationRequired {
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
                                          retryPolicy: retryPolicy,
                                          task: task,
                                          response: response.responseDictionary,
                                          completion: completion)
        } else if responseCode == APIErrorCode.badAppVersion || responseCode == APIErrorCode.badApiVersion {
            self.forceUpgradeHandler(errorMessage: response.errorMessage)
            completion.call(task: task, response: .left(response.responseDictionary))
        } else if responseCode == APIErrorCode.API_offline {
            completion.call(task: task, response: .left(response.responseDictionary))
        } else {
            switch response {
            case .left(let jsonDictionary): completion.call(task: task, response: .left(jsonDictionary))
            case .right(let responseError): completion.call(task: task, error: responseError as NSError)
            }
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
                       accessToken: String?,
                       retryPolicy: ProtonRetryPolicy.RetryMode = .userInitiated) throws -> SessionRequest {
        
        let defaultTimeout = doh.status == .off ? 60.0 : 30.0
        let requestTimeout = nonDefaultTimeout ?? defaultTimeout
        let request = try session.generate(with: method, urlString: url, parameters: parameters, timeout: requestTimeout, retryPolicy: retryPolicy)
        
        let dohHeaders = doh.getCurrentlyUsedUrlHeaders()
        dohHeaders.forEach { header, value in
            request.setValue(header: header, value)
        }
        
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
                        body: \((response as? [String: Any])?.json(prettyPrinted: true) ?? response.map { String(describing: $0) } ?? "")
                        
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

extension PMAPIService {
    
    func sessionRequest<T: Decodable>(request: Request, result: @escaping (URLSessionDataTask?, Result<T, APIError>) -> Void) {
        let decoder: JSONDecoder = .decapitalisingFirstLetter
        let session = getSession()
        let url = doh.getCurrentlyUsedHostUrl() + request.path
        do {
            let request = try createRequest(
                url: url, method: request.method, parameters: request.parameters, nonDefaultTimeout: nil,
                headers: request.header, UID: nil, accessToken: nil)
            session?.request(with: request, jsonDecoder: decoder) { (task, res: Result<T, SessionResponseError>) in
                switch res {
                case .success(let decodable):
                    result(task, .success(decodable))
                case .failure(let sessionResponseError):
                    let error = sessionResponseError.underlyingError
                    result(nil, .failure(error))
                }
            }
        } catch let error {
            result(nil, .failure(error as NSError))
        }
    }
}
