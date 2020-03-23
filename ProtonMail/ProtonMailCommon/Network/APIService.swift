//
//  APIService.swift
//  ProtonMail
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


import CoreData
import Foundation
import AFNetworking
import AFNetworkActivityLogger
import TrustKit
import PMNetworking

let APIServiceErrorDomain = NSError.protonMailErrorDomain("APIService")

protocol APIServiceDelegate: class {
    func onError(error: NSError)
    func isReachable() -> Bool
}

let sharedAPIService = APIService()
class APIService {
    // refresh token failed count
    internal var refreshTokenFailedCount = 0
    
    // synchronize lock
    internal var mutex = pthread_mutex_t()
    
    // api session manager
    fileprivate var sessionManager: AFHTTPSessionManager
    
    // get session
    func getSession() -> AFHTTPSessionManager{
        return sessionManager;
    }
    
    weak var delegate : APIServiceDelegate?
    
    let doh : DoH = DoHMail.default
    
    // MARK: - Internal methods
    
    init() {
        doh.status = userCachedStatus.isDohOn ? .on : .off
        
        // init lock
        pthread_mutex_init(&mutex, nil)
        URLCache.shared.removeAllCachedResponses()
        
        sessionManager = AFHTTPSessionManager(baseURL: URL(string: doh.getHostUrl())!)
        sessionManager.requestSerializer = AFJSONRequestSerializer()
        sessionManager.requestSerializer.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData  //.ReloadIgnoringCacheData
        sessionManager.requestSerializer.stringEncoding = String.Encoding.utf8.rawValue
        
        sessionManager.responseSerializer.acceptableContentTypes?.insert("text/html")
        
        sessionManager.securityPolicy.validatesDomainName = false
        sessionManager.securityPolicy.allowInvalidCertificates = false
        #if DEBUG
        sessionManager.securityPolicy.allowInvalidCertificates = false
        #endif

        sessionManager.setSessionDidReceiveAuthenticationChallenge { session, challenge, credential -> URLSession.AuthChallengeDisposition in
            var dispositionToReturn: URLSession.AuthChallengeDisposition = .performDefaultHandling
            if let validator = TrustKitWrapper.current?.pinningValidator {
                validator.handle(challenge, completionHandler: { (disposition, credentialOut) in
                    credential?.pointee = credentialOut
                    dispositionToReturn = disposition
                })
            } else {
                assert(false, "TrustKit not initialized correctly")
            }
            return dispositionToReturn
        }
        
        setupValueTransforms()
    }
    
    private func enableDoH() {
        
    }
    
    private func disableDoH() {
        
    }
    
    private func tryAnotherRecordDoH() {
        
    }
    
    internal func completionWrapperParseCompletion(_ completion: CompletionBlock?, forKey key: String) -> CompletionBlock? {
        if completion == nil {
            return nil
        }
        
        return { task, response, error in
            if error != nil {
                completion?(task, nil, error)
            } else {
                if let parsedResponse = response?[key] as? [String : Any] {
                    completion?(task, parsedResponse, nil)
                } else {
                    completion?(task, nil, NSError.unableToParseResponse(response))
                }
            }
        }
    }
    
    internal func fetchAuthCredential(_ completion: @escaping AuthCredentialBlock) {
        DispatchQueue.global(qos: .default).async {
            pthread_mutex_lock(&self.mutex)
            
            //fetch auth info

            guard let credential = AuthCredential.fetchFromKeychain(), // mailbox pwd is empty should show error and logout
                !(credential.password ?? "").isEmpty else
            {
                guard UnlockManager.shared.isUnlocked() else { // app is locked, fail with error gracefully
                    pthread_mutex_unlock(&self.mutex)
                    DispatchQueue.main.async {
                        completion(nil, NSError.authCacheLocked())
                    }
                    return
                }
                
                //clean auth cache let user relogin
                AuthCredential.clearFromKeychain()
                pthread_mutex_unlock(&self.mutex)
                DispatchQueue.main.async {
                    completion(nil, NSError.AuthCachePassEmpty())
                    UserTempCachedStatus.backup()
                    sharedUserDataService.signOut(true) //NOTES:signout + errors
                    userCachedStatus.signOut()
                    NSError.alertBadTokenToast()
                }
                return
            }
            
            guard !credential.isExpired else { // access token time is valid
                self.authRefresh (credential.password  ?? "") { (task, authCredential, error) -> Void in
                    self.debugError(error)
                    pthread_mutex_unlock(&self.mutex)
                    if error != nil && error!.domain == APIServiceErrorDomain && error!.code == APIErrorCode.AuthErrorCode.invalidGrant {
                        AuthCredential.clearFromKeychain()
                        DispatchQueue.main.async {
                            NSError.alertBadTokenToast()
                            self.fetchAuthCredential(completion)
                        }
                    } else if error != nil && error!.domain == APIServiceErrorDomain && error!.code == APIErrorCode.AuthErrorCode.localCacheBad {
                        AuthCredential.clearFromKeychain()
                        DispatchQueue.main.async {
                            NSError.alertBadTokenToast()
                            self.fetchAuthCredential(completion)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(authCredential, error)
                        }
                    }
                }
                return
            }
            
            pthread_mutex_unlock(&self.mutex)
            DispatchQueue.main.async {
                completion(credential, nil)
            }
        }
        
    }
    
    
    // MARK: - Request methods
    
    /// downloadTask returns the download task for use with UIProgressView+AFNetworking
    //TODO:: update completion
    internal func download(byUrl url: String,
                           destinationDirectoryURL: URL,
                           headers: [String : Any]?,
                           authenticated: Bool = true,
                           customAuthCredential: AuthCredential? = nil,
                           downloadTask: ((URLSessionDownloadTask) -> Void)?,
                           completion: @escaping ((URLResponse?, URL?, NSError?) -> Void)) {
        let authBlock: AuthCredentialBlock = { auth, error in
            if let error = error {
                self.debugError(error)
                completion(nil, nil, error)
            } else {
                let request = self.sessionManager.requestSerializer.request(withMethod: HTTPMethod.get.toString(),
                                                                            urlString: url,
                                                                            parameters: nil, error: nil)
                if let header = headers {
                    for (k, v) in header {
                        request.setValue("\(v)", forHTTPHeaderField: k)
                    }
                }
                
                let accessToken = auth?.token ?? ""
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                if let userid = auth?.userID {
                    request.setValue(userid, forHTTPHeaderField: "x-pm-uid")
                }
                
                let appversion = "iOS_\(Bundle.main.majorVersion)"
                request.setValue("application/vnd.protonmail.v1+json", forHTTPHeaderField: "Accept")
                request.setValue(appversion, forHTTPHeaderField: "x-pm-appversion")
                
                let clanguage = LanguageManager.currentLanguageEnum()
                request.setValue(clanguage.localeString, forHTTPHeaderField: "x-pm-locale")
                if let ua = UserAgent.default.ua {
                    request.setValue(ua, forHTTPHeaderField: "User-Agent")
                }
                
                let sessionDownloadTask = self.sessionManager.downloadTask(with: request as URLRequest, progress: { (progress) in
                    
                }, destination: { (targetURL, response) -> URL in
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
            authBlock(customAuthCredential, nil)
        }
    }
    
    internal func upload (byPath path: String,
    parameters: [String:String],
    keyPackets : Data,
    dataPacket : Data,
    signature : Data?,
    headers: [String : Any]?,
    authenticated: Bool = true,
    customAuthCredential: AuthCredential? = nil,
    completion: @escaping CompletionBlock) {
        let url = self.doh.getHostUrl() + path
        self.upload(byUrl: url,
                    parameters: parameters,
                    keyPackets: keyPackets,
                    dataPacket: dataPacket,
                    signature: signature,
                    headers: headers,
                    authenticated: authenticated,
                    customAuthCredential: customAuthCredential,
                    completion: completion)
    }
    
    /**
     this function only for upload attachments for now.
     
     :param: url        The content accept endpoint
     :param: parameters the request body
     :param: keyPackets encrypt attachment key package
     :param: dataPacket encrypt attachment data package
     */
    internal func upload (byUrl url: String,
                          parameters: [String:String],
                          keyPackets : Data,
                          dataPacket : Data,
                          signature : Data?,
                          headers: [String : Any]?,
                          authenticated: Bool = true,
                          customAuthCredential: AuthCredential? = nil,
                          completion: @escaping CompletionBlock) {
        
        
        let authBlock: AuthCredentialBlock = { auth, error in
            if let error = error {
                self.debugError(error)
                completion(nil, nil, error)
            } else {
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
                
                let accessToken = auth?.token ?? ""
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                if let userid = auth?.userID {
                    request.setValue(userid, forHTTPHeaderField: "x-pm-uid")
                }
                
                let appversion = "iOS_\(Bundle.main.majorVersion)"
                request.setValue("application/vnd.protonmail.v1+json", forHTTPHeaderField: "Accept")
                request.setValue(appversion, forHTTPHeaderField: "x-pm-appversion")
                
                let clanguage = LanguageManager.currentLanguageEnum()
                request.setValue(clanguage.localeString, forHTTPHeaderField: "x-pm-locale")
                if let ua = UserAgent.default.ua {
                    request.setValue(ua, forHTTPHeaderField: "User-Agent")
                }
            
                var uploadTask: URLSessionDataTask? = nil
                uploadTask = self.sessionManager.uploadTask(withStreamedRequest: request as URLRequest, progress: { (progress) in
                    // nothing
                }, completionHandler: { (response, responseObject, error) in
                    self.debugError(error)
                    
                    // reachability temporarily failed because was switching from WiFi to Cellular
                    if (error as NSError?)?.code == -1005,
                        self.delegate?.isReachable() == true
                    {
                        // retry task asynchonously
                        DispatchQueue.global(qos: .utility).async {
                            self.upload(byUrl: url,
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
                    
                    let resObject = responseObject as? [String : Any]
                    completion(uploadTask, resObject, error as NSError?)
                })
                uploadTask?.resume()
            }
        }
        
        if authenticated && customAuthCredential == nil {
            fetchAuthCredential(authBlock)
        } else {
            authBlock(customAuthCredential, nil)
        }
    }
    
    
    //new requestion function
    func request(method: HTTPMethod,
                 path: String, parameters: Any?,
                 headers: [String : Any]?,
                 authenticated: Bool = true,
                 authRetry: Bool = true,
                 customAuthCredential: AuthCredential? = nil,
                 completion: CompletionBlock?) {
        let authBlock: AuthCredentialBlock = { auth, error in
            if let error = error {
                self.debugError(error)
                completion?(nil, nil, error)
            } else {
                let parseBlock: (_ task: URLSessionDataTask?, _ response: Any?, _ error: Error?) -> Void = { task, response, error in
                    if let error = error as NSError? {
                        self.debugError(error)
                        PMLog.D(api: error)
                        var httpCode : Int = 200
                        if let detail = error.userInfo["com.alamofire.serialization.response.error.response"] as? HTTPURLResponse {
                            httpCode = detail.statusCode
                        }
                        else {
                            httpCode = error.code
                        }
                        
                        if authenticated && httpCode == 401 && authRetry {
                            AuthCredential.expireOrClear(auth?.token)
                            if path.contains("https://api.protonmail.ch/refresh") { //tempery no need later
                                completion?(nil, nil, error)
                                self.delegate?.onError(error: error)
                                UserTempCachedStatus.backup()
                                sharedUserDataService.signOut(true);
                                userCachedStatus.signOut()
                            }else {
                                self.request(method: method,
                                             path: path,
                                             parameters: parameters,
                                             headers: ["x-pm-apiversion": 3],
                                             authenticated: authenticated,
                                             customAuthCredential: customAuthCredential,
                                             completion: completion)
                            }
                        } else if let responseDict = response as? [String : Any], let responseCode = responseDict["Code"] as? Int {
                            let errorMessage = responseDict["Error"] as? String ?? ""
                            let displayError : NSError = NSError.protonMailError(responseCode,
                                                                   localizedDescription: errorMessage,
                                                                   localizedFailureReason: errorMessage,
                                                                   localizedRecoverySuggestion: nil)
                            if responseCode.forceUpgrade {
                                // old check responseCode == 5001 || responseCode == 5002 || responseCode == 5003 || responseCode == 5004
                                // new logic will not log user out
                                NotificationCenter.default.post(name: .forceUpgrade, object: errorMessage)
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
                        } else if let responseDictionary = response as? [String : Any],
                            let responseCode = responseDictionary["Code"] as? Int {
                            var error : NSError?
                            if responseCode != 1000 && responseCode != 1001 {
                                let errorMessage = responseDictionary["Error"] as? String
                                error = NSError.protonMailError(responseCode,
                                                                localizedDescription: errorMessage ?? "",
                                                                localizedFailureReason: errorMessage,
                                                                localizedRecoverySuggestion: nil)
                            }
                            
                            if authenticated && responseCode == 401 {
                                self.request(method: method,
                                             path: path,
                                             parameters: parameters,
                                             headers: ["x-pm-apiversion": 3],
                                             authenticated: authenticated,
                                             customAuthCredential: customAuthCredential,
                                             completion: completion)
                            } else if responseCode.forceUpgrade  {
                                //FIXME: shouldn't be here
                                let errorMessage = responseDictionary["Error"] as? String
                                NotificationCenter.default.post(name: .forceUpgrade, object: errorMessage)
                                completion?(task, responseDictionary, error)
                            } else if responseCode == APIErrorCode.API_offline {
                                completion?(task, responseDictionary, error)
                            }
                            else {
                                completion?(task, responseDictionary, error)
                            }
                            self.debugError(error)
                        } else {
                            self.debugError(NSError.unableToParseResponse(response))
                            completion?(task, nil, NSError.unableToParseResponse(response))
                        }
                    }
                }
                
                let url = self.doh.getHostUrl() + path
                let request = self.sessionManager.requestSerializer.request(withMethod: method.toString(),
                                                                            urlString: url,
                                                                            parameters: parameters,
                                                                            error: nil)
                if let header = headers {
                    for (k, v) in header {
                        request.setValue("\(v)", forHTTPHeaderField: k)
                    }
                }
                let accessToken = auth?.token ?? ""
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                if let userid = auth?.userID {
                    request.setValue(userid, forHTTPHeaderField: "x-pm-uid")
                }
                let appversion = "iOS_\(Bundle.main.majorVersion)"
                request.setValue("application/vnd.protonmail.v1+json", forHTTPHeaderField: "Accept")
                request.setValue(appversion, forHTTPHeaderField: "x-pm-appversion")
                
                let clanguage = LanguageManager.currentLanguageEnum()
                request.setValue(clanguage.localeString, forHTTPHeaderField: "x-pm-locale")
                if let ua = UserAgent.default.ua {
                    request.setValue(ua, forHTTPHeaderField: "User-Agent")
                }
                
                var task: URLSessionDataTask? = nil
                task = self.sessionManager.dataTask(with: request as URLRequest, uploadProgress: { (progress) in
                    //TODO::add later
                }, downloadProgress: { (progress) in
                    //TODO::add later
                }, completionHandler: { (urlresponse, res, error) in
                    self.debugError(error)
                    if let urlres = urlresponse as? HTTPURLResponse, let allheader = urlres.allHeaderFields as? [String : Any] {
                        //PMLog.D("\(allheader.json(prettyPrinted: true))")
                        if let strData = allheader["Date"] as? String {
                            // create dateFormatter with UTC time format
                            let dateFormatter = DateFormatter()
                            dateFormatter.calendar = .some(.init(identifier: .gregorian))
                            dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
                            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                            if let date = dateFormatter.date(from: strData) {
                                let timeInterval = date.timeIntervalSince1970
                                Crypto.updateTime(Int64(timeInterval))
                            }
                        }
                    }
                    
                    DoHMail.default.handleError(host: url, error: error)
                    /// parse urlresponse
                    parseBlock(task, res, error)
                })
                task!.resume()
            }
        }
        
        if authenticated && customAuthCredential == nil {
            fetchAuthCredential(authBlock)
        } else {
            authBlock(customAuthCredential, nil)
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
}



