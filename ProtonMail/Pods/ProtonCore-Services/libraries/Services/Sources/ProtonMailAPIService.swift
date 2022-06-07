//
//  ProtonMailAPIService.swift
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

// swiftlint:disable identifier_name type_body_length cyclomatic_complexity function_body_length force_try function_parameter_count todo

import Foundation
import ProtonCore_Doh
import ProtonCore_Log
import ProtonCore_Networking
import ProtonCore_Utilities

#if canImport(TrustKit)
import TrustKit
#endif

public protocol TrustKitProvider {
    var noTrustKit: Bool { get }
    var trustKit: TrustKit? { get }
}

public protocol URLCacheInterface {
    func removeAllCachedResponses()
}

extension URLCache: URLCacheInterface {}

public enum PMAPIServiceTrustKitProviderWrapper: TrustKitProvider {
    case instance
    public var noTrustKit: Bool { PMAPIService.noTrustKit }
    public var trustKit: TrustKit? { PMAPIService.trustKit }
}

// Proton mail api serivce. all the network requestion must go with this.
public class PMAPIService: APIService {
    /// ForceUpgradeDelegate
    public weak var forceUpgradeDelegate: ForceUpgradeDelegate?
    
    /// HumanVerifyDelegate
    public weak var humanDelegate: HumanVerifyDelegate?
    
    /// AuthDelegate
    public weak var authDelegate: AuthDelegate?
    
    ///
    public weak var serviceDelegate: APIServiceDelegate?
    
    public static var noTrustKit: Bool = false
    public static var trustKit: TrustKit?
    
    private let hvDispatchGroup = DispatchGroup()
    
    /// the session ID. this can be changed
    public var sessionUID: String = ""
    
    /// doh with service config
    public var doh: DoH & ServerConfig
    
    public var signUpDomain: String {
        return self.doh.getSignUpString()
    }
    
    /// api session manager
    private var session: Session
    
    // get session
    public func getSession() -> Session? {
        return session
    }
    
    private var isHumanVerifyUIPresented = false
    private var isForceUpgradeUIPresented = false
    
    var tokenExpired = false

    let fetchAuthCredentialsAsyncQueue = DispatchQueue(label: "ch.proton.api.credential_fetch_async", qos: .userInitiated)
    let fetchAuthCredentialsSyncSerialQueue = DispatchQueue(label: "ch.proton.api.credential_fetch_sync", qos: .userInitiated)
    let tokenQueue = DispatchQueue(label: "ch.proton.api.token_management", qos: .userInitiated)
    let fetchAuthCredentialCompletionBlockBackgroundQueue = DispatchQueue(
        label: "ch.proton.api.refresh_completion", qos: .userInitiated, attributes: [.concurrent]
    )

    func tokenExpire() -> Bool {
        tokenQueue.sync {
            let ret = self.tokenExpired
            if ret == false {
                self.tokenExpired = true
            }
            return ret
        }
    }
    func tokenReset() {
        tokenQueue.sync {
            self.tokenExpired = false
        }
    }
    
    // MARK: - Internal methods
    /// by default will create a non auth api service. after calling the auth function, it will set the session. then use the delation to fetch the auth data  for this session.
    public required init(doh: DoH & ServerConfig,
                         sessionUID: String = "",
                         sessionFactory: SessionFactoryInterface = SessionFactory.instance,
                         cacheToClear: URLCacheInterface = URLCache.shared,
                         trustKitProvider: TrustKitProvider = PMAPIServiceTrustKitProviderWrapper.instance) {
        self.doh = doh
        
        self.sessionUID = sessionUID
        
        // clear all response cache
        cacheToClear.removeAllCachedResponses()
        
        let apiHostUrl = self.doh.getCurrentlyUsedHostUrl()
        self.session = sessionFactory.createSessionInstance(url: apiHostUrl)
        
        self.session.setChallenge(noTrustKit: trustKitProvider.noTrustKit, trustKit: trustKitProvider.trustKit)
        
        doh.setUpCookieSynchronization(storage: self.session.sessionConfiguration.httpCookieStorage)
    }
    
    public func setSessionUID(uid: String) {
        self.sessionUID = uid
    }
    
    internal typealias AuthTokenBlock = (_ accessToken: String?, _ sessionID: String?, _ error: NSError?) -> Void
    
    internal func fetchAuthCredential(_ completion: @escaping AuthTokenBlock) {
        // This was changed to avoid use of pthread_mutex_t, since this object is passed around (and
        // thus goes against Swift's runtime guarantees for mutexes). Code was modified to use dispatch
        // queues instead, while mirroring the previous threading behavior.
        fetchAuthCredentialsAsyncQueue.async {
            self.fetchAuthCredentialSync(completion)
        }
    }
    
    internal func fetchAuthCredentialSync(_ completion: @escaping AuthTokenBlock) {
        fetchAuthCredentialsSyncSerialQueue.sync {
            let group = DispatchGroup()
            group.enter()
            fetchAuthCredentialNoSync(continuation: {
                group.leave()
            }, completion: completion)
            group.wait()
        }
    }
    
    internal func fetchAuthCredentialNoSync(continuation: @escaping () -> Void, completion: @escaping AuthTokenBlock) {
        let bg = fetchAuthCredentialCompletionBlockBackgroundQueue
        let main = DispatchQueue.main

        guard let delegate = self.authDelegate else {
            bg.async {
                continuation()
                completion(nil, nil, NSError(domain: "AuthDelegate is required", code: 0, userInfo: nil))
            }
            return
        }

        let authCredential = delegate.getToken(bySessionUID: self.sessionUID)
        guard let credential = authCredential else {
            bg.async {
                continuation()
                completion(nil, nil, NSError(domain: "Empty token", code: 0, userInfo: nil))
            }
            return
        }
        
        // if credentials are fresh, complete
        if credential.isExpired == false {
            bg.async {
                // renew
                self.tokenReset()
                continuation()
                completion(credential.accessToken, self.sessionUID.isEmpty ? credential.sessionID : self.sessionUID, nil)
            }
            return
        }
        
        // when local credential expired, should handle the case same as api reuqest error handling
        self.authDelegate?.onRefresh(bySessionUID: self.sessionUID) { newCredential, error in
            self.debugError(error)
            
            if case .networkingError(let responseError) = error,
               // according to documentation 422 indicates expired refresh token and 400 indicates invalid refresh token
               // both situations should result in user logout
               responseError.httpCode == 422 || responseError.httpCode == 400 {
                main.async {
                    let sessionUID = self.sessionUID.isEmpty ? credential.sessionID : self.sessionUID
                    completion(nil, sessionUID, responseError.underlyingError)
                    self.authDelegate?.onLogout(sessionUID: sessionUID)
                    // this is the only place in which we wait with the continuation until after the completion block call
                    // the reason being we want to call completion after the delegate call
                    // and in all the places in this service we call completion block before `onLogout` delegate method
                    continuation()
                }
                
            } else if case .networkingError(let responseError) = error,
                      let underlyingError = responseError.underlyingError,
                      underlyingError.code == APIErrorCode.AuthErrorCode.localCacheBad {
                continuation()
                self.fetchAuthCredential(completion)
                
            } else {
                if let credential = newCredential {
                    self.authDelegate?.onUpdate(auth: credential)
                }
                bg.async {
                    self.tokenReset()
                    main.async {
                        continuation()
                        completion(newCredential?.accessToken,
                                   self.sessionUID.isEmpty ? credential.sessionID : self.sessionUID,
                                   error?.underlyingError)
                    }
                }
            }
        }
    }
    
    internal func expireCredential() {
        guard self.tokenExpire() == false else {
            return
        }

        fetchAuthCredentialsSyncSerialQueue.sync {
            guard let authCredential = self.authDelegate?.getToken(bySessionUID: self.sessionUID) else {
                PMLog.debug("token is empty")
                return
            }

            // TODO:: fix me.  to aline the auth framwork Credential object with Networking Credential object
            authCredential.expire()
            self.authDelegate?.onUpdate(auth: Credential( authCredential))
        }
    }
    
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
        let authBlock: AuthTokenBlock = { [self] token, userID, error in
            if let error = error {
                self.debugError(error)
                completion?(nil, nil, error)
            } else {
                let parseBlock: (_ task: URLSessionDataTask?, _ response: Any?, _ error: Error?) -> Void = { task, response, error in
                    if let error = error as NSError? {
                        self.debugError(error)
                        // PMLog.D(api: error)
                        var httpCode: Int = 200
                        if let detail = task?.response as? HTTPURLResponse {
                            httpCode = detail.statusCode
                        } else {
                            httpCode = error.code
                        }
                        
                        if authenticated && httpCode == 401 && authRetry {
                            if customAuthCredential == nil {
                                self.expireCredential()
                            }
                            if path.isRefreshPath { // tempery no need later
                                completion?(task, nil, error)
                                self.authDelegate?.onLogout(sessionUID: self.sessionUID)
                            } else {
                                if authRetryRemains > 0 {
                                    self.request(method: method,
                                                 path: path,
                                                 parameters: parameters,
                                                 headers: [:],
                                                 authenticated: authenticated,
                                                 authRetryRemains: authRetryRemains - 1,
                                                 customAuthCredential: customAuthCredential,
                                                 nonDefaultTimeout: nonDefaultTimeout,
                                                 completion: completion)
                                } else {
                                    completion?(task, nil, error)
                                    self.authDelegate?.onLogout(sessionUID: self.sessionUID)
                                    // NotificationCenter.default.post(name: .didReovke, object: nil, userInfo: ["uid": userID ?? ""])
                                }
                            }
                        } else if authenticated && (httpCode == 422 || httpCode == 400) && authRetry && path.isRefreshPath {
                            completion?(task, nil, error)
                            self.authDelegate?.onLogout(sessionUID: self.sessionUID)
                        } else if let responseDict = response as? [String: Any], let responseCode = responseDict["Code"] as? Int {
                            let errorMessage = responseDict["Error"] as? String ?? ""
                            let displayError: NSError = NSError.protonMailError(responseCode,
                                                                                localizedDescription: errorMessage,
                                                                                localizedFailureReason: errorMessage,
                                                                                localizedRecoverySuggestion: nil)
                            if responseCode == APIErrorCode.humanVerificationRequired {
                                // human verification required
                                self.humanVerificationHandler(method: method,
                                                              path: path,
                                                              parameters: parameters,
                                                              headers: headers,
                                                              authenticated: authenticated,
                                                              authRetry: authRetry,
                                                              authRetryRemains: authRetryRemains,
                                                              customAuthCredential: customAuthCredential,
                                                              nonDefaultTimeout: nonDefaultTimeout,
                                                              error: displayError,
                                                              response: response,
                                                              task: task,
                                                              responseDict: responseDict,
                                                              completion: completion)
                            } else if responseCode == APIErrorCode.badAppVersion || responseCode == APIErrorCode.badApiVersion {
                                self.forceUpgradeHandler(responseDictionary: responseDict)
                                completion?(task, responseDict, displayError)
                            } else if responseCode == APIErrorCode.API_offline {
                                completion?(task, responseDict, displayError)
                            } else {
                                completion?(task, responseDict, displayError)
                            }
                        } else {
                            completion?(task, nil, error)
                        }
                    } else {
                        if response == nil {
                            completion?(task, [:], nil)
                        } else if let responseDictionary = response as? [String: Any],
                                  let responseCode = responseDictionary["Code"] as? Int {
                            var error: NSError?
                            if responseCode != 1000 && responseCode != 1001 {
                                let errorMessage = responseDictionary["Error"] as? String
                                error = NSError.protonMailError(responseCode,
                                                                localizedDescription: errorMessage ?? "",
                                                                localizedFailureReason: errorMessage,
                                                                localizedRecoverySuggestion: nil)
                            }
                            
                            if authenticated && responseCode == 401 {
                                if token == nil {
                                    //                                    Analytics.shared.debug(message: .logout, extra: [
                                    //                                        "EmptyToken": true,
                                    //                                        "Path": path
                                    //                                    ])
                                }
                                if customAuthCredential == nil {
                                    self.expireCredential()
                                }
                                if path.contains("\(self.doh.defaultHost)/refresh") { // tempery no need later
                                    completion?(task, nil, error)
                                    self.authDelegate?.onLogout(sessionUID: self.sessionUID)
                                } else {
                                    if authRetryRemains > 0 {
                                        self.request(method: method,
                                                     path: path,
                                                     parameters: parameters,
                                                     headers: headers,
                                                     authenticated: authenticated,
                                                     authRetryRemains: authRetryRemains - 1,
                                                     customAuthCredential: customAuthCredential,
                                                     nonDefaultTimeout: nonDefaultTimeout,
                                                     completion: completion)
                                    } else {
                                        completion?(task, nil, error)
                                        self.authDelegate?.onLogout(sessionUID: self.sessionUID)
                                        // NotificationCenter.default.post(name: .didReovke, object: nil, userInfo: ["uid": userID ?? ""])
                                    }
                                }
                            } else if responseCode == APIErrorCode.humanVerificationRequired, let error = error {
                                // human verification required
                                self.humanVerificationHandler(method: method,
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
                                                              responseDict: responseDictionary,
                                                              completion: completion)
                            } else if responseCode == APIErrorCode.badAppVersion || responseCode == APIErrorCode.badApiVersion {
                                self.forceUpgradeHandler(responseDictionary: responseDictionary)
                                completion?(task, responseDictionary, error)
                            } else if responseCode == APIErrorCode.API_offline {
                                completion?(task, responseDictionary, error)
                            } else {
                                completion?(task, responseDictionary, error)
                            }
                            self.debugError(error)
                        } else {
                            let err = NSError(domain: "unable to parse response", code: 0, userInfo: nil)
                            self.debugError(err)
                            completion?(task, nil, err)
                        }
                    }
                }
                
                let url = self.doh.getCurrentlyUsedHostUrl() + path
                
                do {
                    let accessToken = token ?? ""
                    if authenticated && accessToken.isEmpty {
                        let localerror = NSError.protonMailError(401,
                                                                 localizedDescription: "The request failed, invalid access token.",
                                                                 localizedFailureReason: "The request failed, invalid access token.",
                                                                 localizedRecoverySuggestion: nil)
                        completion?(nil, nil, localerror)
                        return
                    }
                    
                    let request = try self.createRequest(
                        url: url, method: method, parameters: parameters, nonDefaultTimeout: nonDefaultTimeout,
                        headers: headers, userID: userID, accessToken: accessToken
                    )
                    
                    try self.session.request(with: request) { task, res, originalError in
                        var error = originalError
                        self.debug(task, res, originalError)
                        self.updateServerTime(task?.response)
                        
                        if let tlsErrorDescription = self.session.failsTLS(request: request) {
                            error = NSError.protonMailError(APIErrorCode.tls, localizedDescription: tlsErrorDescription)
                        }
                        self.doh.handleErrorResolvingProxyDomainAndSynchronizingCookiesIfNeeded(
                            host: url, sessionId: userID, response: task?.response, error: error) { shouldRetry in
                            guard shouldRetry else {
                                if self.doh.errorIndicatesDoHSolvableProblem(error: error) {
                                    self.serviceDelegate?.onDohTroubleshot()
                                }
                                parseBlock(task, res, error)
                                return
                            }
                            // retry. will use the proxy domain automatically if it was successfully fetched
                            self.request(method: method,
                                         path: path,
                                         parameters: parameters,
                                         headers: headers,
                                         authenticated: authenticated,
                                         authRetry: authRetry,
                                         authRetryRemains: authRetryRemains,
                                         customAuthCredential: customAuthCredential,
                                         nonDefaultTimeout: nonDefaultTimeout,
                                         completion: completion)
                        }
                    }
                } catch let error {
                    completion?(nil, nil, error as NSError)
                }
            }
        }
        
        if authenticated && customAuthCredential == nil {
            fetchAuthCredential(authBlock)
        } else {
            authBlock(customAuthCredential?.accessToken, customAuthCredential?.sessionID, nil)
        }
    }
    
    public func upload(byPath path: String,
                       parameters: [String: String],
                       keyPackets: Data,
                       dataPacket: Data,
                       signature: Data?,
                       headers: [String: Any]?,
                       authenticated: Bool = true,
                       customAuthCredential: AuthCredential? = nil,
                       nonDefaultTimeout: TimeInterval?,
                       completion: @escaping CompletionBlock) {
        
        let url = self.doh.getCurrentlyUsedHostUrl() + path
        let authBlock: AuthTokenBlock = { token, userID, error in
            if let error = error {
                self.debugError(error)
                completion(nil, nil, error)
            } else {
                
                do {
                    let accessToken = token ?? ""
                    if authenticated && accessToken.isEmpty {
                        let localerror = NSError.protonMailError(401,
                                                                 localizedDescription: "The upload request failed, invalid access token.",
                                                                 localizedFailureReason: "The upload request failed, invalid access token.",
                                                                 localizedRecoverySuggestion: nil)
                        return completion(nil, nil, localerror)
                    }
                    
                    let request = try self.createRequest(
                        url: url, method: .post, parameters: parameters, nonDefaultTimeout: nonDefaultTimeout,
                        headers: headers, userID: userID, accessToken: accessToken
                    )
                    
                    try self.session.upload(with: request,
                                            keyPacket: keyPackets, dataPacket: dataPacket,
                                            signature: signature) { task, res, error in
                        self.debugError(error)
                        self.updateServerTime(task?.response)
                        
                        // reachability temporarily failed because was switching from WiFi to Cellular
                        if (error as NSError?)?.code == -1005,
                           self.serviceDelegate?.isReachable() == true {
                            // retry task asynchonously
                            DispatchQueue.global(qos: .utility).async {
                                self.upload(byPath: url,
                                            parameters: parameters,
                                            keyPackets: keyPackets,
                                            dataPacket: dataPacket,
                                            signature: signature,
                                            headers: headers,
                                            authenticated: authenticated,
                                            customAuthCredential: customAuthCredential,
                                            completion: completion)
                            }
                            return
                        }
                        let resObject = res as? [String: Any]
                        completion(task, resObject, error as NSError?)
                    }
                } catch let error {
                    completion(nil, nil, error as NSError)
                }
            }
        }
        
        if authenticated && customAuthCredential == nil {
            fetchAuthCredential(authBlock)
        } else {
            authBlock(customAuthCredential?.accessToken, customAuthCredential?.sessionID, nil)
        }
    }
    
    public func upload(byPath path: String,
                       parameters: Any?,
                       files: [String: URL],
                       headers: [String: Any]?,
                       authenticated: Bool,
                       customAuthCredential: AuthCredential?,
                       nonDefaultTimeout: TimeInterval?,
                       uploadProgress: ProgressCompletion?,
                       completion: @escaping CompletionBlock) {
        let url = self.doh.getCurrentlyUsedHostUrl() + path
        let authBlock: AuthTokenBlock = { token, userID, error in
            if let error = error {
                self.debugError(error)
                completion(nil, nil, error)
            } else {
                
                do {
                    let accessToken = token ?? ""
                    if authenticated && accessToken.isEmpty {
                        let localerror = NSError.protonMailError(401,
                                                                 localizedDescription: "The upload request failed, invalid access token.",
                                                                 localizedFailureReason: "The upload request failed, invalid access token.",
                                                                 localizedRecoverySuggestion: nil)
                        return completion(nil, nil, localerror)
                    }
                    
                    let request = try self.createRequest(
                        url: url, method: .post, parameters: parameters, nonDefaultTimeout: nonDefaultTimeout,
                        headers: headers, userID: userID, accessToken: accessToken
                    )
                    
                    try self.session.upload(with: request, files: files, completion: { task, res, error in
                        self.debugError(error)
                        self.updateServerTime(task?.response)
                        
                        // reachability temporarily failed because was switching from WiFi to Cellular
                        if (error as NSError?)?.code == -1005,
                           self.serviceDelegate?.isReachable() == true {
                            // retry task asynchonously
                            DispatchQueue.global(qos: .utility).async {
                                self.upload(byPath: url,
                                            parameters: parameters,
                                            files: files,
                                            headers: headers,
                                            authenticated: authenticated,
                                            customAuthCredential: customAuthCredential,
                                            uploadProgress: uploadProgress,
                                            completion: completion)
                            }
                            return
                        }
                        let resObject = res as? [String: Any]
                        completion(task, resObject, error as NSError?)
                    }, uploadProgress: uploadProgress)
                } catch let error {
                    completion(nil, nil, error as NSError)
                }
            }
        }
        
        if authenticated && customAuthCredential == nil {
            fetchAuthCredential(authBlock)
        } else {
            authBlock(customAuthCredential?.accessToken, customAuthCredential?.sessionID, nil)
        }
    }
    
    public func uploadFromFile(byPath path: String,
                               parameters: [String: String],
                               keyPackets: Data,
                               dataPacketSourceFileURL: URL,
                               signature: Data?,
                               headers: [String: Any]?,
                               authenticated: Bool = true,
                               customAuthCredential: AuthCredential? = nil,
                               nonDefaultTimeout: TimeInterval?,
                               completion: @escaping CompletionBlock) {
        
        let url = self.doh.getCurrentlyUsedHostUrl() + path
        let authBlock: AuthTokenBlock = { token, userID, error in
            if let error = error {
                self.debugError(error)
                completion(nil, nil, error)
            } else {
                
                do {
                    let accessToken = token ?? ""
                    if authenticated && accessToken.isEmpty {
                        let localerror = NSError.protonMailError(401,
                                                                 localizedDescription: "The upload request failed, invalid access token.",
                                                                 localizedFailureReason: "The upload request failed, invalid access token.",
                                                                 localizedRecoverySuggestion: nil)
                        return completion(nil, nil, localerror)
                    }
                    
                    let request = try self.createRequest(
                        url: url, method: .post, parameters: parameters, nonDefaultTimeout: nonDefaultTimeout,
                        headers: headers, userID: userID, accessToken: accessToken
                    )
                    
                    try self.session.uploadFromFile(with: request,
                                                    keyPacket: keyPackets, dataPacketSourceFileURL: dataPacketSourceFileURL,
                                                    signature: signature) { task, res, error in
                        self.debugError(error)
                        self.updateServerTime(task?.response)
                        
                        // reachability temporarily failed because was switching from WiFi to Cellular
                        if (error as NSError?)?.code == -1005,
                           self.serviceDelegate?.isReachable() == true {
                            // retry task asynchonously
                            DispatchQueue.global(qos: .utility).async {
                                self.uploadFromFile(byPath: url,
                                                    parameters: parameters,
                                                    keyPackets: keyPackets,
                                                    dataPacketSourceFileURL: dataPacketSourceFileURL,
                                                    signature: signature,
                                                    headers: headers,
                                                    authenticated: authenticated,
                                                    customAuthCredential: customAuthCredential,
                                                    completion: completion)
                            }
                            return
                        }
                        let resObject = res as? [String: Any]
                        completion(task, resObject, error as NSError?)
                    }
                } catch let error {
                    completion(nil, nil, error as NSError)
                }
            }
        }
        
        if authenticated && customAuthCredential == nil {
            fetchAuthCredential(authBlock)
        } else {
            authBlock(customAuthCredential?.accessToken, customAuthCredential?.sessionID, nil)
        }
    }

    public func download(byUrl url: String,
                         destinationDirectoryURL: URL,
                         headers: [String: Any]?,
                         authenticated: Bool = true,
                         customAuthCredential: AuthCredential? = nil,
                         nonDefaultTimeout: TimeInterval?,
                         downloadTask: ((URLSessionDownloadTask) -> Void)?,
                         completion: @escaping ((URLResponse?, URL?, NSError?) -> Void)) {
        let authBlock: AuthTokenBlock = { token, userID, error in
            if let error = error {
                self.debugError(error)
                completion(nil, nil, error)
            } else {
                do {
                    let accessToken = token ?? ""
                    if authenticated && accessToken.isEmpty {
                        let localerror = NSError.protonMailError(401,
                                                                 localizedDescription: "The download request failed, invalid access token.",
                                                                 localizedFailureReason: "The download request failed, invalid access token.",
                                                                 localizedRecoverySuggestion: nil)
                        completion(nil, nil, localerror)
                        return
                    }
                    
                    let request = try self.createRequest(
                        url: url, method: .get, parameters: nil, nonDefaultTimeout: nonDefaultTimeout,
                        headers: headers, userID: userID, accessToken: accessToken
                    )
                    
                    try self.session.download(with: request, destinationDirectoryURL: destinationDirectoryURL) { response, url, error in
                        completion(response, url, error)
                    }
                } catch let error {
                    completion(nil, nil, error as NSError)
                }
            }
        }
        
        if authenticated && customAuthCredential == nil {
            fetchAuthCredential(authBlock)
        } else {
            authBlock(customAuthCredential?.accessToken, customAuthCredential?.sessionID, nil)
        }
    }
    
    private func createRequest(url: String,
                               method: HTTPMethod,
                               parameters: Any?,
                               nonDefaultTimeout: TimeInterval?,
                               headers: [String: Any]?,
                               userID: String?,
                               accessToken: String) throws -> SessionRequest {
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
        
        if !accessToken.isEmpty {
            request.setValue(header: "Authorization", "Bearer \(accessToken)")
        }
        
        if let userid = userID {
            request.setValue(header: "x-pm-uid", userid)
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
        
        var ua = UserAgent.default.ua
        if let delegateAgent = serviceDelegate?.userAgent, !delegateAgent.isEmpty {
            ua = delegateAgent
        }
        request.setValue(header: "User-Agent", ua)
        
        return request
    }
    
    private func updateServerTime(_ response: URLResponse?) {
        if let urlres = response as? HTTPURLResponse,
           let allheader = urlres.allHeaderFields as? [String: Any],
           let strData = allheader["Date"] as? String,
           let date = DateParser.parse(time: strData) {
            let timeInterval = date.timeIntervalSince1970
            self.serviceDelegate?.onUpdate(serverTime: Int64(timeInterval))
        }
    }
    
    func debug(_ task: URLSessionTask?, _ response: Any?, _ error: NSError?) {
        #if DEBUG
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
        #if DEBUG
        if let error = error {
            PMLog.debug("""
                        
                        [ERROR]
                        code: \(error.bestShotAtReasonableErrorCode)
                        message: \(error.messageForTheUser)
                        """)
        }
        #endif
    }
    
    private func humanVerificationHandler(method: HTTPMethod,
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
        
        // return completion if humanDelegate in not present
        if self.humanDelegate == nil {
            completion?(task, responseDict, error)
            return
        }
        
        // human verification required
        if self.isHumanVerifyUIPresented == true {
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
        self.isHumanVerifyUIPresented = true
        
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
                        if self.isHumanVerifyUIPresented {
                            self.isHumanVerifyUIPresented = false
                            self.hvDispatchGroup.leave()
                        }
                        
                    case .closeWithError(let code, let description):
                        // finish request with existing completion block
                        var newResponse: [String: Any] = responseDict
                        newResponse["Error"] = description
                        newResponse["Code"] = code
                        completion?(task, newResponse, error)
                        if self.isHumanVerifyUIPresented {
                            self.isHumanVerifyUIPresented = false
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
                        if self.isHumanVerifyUIPresented {
                            self.isHumanVerifyUIPresented = false
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
    
    private func forceUpgradeHandler(responseDictionary: [String: Any]) {
        let errorMessage = responseDictionary["Error"] as? String ?? ""
        if let delegate = forceUpgradeDelegate, isForceUpgradeUIPresented == false {
            isForceUpgradeUIPresented = true
            DispatchQueue.main.async {
                delegate.onForceUpgrade(message: errorMessage)
            }
        }
    }
}

extension String {
    var isRefreshPath: Bool {
        return self.contains("/auth/refresh")
    }
}
