//
//  APIService.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import CoreData
import Foundation


let APIServiceErrorDomain = NSError.protonMailErrorDomain("APIService")


protocol APIServiceDelegate {
    func onError(error: NSError)
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
    
    var delegate : APIServiceDelegate?
    
    // MARK: - Internal methods
    
    init() {
        // init lock
        pthread_mutex_init(&mutex, nil)
        
        sessionManager = AFHTTPSessionManager(baseURL: URL(string: AppConstants.API_HOST_URL)!)
        sessionManager.requestSerializer = AFJSONRequestSerializer() as AFHTTPRequestSerializer
        //sessionManager.requestSerializer.timeoutInterval = 20.0;
        sessionManager.securityPolicy.validatesDomainName = false
        sessionManager.securityPolicy.allowInvalidCertificates = false
        
        #if DEBUG
            sessionManager.securityPolicy.allowInvalidCertificates = true
        #endif
        
        setupValueTransforms()
    }
    
    internal func afNetworkingBlocksForRequest(_ method: HTTPMethod, path: String, parameters: Any?, auth: AuthCredential?, authenticated: Bool = true, completion: CompletionBlock?) -> (AFNetworkingSuccessBlock?, AFNetworkingFailureBlock?) {
        if let completion = completion {
            let failure: AFNetworkingFailureBlock = { task, error in
                //TODO::Swift
                let error = error! as NSError
                PMLog.D("Error: \(String(describing: error))")
                var errorCode : Int = 200;
                if let detail = error.userInfo["com.alamofire.serialization.response.error.response"] as? HTTPURLResponse {
                    errorCode = detail.statusCode
                }
                else {
                    errorCode = error.code
                }
                
                if authenticated && errorCode == 401 {
                    AuthCredential.expireOrClear(auth?.token)
                    if path.contains("https://api.protonmail.ch/refresh") { //tempery no need later
                        self.delegate?.onError(error: error)
                        UserTempCachedStatus.backup()
                        sharedUserDataService.signOut(true);
                        userCachedStatus.signOut()
                    }else {
                        self.request(method: method, path: path, parameters: parameters, headers: ["x-pm-apiversion": 1], authenticated: authenticated, completion: completion)
                    }
                } else {
                    completion(task, nil, error)
                }
            }
            
            let success: AFNetworkingSuccessBlock = { task, responseObject in
                if responseObject == nil {
                    completion(task, [:], nil)
                } else if let responseDictionary = responseObject as? Dictionary<String, Any> {
                    var error : NSError?
                    let responseCode = responseDictionary["Code"] as? Int
                    
                    if responseCode != 1000 && responseCode != 1001 {
                        let errorMessage = responseDictionary["Error"] as? String
                        let errorDetails = responseDictionary["ErrorDescription"] as? String
                        error = NSError.protonMailError(responseCode ?? 1000, localizedDescription: errorMessage ?? "", localizedFailureReason: errorDetails, localizedRecoverySuggestion: nil)
                    }
                    
                    if authenticated && responseCode == 401 {
                        AuthCredential.expireOrClear(auth?.token)
                        self.request(method: method, path: path, parameters: parameters, headers: ["x-pm-apiversion": 1], authenticated: authenticated, completion: completion)
                    } else if responseCode == 5001 || responseCode == 5002 || responseCode == 5003 || responseCode == 5004 {
                        //TODO::Fix later
//                        NSError.alertUpdatedToast()
                        completion(task, responseDictionary, error)
                        UserTempCachedStatus.backup()
                        sharedUserDataService.signOut(true);
                        userCachedStatus.signOut()
                    } else if responseCode == APIErrorCode.API_offline {
                        completion(task, responseDictionary, error)
                    }
                    else {
                        completion(task, responseDictionary, error)
                    }
                } else {
                    completion(task, nil, NSError.unableToParseResponse(responseObject))
                }
            }
            return (success, failure)
        }
        return (nil, nil)
    }
    
    internal func completionWrapperParseCompletion(_ completion: CompletionBlock?, forKey key: String) -> CompletionBlock? {
        if completion == nil {
            return nil
        }
        
        return { task, response, error in
            if error != nil {
                completion?(task, nil, error)
            } else {
                if let parsedResponse = response?[key] as? Dictionary<String, Any> {
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
            if let credential = AuthCredential.fetchFromKeychain() {
                if !credential.isExpired { // access token time is valid
                    if (credential.password ?? "").isEmpty { // mailbox pwd is empty should show error and logout
                        //clean auth cache let user relogin
                        AuthCredential.clearFromKeychain()
                        pthread_mutex_unlock(&self.mutex)
                        DispatchQueue.main.async {
                            //TODO::Fix later
                            completion(nil, NSError.AuthCachePassEmpty())
                            UserTempCachedStatus.backup()
                            sharedUserDataService.signOut(true) //NOTES:signout + errors
                            userCachedStatus.signOut()
                            
                            //NSError.alertBadTokenToast()
                        }
                    } else {
                        pthread_mutex_unlock(&self.mutex)
                        DispatchQueue.main.async {
                            completion(credential, nil)
                        }
                    }
                } else {
                    if (credential.password ?? "").isEmpty {
                        AuthCredential.clearFromKeychain()
                        pthread_mutex_unlock(&self.mutex)
                        DispatchQueue.main.async {
                            //TODO::Fix later
                            completion(nil, NSError.AuthCachePassEmpty())
                            UserTempCachedStatus.backup()
                            sharedUserDataService.signOut(true)
                            userCachedStatus.signOut()
//                            NSError.alertBadTokenToast()
                        }
                    } else {
                        self.authRefresh (credential.password  ?? "") { (task, authCredential, error) -> Void in
                            pthread_mutex_unlock(&self.mutex)
                            if error != nil && error!.domain == APIServiceErrorDomain && error!.code == APIErrorCode.AuthErrorCode.invalidGrant {
                                AuthCredential.clearFromKeychain()
                                DispatchQueue.main.async {
                                    //TODO::Fix later
//                                    NSError.alertBadTokenToast()
                                    self.fetchAuthCredential(completion)
                                }
                            } else if error != nil && error!.domain == APIServiceErrorDomain && error!.code == APIErrorCode.AuthErrorCode.localCacheBad {
                                AuthCredential.clearFromKeychain()
                                DispatchQueue.main.async {
                                    //TODO::Fix later
//                                    NSError.alertBadTokenToast()
                                    self.fetchAuthCredential(completion)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    completion(authCredential, error)
                                }
                            }
                        }
                    }
                }
            } else { //the cache have issues
                AuthCredential.clearFromKeychain()
                pthread_mutex_unlock(&self.mutex)
                DispatchQueue.main.async {
                    if sharedUserDataService.isSignedIn {
                        completion(nil, NSError.authCacheBad())
                        UserTempCachedStatus.backup()
                        sharedUserDataService.signOut(true)
                        userCachedStatus.signOut()
                    }
                }
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
                           downloadTask: ((URLSessionDownloadTask) -> Void)?,
                           completion: @escaping ((URLResponse?, URL?, NSError?) -> Void)) {
        
        
        let authBlock: AuthCredentialBlock = { auth, error in
            if let error = error {
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
                
                let sessionDownloadTask = self.sessionManager.downloadTask(with: request as URLRequest, progress: { (progress) in
                    
                }, destination: { (targetURL, response) -> URL in
                    return destinationDirectoryURL
                }, completionHandler: { (response, url, error) in
                    completion(response, url, error as NSError?)
                })
                downloadTask?(sessionDownloadTask)
                sessionDownloadTask.resume()
            }
        }
        
        if authenticated {
            fetchAuthCredential(authBlock)
        } else {
            authBlock(nil, nil)
        }
    }

    
    /**
     this function only for upload attachments for now.
     
     :param: url        The content accept endpoint
     :param: parameters the request body
     :param: keyPackets encrypt attachment key package
     :param: dataPacket encrypt attachment data package
     */
    internal func upload (byUrl url: String,
                          parameters: Any?,
                          keyPackets : Data!,
                          dataPacket : Data!,
                          headers: [String : Any]?,
                          authenticated: Bool = true,
                          completion: @escaping CompletionBlock) {
        
        
        let authBlock: AuthCredentialBlock = { auth, error in
            if let error = error {
                completion(nil, nil, error)
            } else {
                let request = self.sessionManager.requestSerializer.multipartFormRequest(withMethod: "POST", urlString: url, parameters: parameters as! [String:String], constructingBodyWith: { (formData) -> Void in
                    let data: AFMultipartFormData = formData
                    data.appendPart(withFileData: keyPackets, name: "KeyPackets", fileName: "KeyPackets.txt", mimeType: "" )
                    data.appendPart(withFileData: dataPacket, name: "DataPacket", fileName: "DataPacket.txt", mimeType: "" ) }, error: nil)

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
            
                var uploadTask: URLSessionDataTask? = nil
                uploadTask = self.sessionManager.uploadTask(withStreamedRequest: request as URLRequest, progress: { (progress) in
                    //
                }, completionHandler: { (response, responseObject, error) in
                    let resObject = responseObject as? Dictionary<String, Any>
                    completion(uploadTask, resObject, error as NSError?)
                })
                uploadTask?.resume()
            }
        }
        
        if authenticated {
            fetchAuthCredential(authBlock)
        } else {
            authBlock(nil, nil)
        }
    }
    
    //new requestion function
    func request(method: HTTPMethod,
                 path: String, parameters: Any?,
                 headers: [String : Any]?,
                 authenticated: Bool = true,
                 completion: CompletionBlock?) {
        
        let authBlock: AuthCredentialBlock = { auth, error in
            if let error = error {
                completion?(nil, nil, error)
            } else {
                let (successBlock, failureBlock) = self.afNetworkingBlocksForRequest(method, path: path, parameters: parameters, auth:auth, authenticated: authenticated, completion: completion)
                let url = AppConstants.API_HOST_URL + path
                let request = AFJSONRequestSerializer().request(withMethod: method.toString(), urlString: url, parameters: parameters, error: nil)
                //request.timeoutInterval = 120
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
                
                var task: URLSessionDataTask? = nil
                task = self.sessionManager.dataTask(with: request as URLRequest, uploadProgress: { (progress) in
                    //TODO::add later
                }, downloadProgress: { (progress) in
                    //TODO::add later
                }, completionHandler: { (urlresponse, res, error) in
                    if let err = error {
                        failureBlock?(task, err)
                    } else {
                        successBlock?(task, res)
                    }
                })
                task!.resume()
            }
        }
        
        if authenticated {
            fetchAuthCredential(authBlock)
        } else {
            authBlock(nil, nil)
        }
    }

    
}

