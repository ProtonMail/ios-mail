//
//  ProtonMailAPIService.swift
//  ProtonMail - Created on 5/22/20.
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

// swiftlint:disable identifier_name type_body_length cyclomatic_complexity function_body_length force_try function_parameter_count todo

import Foundation
// REMOVE the networking ref
import AFNetworking
import ProtonCore_Doh
import ProtonCore_Log
import ProtonCore_Networking

#if canImport(TrustKit)
import TrustKit
#endif

public class APIErrorCode {
    public static let responseOK = 1000

    public static let HTTP503 = 503
    public static let HTTP504 = 504
    public static let HTTP404 = 404

    public static let badParameter = 1
    public static let badPath = 2
    public static let unableToParseResponse = 3
    public static let badResponse = 4

    public struct AuthErrorCode {
        public static let credentialExpired = 10
        public static let credentialInvalid = 20
        public static let invalidGrant = 30
        public static let unableToParseToken = 40
        public static let localCacheBad = 50
        public static let networkIusse = -1004
        public static let unableToParseAuthInfo = 70
        public static let authServerSRPInValid = 80
        public static let authUnableToGenerateSRP = 90
        public static let authUnableToGeneratePwd = 100
        public static let authInValidKeySalt = 110

        public static let authCacheLocked = 665

        public static let Cache_PasswordEmpty = 0x10000001
    }

    public static let API_offline = 7001

    public struct UserErrorCode {
        public static let userNameExsit = 12011
        public static let currentWrong = 12021
        public static let newNotMatch = 12022
        public static let pwdUpdateFailed = 12023
        public static let pwdEmpty = 12024
    }

    public static let badAppVersion = 5003
    public static let badApiVersion = 5005
    public static let humanVerificationRequired = 9001
    public static let invalidVerificationCode = 12087
    public static let tooManyVerificationCodes = 12214
    public static let tooManyFailedVerificationAttempts = 85131
}

// This need move to a common framwork
public extension NSError {

    convenience init(domain: String, code: Int, localizedDescription: String, localizedFailureReason: String? = nil, localizedRecoverySuggestion: String? = nil) {
        var userInfo = [NSLocalizedDescriptionKey: localizedDescription]

        if let localizedFailureReason = localizedFailureReason {
            userInfo[NSLocalizedFailureReasonErrorKey] = localizedFailureReason
        }

        if let localizedRecoverySuggestion = localizedRecoverySuggestion {
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = localizedRecoverySuggestion
        }

        self.init(domain: domain, code: code, userInfo: userInfo)
    }

    class func protonMailError(_ code: Int, localizedDescription: String, localizedFailureReason: String? = nil, localizedRecoverySuggestion: String? = nil) -> NSError {
        return NSError(domain: protonMailErrorDomain(), code: code, localizedDescription: localizedDescription, localizedFailureReason: localizedFailureReason, localizedRecoverySuggestion: localizedRecoverySuggestion)
    }

    class func protonMailErrorDomain(_ subdomain: String? = nil) -> String {
        var domain = Bundle.main.bundleIdentifier ?? "ch.protonmail"

        if let subdomain = subdomain {
            domain += ".\(subdomain)"
        }
        return domain
    }

    func getCode() -> Int {
        var defaultCode: Int = code
        if defaultCode == Int.max {
            if let detail = self.userInfo["com.alamofire.serialization.response.error.response"] as? HTTPURLResponse {
                defaultCode = detail.statusCode
            }
        }
        return defaultCode
    }

    func isInternetError() -> Bool {
        var isInternetIssue = false
        if self.userInfo ["com.alamofire.serialization.response.error.response"] as? HTTPURLResponse != nil {
        } else {
            //                        if(error?.code == -1001) {
            //                            // request timed out
            //                        }
            if self.code == -1009 || self.code == -1004 || self.code == -1001 { // internet issue
                isInternetIssue = true
            }
        }
        return isInternetIssue
    }

}

final class UserAgent {
    public static let `default` : UserAgent = UserAgent()

    private var cachedUS: String?
    private init () { }

    // eg. Darwin/16.3.0
    private func DarwinVersion() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        if let dv = String(bytes: Data(bytes: &sysinfo.release, count: Int(_SYS_NAMELEN)), encoding: .ascii) {
            let ndv = dv.trimmingCharacters(in: .controlCharacters)
            return "Darwin/\(ndv)"
        }
        return ""
    }
    // eg. CFNetwork/808.3
    private func CFNetworkVersion() -> String {
        let dictionary = Bundle(identifier: "com.apple.CFNetwork")?.infoDictionary
        let version = dictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        return "CFNetwork/\(version)"
    }

    // eg. iOS/10_1
    private func deviceVersion() -> String {
        #if canImport(UIKit)
        let currentDevice = UIDevice.current
        return "\(currentDevice.systemName)/\(currentDevice.systemVersion)"
        #elseif canImport(AppKit)
        return "macOS/\(ProcessInfo.processInfo.operatingSystemVersionString)"
        #else
        return ""
        #endif
    }
    // eg. iPhone5,2
    private func deviceName() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        let data = Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN))
        if let dn = String(bytes: data, encoding: .ascii) {
            let ndn = dn.trimmingCharacters(in: .controlCharacters)
            return ndn
        }
        return "Unknown"
    }
    // eg. MyApp/1
    private func appNameAndVersion() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as? String ?? "Unknown"
        let name = dictionary["CFBundleName"] as? String ?? "Unknown"
        return "\(name)/\(version)"
    }

    /// Return the User agent string. the format requested by data team
    /// - Returns: UA string
    private func UAString() -> String {
        return "\(appNameAndVersion()) (\(deviceVersion()); \(deviceName()))"
    }

    var ua: String? {
        if cachedUS == nil {
            cachedUS = self.UAString()
        }
        return cachedUS
    }
}

public let APIServiceErrorDomain = NSError.protonMailErrorDomain("APIService")

extension APIService {
    public func getSession() -> AFHTTPSessionManager? {
        return nil
    }
}

// Protonmail api serivce. all the network requestion must go with this.
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

    /// synchronize locks
    private var mutex = pthread_mutex_t()
    private let hvDispatchGroup = DispatchGroup()

    //    /// the user id
    //    public var userID : String = ""

    /// the session ID. this can be changed
    public var sessionUID: String = ""

    /// doh with service config
    public var doh: DoH

    public var signUpDomain: String {
        return self.doh.getSignUpString()
    }

    /// network config
    //    let serverConfig : APIServerConfig

    /// api session manager
    private var sessionManager: AFHTTPSessionManager

    // get session
    public func getSession() -> AFHTTPSessionManager? {
        return sessionManager
    }

    /// refresh token failed count
    // public var refreshTokenFailedCount = 0

    private var isHumanVerifyUIPresented = false

    private var isForceUpgradeUIPresented = false

    var tokenExpired = false
    let serialQueue = DispatchQueue(label: "com.proton.common")
    func tokenExpire() -> Bool {
        serialQueue.sync {
            let ret = self.tokenExpired
            if ret == false {
                self.tokenExpired = true
            }
            return ret
        }
    }
    func tokenReset() {
        serialQueue.sync {
            self.tokenExpired = false
        }
    }

    //    var network : NetworkLayer
    //    var vpn : VPNInterface
    //    var doh:  DoH //depends on NetworkLayer.
    //    var queue : [Request]
    //    weak var apiServiceDelegate: APIServiceDelegate?
    //    weak var authDelegate : AuthDelegate?
    //    init(networkImpl: NetworkLayer, doh, vpn?, apiServiceDelegate?, authDelegate) {
    //        ///
    //    }

    // MARK: - Internal methods
    /// by default will create a non auth api service. after calling the auth function, it will set the session. then use the delation to fetch the auth data  for this session.
    public required init(doh: DoH, sessionUID: String = "") {
        // init lock
        pthread_mutex_init(&mutex, nil)
        self.doh = doh

        // set config
        // self.serverConfig = config
        self.sessionUID = sessionUID

        // clear all response cache
        URLCache.shared.removeAllCachedResponses()

        // ----- this part need move the networking wrapper
        let apiHostUrl = self.doh.getHostUrl() // self.serverConfig.hostUrl
        sessionManager = AFHTTPSessionManager(baseURL: URL(string: apiHostUrl)!)
        sessionManager.requestSerializer = AFJSONRequestSerializer()
        sessionManager.requestSerializer.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData  // .ReloadIgnoringCacheData
        sessionManager.requestSerializer.stringEncoding = String.Encoding.utf8.rawValue

        sessionManager.responseSerializer.acceptableContentTypes?.insert("text/html")
        sessionManager.securityPolicy.allowInvalidCertificates = false
        sessionManager.securityPolicy.validatesDomainName = false
        #if DEBUG
        sessionManager.securityPolicy.allowInvalidCertificates = true
        #endif

        if PMAPIService.noTrustKit {
            sessionManager.setSessionDidReceiveAuthenticationChallenge { _, challenge, credential -> URLSession.AuthChallengeDisposition in
                let dispositionToReturn: URLSession.AuthChallengeDisposition = .useCredential
                // Hard force to pass all connections -- this only for testing and with charles
                guard let trust = challenge.protectionSpace.serverTrust else { return dispositionToReturn }
                let credentialOut = URLCredential(trust: trust)
                credential?.pointee = credentialOut
                return dispositionToReturn
            }
        } else {
            sessionManager.setSessionDidReceiveAuthenticationChallenge { _, challenge, credential -> URLSession.AuthChallengeDisposition in
                var dispositionToReturn: URLSession.AuthChallengeDisposition = .performDefaultHandling
                if let validator = PMAPIService.trustKit?.pinningValidator {
                    validator.handle(challenge, completionHandler: { (disposition, credentialOut) in
                        credential?.pointee = credentialOut
                        dispositionToReturn = disposition
                    })
                } else {
                    assert(false, "TrustKit not initialized correctly")
                }
                return dispositionToReturn
            }
        }
    }

    private func enableDoH() {

    }

    private func disableDoH() {

    }

    public func setSessionUID(uid: String) {
        self.sessionUID = uid
    }

    internal typealias AuthTokenBlock = (String?, String?, NSError?) -> Void
    internal func fetchAuthCredential(_ completion: @escaping AuthTokenBlock) {
        // TODO:: fix me. this is wrong. concurruncy
        DispatchQueue.global(qos: .default).async {
            pthread_mutex_lock(&self.mutex)
            guard let delegate = self.authDelegate else {
                pthread_mutex_unlock(&self.mutex)
                completion(nil, nil, NSError(domain: "AuthDelegate is required", code: 0, userInfo: nil))
                return
            }
            let authCredential = delegate.getToken(bySessionUID: self.sessionUID)
            guard let credential = authCredential else {
                pthread_mutex_unlock(&self.mutex)
                completion(nil, nil, NSError(domain: "Empty token", code: 0, userInfo: nil))
                return
            }
            // when local credential expired, should handle the case same as api reuqest error handling
            guard !credential.isExpired else {
                self.authDelegate?.onRefresh(bySessionUID: self.sessionUID) { newCredential, error in
                    self.debugError(error)
                    if case .networkingError(let responseError) = error,
                       responseError.httpCode == 422 {
                        pthread_mutex_unlock(&self.mutex)
                        DispatchQueue.main.async {
                            // NSError.alertBadTokenToast()
                            completion(newCredential?.accessToken, self.sessionUID, responseError.underlyingError)
                            self.authDelegate?.onLogout(sessionUID: self.sessionUID)
                            // NotificationCenter.default.post(name: .didReovke, object: nil, userInfo: ["uid": self.sessionUID ])error
                        }
                    } else if case .networkingError(let responseError) = error,
                              let underlyingError = responseError.underlyingError,
                              underlyingError.code == APIErrorCode.AuthErrorCode.localCacheBad {
                        pthread_mutex_unlock(&self.mutex)
                        DispatchQueue.main.async {
                            // NSError.alertBadTokenToast()
                            self.fetchAuthCredential(completion)
                        }
                    } else {
                        if let credential = newCredential {
                            self.authDelegate?.onUpdate(auth: credential)
                        }
                        pthread_mutex_unlock(&self.mutex)
                        self.tokenReset()
                        DispatchQueue.main.async {
                            completion(newCredential?.accessToken, self.sessionUID, error?.underlyingError)
                        }
                    }
                }
                return
            }

            pthread_mutex_unlock(&self.mutex)
            // renew
            self.tokenReset()
            completion(credential.accessToken, self.sessionUID.isEmpty ? credential.sessionID : self.sessionUID, nil)
        }
    }

    internal func expireCredential() {

        guard self.tokenExpire() == false else {
            return
        }

        pthread_mutex_lock(&self.mutex)
        defer {
            pthread_mutex_unlock(&self.mutex)
        }
        guard let authCredential = self.authDelegate?.getToken(bySessionUID: self.sessionUID) else {
            PMLog.debug("token is empty")
            return
        }

        // TODO:: fix me.  to aline the auth framwork Credential object with Networking Credential object
        authCredential.expire()
        self.authDelegate?.onUpdate(auth: Credential( authCredential))
    }

    public func request(method: HTTPMethod, path: String,
                        parameters: Any?, headers: [String: Any]?,
                        authenticated: Bool, autoRetry: Bool, customAuthCredential: AuthCredential?, completion: CompletionBlock?) {

        self.request(method: method, path: path, parameters: parameters,
                     headers: headers, authenticated: authenticated, authRetry: autoRetry, authRetryRemains: 10,
                     customAuthCredential: customAuthCredential, completion: completion)

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
                 completion: CompletionBlock?) {
        let authBlock: AuthTokenBlock = { token, userID, error in
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
                                                 headers: [HTTPHeader.apiVersion: 3],
                                                 authenticated: authenticated,
                                                 authRetryRemains: authRetryRemains - 1,
                                                 customAuthCredential: customAuthCredential,
                                                 completion: completion)
                                } else {
                                    completion?(task, nil, error)
                                    self.authDelegate?.onLogout(sessionUID: self.sessionUID)
                                    // NotificationCenter.default.post(name: .didReovke, object: nil, userInfo: ["uid": userID ?? ""])
                                }
                            }
                        } else if authenticated && httpCode == 422 && authRetry && path.isRefreshPath {
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
                                if path.contains("https://api.protonmail.ch/refresh") { // tempery no need later
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
                                                     completion: completion)
                                    } else {
                                        completion?(task, nil, error)
                                        self.authDelegate?.onLogout(sessionUID: self.sessionUID)
                                        // NotificationCenter.default.post(name: .didReovke, object: nil, userInfo: ["uid": userID ?? ""])
                                    }
                                }
                            } else if responseCode == APIErrorCode.humanVerificationRequired {
                                // human verification required
                                self.humanVerificationHandler(method: method,
                                                              path: path,
                                                              parameters: parameters,
                                                              headers: headers,
                                                              authenticated: authenticated,
                                                              authRetry: authRetry,
                                                              authRetryRemains: authRetryRemains,
                                                              customAuthCredential: customAuthCredential,
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
                let url = self.doh.getHostUrl() + path

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

                    let request = try self.sessionManager.requestSerializer.request(withMethod: method.toString(),
                                                                                    urlString: url,
                                                                                    parameters: parameters)
                    if let header = headers {
                        for (k, v) in header {
                            request.setValue("\(v)", forHTTPHeaderField: k)
                        }
                    }
                    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                    if let userid = userID {
                        request.setValue(userid, forHTTPHeaderField: "x-pm-uid")
                    }

                    // move to delegte
                    var appversion = "iOS_\(Bundle.main.majorVersion)"
                    if let delegateAppVersion = self.serviceDelegate?.appVersion, !delegateAppVersion.isEmpty {
                        appversion = delegateAppVersion
                    }
                    request.setValue("application/vnd.protonmail.v1+json", forHTTPHeaderField: "Accept")
                    request.setValue(appversion, forHTTPHeaderField: "x-pm-appversion")

                    // todo
                    // let clanguage = LanguageManager.currentLanguageEnum()
                    // request.setValue(clanguage.localeString, forHTTPHeaderField: "x-pm-locale")

                    // move to delegte
                    var ua = UserAgent.default.ua
                    if let delegateAgent = self.serviceDelegate?.userAgent, !delegateAgent.isEmpty {
                        ua = delegateAgent
                    }
                    request.setValue(ua, forHTTPHeaderField: "User-Agent")

                    var task: URLSessionDataTask?
                    task = self.sessionManager.dataTask(with: request as URLRequest, uploadProgress: { (_) in
                        // TODO::add later

                    }, downloadProgress: { (_) in
                        // TODO::add later
                        PMLog.debug("in progress")
                    }, completionHandler: { (urlresponse, res, error) in
                        self.debugError(error)
                        if let urlres = urlresponse as? HTTPURLResponse,
                            let allheader = urlres.allHeaderFields as? [String: Any] {
                            // PMLog.D("\(allheader.json(prettyPrinted: true))")
                            if let strData = allheader["Date"] as? String {
                                // create dateFormatter with UTC time format
                                let dateFormatter = DateFormatter()
                                dateFormatter.calendar = .some(.init(identifier: .gregorian))
                                dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
                                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                                if let date = dateFormatter.date(from: strData) {
                                    let timeInterval = date.timeIntervalSince1970
                                    self.serviceDelegate?.onUpdate(serverTime: Int64(timeInterval))
                                }
                            }
                        }

                        if self.doh.handleError(host: url, error: error) {
                            // retry here
                            // PMLog.D(" DOH Retry: " + url)
                            self.request(method: method,
                                         path: path,
                                         parameters: parameters,
                                         headers: headers,
                                         authenticated: authenticated,
                                         authRetry: authRetry,
                                         authRetryRemains: authRetryRemains,
                                         customAuthCredential: customAuthCredential, completion: completion)
                        } else {
                            /// parse urlresponse
                            parseBlock(task, res, error)
                        }
                    })
                    task!.resume()

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

    public func upload (byPath path: String,
                        parameters: [String: String],
                        keyPackets: Data,
                        dataPacket: Data,
                        signature: Data?,
                        headers: [String: Any]?,
                        authenticated: Bool = true,
                        customAuthCredential: AuthCredential? = nil,
                        completion: @escaping CompletionBlock) {

        let url = self.doh.getHostUrl() + path
        let authBlock: AuthTokenBlock = { token, userID, error in
            if let error = error {
                self.debugError(error)
                completion(nil, nil, error)
            } else {

                let accessToken = token ?? ""
                if authenticated && accessToken.isEmpty {
                    let localerror = NSError.protonMailError(401,
                                                             localizedDescription: "The upload request failed, invalid access token.",
                                                             localizedFailureReason: "The upload request failed, invalid access token.",
                                                             localizedRecoverySuggestion: nil)
                    return completion(nil, nil, localerror)
                }

                let request = self.sessionManager.requestSerializer.multipartFormRequest(withMethod: "POST",
                                                                                         urlString: url, parameters: parameters,
                                                                                         constructingBodyWith: { (formData) -> Void in
                                                                                            let data: AFMultipartFormData = formData
                                                                                            data.appendPart(withFileData: keyPackets, name: "KeyPackets", fileName: "KeyPackets.txt", mimeType: "" )
                                                                                            data.appendPart(withFileData: dataPacket, name: "DataPacket", fileName: "DataPacket.txt", mimeType: "" )
                                                                                            if let sign = signature {
                                                                                                data.appendPart(withFileData: sign, name: "Signature", fileName: "Signature.txt", mimeType: "" )
                                                                                            }
                                                                                         }, error: nil)

                if let header = headers {
                    for (k, v) in header {
                        request.setValue("\(v)", forHTTPHeaderField: k)
                    }
                }
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                if let userid = userID {
                    request.setValue(userid, forHTTPHeaderField: "x-pm-uid")
                }

                let appversion = "iOS_\(Bundle.main.majorVersion)"
                request.setValue("application/vnd.protonmail.v1+json", forHTTPHeaderField: "Accept")
                request.setValue(appversion, forHTTPHeaderField: "x-pm-appversion")

                // TODO:: fix the local
                // let clanguage = LanguageManager.currentLanguageEnum()
                // request.setValue(clanguage.localeString, forHTTPHeaderField: "x-pm-locale")
                if let ua = self.serviceDelegate?.userAgent ?? UserAgent.default.ua {
                    request.setValue(ua, forHTTPHeaderField: "User-Agent")
                }

                var uploadTask: URLSessionDataTask?
                uploadTask = self.sessionManager.uploadTask(withStreamedRequest: request as URLRequest, progress: { (_) in
                    // nothing
                }, completionHandler: { (_, responseObject, error) in
                    self.debugError(error)

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

                    let resObject = responseObject as? [String: Any]
                    completion(uploadTask, resObject, error as NSError?)
                })
                uploadTask?.resume()
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
                         downloadTask: ((URLSessionDownloadTask) -> Void)?,
                         completion: @escaping ((URLResponse?, URL?, NSError?) -> Void)) {
        let authBlock: AuthTokenBlock = { token, userID, error in
            if let error = error {
                self.debugError(error)
                completion(nil, nil, error)
            } else {
                let accessToken = token ?? ""
                if authenticated && accessToken.isEmpty {
                    let localerror = NSError.protonMailError(401,
                                                             localizedDescription: "The download request failed, invalid access token.",
                                                             localizedFailureReason: "The download request failed, invalid access token.",
                                                             localizedRecoverySuggestion: nil)
                    completion(nil, nil, localerror)
                    return
                }

                let request = try! self.sessionManager.requestSerializer.request(withMethod: HTTPMethod.get.toString(),
                                                                                 urlString: url,
                                                                                 parameters: nil)
                if let header = headers {
                    for (k, v) in header {
                        request.setValue("\(v)", forHTTPHeaderField: k)
                    }
                }
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                if let userID = userID {
                    request.setValue(userID, forHTTPHeaderField: "x-pm-uid")
                }

                let appversion = "iOS_\(Bundle.main.majorVersion)"
                request.setValue("application/vnd.protonmail.v1+json", forHTTPHeaderField: "Accept")
                request.setValue(appversion, forHTTPHeaderField: "x-pm-appversion")

//                let clanguage = LanguageManager.currentLanguageEnum()
//                request.setValue(clanguage.localeString, forHTTPHeaderField: "x-pm-locale")
                if let ua = self.serviceDelegate?.userAgent ?? UserAgent.default.ua {
                    request.setValue(ua, forHTTPHeaderField: "User-Agent")
                }

                let sessionDownloadTask = self.sessionManager.downloadTask(with: request as URLRequest, progress: { (_) in

                }, destination: { (_, _) -> URL in
                    return destinationDirectoryURL
                }, completionHandler: { (response, url, error) in
                    self.debugError(error)
                    completion(response, url, error as NSError?)
                })
                downloadTask?(sessionDownloadTask)
                sessionDownloadTask.resume()
            }
        }

        if authenticated && customAuthCredential == nil {
            fetchAuthCredential(authBlock)
        } else {
            authBlock(customAuthCredential?.accessToken, customAuthCredential?.sessionID, nil)
        }
    }

    func debugError(_ error: NSError?) {
        #if DEBUG
        // nothing
        #endif
    }
    func debugError(_ error: Error?) {
        #if DEBUG
        // nothing
        #endif
    }

    func humanVerificationHandler(
        method: HTTPMethod,
        path: String,
        parameters: Any?,
        headers: [String: Any]?,
        authenticated: Bool = true,
        authRetry: Bool = true,
        authRetryRemains: Int = 3,
        customAuthCredential: AuthCredential? = nil,
        error: NSError?,
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
                                          error: error,
                                          response: response,
                                          task: task,
                                          responseDict: responseDict,
                                          completion: completion)
        }
    }

    func humanVerificationUIHandler(
        method: HTTPMethod,
        path: String,
        parameters: Any?,
        headers: [String: Any]?,
        authenticated: Bool = true,
        authRetry: Bool = true,
        authRetryRemains: Int = 3,
        customAuthCredential: AuthCredential? = nil,
        error: NSError?,
        response: Any?,
        task: URLSessionDataTask?,
        responseDict: [String: Any],
        completion: CompletionBlock?) {

        // get human verification methods
        let (hvResponse, _) = Response.parseNetworkCallResults(
            to: HumanVerificationResponse.self, response: task?.response, responseDict: responseDict, error: error
        )
        if let response = response as? [String: Any] {
            _ = hvResponse.ParseResponse(response)
        }
        self.isHumanVerifyUIPresented = true

        // human verification required delegate
        DispatchQueue.global(qos: .default).async {
            self.hvDispatchGroup.enter()
            DispatchQueue.main.async {
                self.humanDelegate?.onHumanVerify(methods: hvResponse.supported, startToken: hvResponse.startToken) { header, isClosed, verificationCodeBlock in

                    // close human verification UI
                    if isClosed {
                        // finish request with existing completion block
                        completion?(task, responseDict, error)
                        self.isHumanVerifyUIPresented = false
                        self.hvDispatchGroup.leave()
                        return
                    }

                    // human verification completion
                    let hvCompletion: CompletionBlock = { task, response, error in
                        if let error = error, self.invalidHVCodes.first(where: { error.code == $0 }) != nil {
                            let responseError = ResponseError(httpCode: (task?.response as? HTTPURLResponse)?.statusCode,
                                                              responseCode: response?["Code"] as? Int,
                                                              userFacingMessage: response?["Error"] as? String,
                                                              underlyingError: error)
                            verificationCodeBlock?(false, responseError, nil)
                        } else {
                            verificationCodeBlock?(true, nil) {
                                // finish request with new completion block
                                completion?(task, response, error)
                                self.isHumanVerifyUIPresented = false
                                self.hvDispatchGroup.leave()
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
                                 completion: hvCompletion)
                }
            }
        }
    }

    var invalidHVCodes: [Int] {
        return [APIErrorCode.invalidVerificationCode,
                APIErrorCode.tooManyVerificationCodes,
                APIErrorCode.tooManyFailedVerificationAttempts]
    }

    func forceUpgradeHandler(responseDictionary: [String: Any]) {
        let errorMessage = responseDictionary["Error"] as? String ?? ""
        if let delegate = forceUpgradeDelegate, isForceUpgradeUIPresented == false {
            isForceUpgradeUIPresented = true
            delegate.onForceUpgrade(message: errorMessage)
        }
    }

}

extension String {
    var isRefreshPath: Bool {
        return self.contains("/auth/refresh")
    }
}
