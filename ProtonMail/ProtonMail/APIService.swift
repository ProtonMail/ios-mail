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

let sharedAPIService = APIService()

class APIService {
    
    // refresh token failed count
    internal var refreshTokenFailedCount = 0
    
    // synchronize lock
    internal var mutex = pthread_mutex_t()
    
    // api session manager
    private var sessionManager: AFHTTPSessionManager
    
    // get session
    func getSession() -> AFHTTPSessionManager{
        return sessionManager;
    }
    
    // MARK: - Internal methods
    
    init() {
        // init lock
        pthread_mutex_init(&mutex, nil)
        
        sessionManager = AFHTTPSessionManager(baseURL: NSURL(string: AppConstants.BaseURLString)!)
        sessionManager.requestSerializer = AFJSONRequestSerializer() as AFHTTPRequestSerializer
        //sessionManager.requestSerializer.timeoutInterval = 20.0;
        sessionManager.securityPolicy.validatesDomainName = false
        sessionManager.securityPolicy.allowInvalidCertificates = false
        
        #if DEBUG
            sessionManager.securityPolicy.allowInvalidCertificates = true
        #endif
        
        //NSOperationQueueDefaultMaxConcurrentOperationCount sessionManager.operationQueue.maxConcurrentOperationCount
        //let defaultV = NSOperationQueueDefaultMaxConcurrentOperationCount;
        setupValueTransforms()
    }
    
    internal func afNetworkingBlocksForRequest(method: HTTPMethod, path: String, parameters: AnyObject?, auth: AuthCredential?, authenticated: Bool = true, completion: CompletionBlock?) -> (AFNetworkingSuccessBlock?, AFNetworkingFailureBlock?) {
        if let completion = completion {
            let failure: AFNetworkingFailureBlock = { task, error in
                PMLog.D("Error: \(error)")
                var errorCode : Int = 200;
                if let detail = error.userInfo["com.alamofire.serialization.response.error.response"] as? NSHTTPURLResponse {
                    errorCode = detail.statusCode
                }
                else {
                    errorCode = error.code
                }
                
                if authenticated && errorCode == 401 {
                    AuthCredential.expireOrClear(auth?.token)
                    if path.contains("https://api.protonmail.ch/refresh") { //tempery no need later
                        error.alertToast()
                        UserTempCachedStatus.backup()
                        sharedUserDataService.signOut(true);
                        userCachedStatus.signOut()
                    }else {
                        self.setApiVesion(1, appVersion: 1)
                        self.request(method: method, path: path, parameters: parameters, authenticated: authenticated, completion: completion)
                    }
                } else {
                    completion(task: task, response: nil, error: error)
                }
            }
            
            let success: AFNetworkingSuccessBlock = { task, responseObject in
                if responseObject == nil {
                    completion(task: task, response: [:], error: nil)
                } else if let responseDictionary = responseObject as? Dictionary<String, AnyObject> {
                    var error : NSError?
                    let responseCode = responseDictionary["Code"] as? Int
                    
                    if responseCode != 1000 && responseCode != 1001 {
                        let errorMessage = responseDictionary["Error"] as? String
                        let errorDetails = responseDictionary["ErrorDescription"] as? String
                        error = NSError.protonMailError(responseCode ?? 1000, localizedDescription: errorMessage ?? "", localizedFailureReason: errorDetails, localizedRecoverySuggestion: nil)
                    }
                    
                    if authenticated && responseCode == 401 {
                        AuthCredential.expireOrClear(auth?.token)
                        self.setApiVesion(1, appVersion: 1)
                        self.request(method: method, path: path, parameters: parameters, authenticated: authenticated, completion: completion)
                    } else if responseCode == 5001 || responseCode == 5002 || responseCode == 5003 || responseCode == 5004 {
                        NSError.alertUpdatedToast()
                        completion(task: task, response: responseDictionary, error: error)
                        UserTempCachedStatus.backup()
                        sharedUserDataService.signOut(true);
                        userCachedStatus.signOut()
                    } else if responseCode == APIErrorCode.API_offline {
                        completion(task: task, response: responseDictionary, error: error)
                    }
                    else {
                        completion(task: task, response: responseDictionary, error: error)
                    }
                } else {
                    completion(task: task, response: nil, error: NSError.unableToParseResponse(responseObject))
                }
            }
            return (success, failure)
        }
        return (nil, nil)
    }
    
    internal func completionWrapperParseCompletion(completion: CompletionBlock?, forKey key: String) -> CompletionBlock? {
        if completion == nil {
            return nil
        }
        
        return { task, response, error in
            if error != nil {
                completion?(task: task, response: nil, error: error)
            } else {
                if let parsedResponse = response?[key] as? Dictionary<String, AnyObject> {
                    completion?(task: task, response: parsedResponse, error: nil)
                } else {
                    completion?(task: task, response: nil, error: NSError.unableToParseResponse(response))
                }
            }
        }
    }
    
    internal func fetchAuthCredential(completion: AuthCredentialBlock) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            pthread_mutex_lock(&self.mutex)
            //fetch auth info
            if let credential = AuthCredential.fetchFromKeychain() {
                //PMLog.D("\(credential.description)")
                if !credential.isExpired { // access token time is valid
                    if (credential.password ?? "").isEmpty { // mailbox pwd is empty should show error and logout
                        
                        //clean auth cache let user relogin
                        AuthCredential.clearFromKeychain()
                        pthread_mutex_unlock(&self.mutex)
                        dispatch_async(dispatch_get_main_queue()) {
                            completion(nil, NSError.AuthCachePassEmpty())
                            UserTempCachedStatus.backup()
                            sharedUserDataService.signOut(true) //NOTES:signout + errors
                            userCachedStatus.signOut()
                            NSError.alertBadTokenToast()
                        }
                    } else {
                        self.sessionManager.requestSerializer.setAuthorizationHeaderFieldWithCredential(credential)
                        pthread_mutex_unlock(&self.mutex)
                        dispatch_async(dispatch_get_main_queue()) {
                            completion(credential, nil)
                        }
                    }
                } else {
                    if (credential.password ?? "").isEmpty {
                        AuthCredential.clearFromKeychain()
                        pthread_mutex_unlock(&self.mutex)
                        dispatch_async(dispatch_get_main_queue()) {
                            completion(nil, NSError.AuthCachePassEmpty())
                            UserTempCachedStatus.backup()
                            sharedUserDataService.signOut(true)
                            userCachedStatus.signOut()
                            NSError.alertBadTokenToast()
                        }
                    } else {
                        self.authRefresh (credential.password  ?? "") { (task, authCredential, error) -> Void in
                            pthread_mutex_unlock(&self.mutex)
                            if error != nil && error!.domain == APIServiceErrorDomain && error!.code == APIErrorCode.AuthErrorCode.invalidGrant {
                                AuthCredential.clearFromKeychain()
                                dispatch_async(dispatch_get_main_queue()) {
                                    NSError.alertBadTokenToast()
                                    self.fetchAuthCredential(completion)
                                }
                            } else if error != nil && error!.domain == APIServiceErrorDomain && error!.code == APIErrorCode.AuthErrorCode.localCacheBad {
                                AuthCredential.clearFromKeychain()
                                dispatch_async(dispatch_get_main_queue()) {
                                    NSError.alertBadTokenToast()
                                    completion(authCredential, error)
                                }
                            } else {
                                if let credential = AuthCredential.fetchFromKeychain() {
                                    self.sessionManager.requestSerializer.setAuthorizationHeaderFieldWithCredential(credential)
                                }
                                dispatch_async(dispatch_get_main_queue()) {
                                    completion(authCredential, error)
                                }
                            }
                        }
                    }
                }
            } else { //the cache have issues
                AuthCredential.clearFromKeychain()
                pthread_mutex_unlock(&self.mutex)
                dispatch_async(dispatch_get_main_queue()) {
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
    internal func download(path: String, destinationDirectoryURL: NSURL, downloadTask: ((NSURLSessionDownloadTask) -> Void)?, completion: ((NSURLResponse?, NSURL?, NSError?) -> Void)?) {
        if let url = NSURL(string: path, relativeToURL: self.sessionManager.baseURL), let abs_string = url.absoluteString {
            var error:NSError? = nil
            let request = self.sessionManager.requestSerializer.requestWithMethod("GET", URLString: abs_string, parameters: nil, error: &error)
            if let ex = error {
                completion?(nil, nil, ex)
            } else {
                let sessionDownloadTask = self.sessionManager.downloadTaskWithRequest(request, progress: nil, destination: { (targetURL, response) -> NSURL in
                    return destinationDirectoryURL
                    }, completionHandler: completion )
                downloadTask?(sessionDownloadTask)
                sessionDownloadTask.resume()
            }
        } else {
            completion?(nil, nil, NSError.badPath(path))
        }
    }
    
    internal func setApiVesion(apiVersion:Int, appVersion:Int)
    {
        self.sessionManager.requestSerializer.setVersionHeader(apiVersion, appVersion: appVersion)
    }
    
    
    /**
     this function only for upload attachments for now.
     
     :param: url        The content accept endpoint
     :param: parameters the request body
     :param: keyPackets encrypt attachment key package
     :param: dataPacket encrypt attachment data package
     */
    internal func upload (url: String, parameters: AnyObject?, keyPackets : NSData!, dataPacket : NSData!, completion: CompletionBlock?) {
        //TODO / RUSH : need add respons handling, progress bar later
        var error:NSError? = nil
        let request = sessionManager.requestSerializer.multipartFormRequestWithMethod("POST", URLString: url, parameters: parameters as! [String:String], constructingBodyWithBlock: { (formData) -> Void in
            let data: AFMultipartFormData = formData
            data.appendPartWithFileData(keyPackets, name: "KeyPackets", fileName: "KeyPackets.txt", mimeType: "" )
            data.appendPartWithFileData(dataPacket, name: "DataPacket", fileName: "DataPacket.txt", mimeType: "" ) }, error: &error)
        
        if let ex = error {
            completion?(task: nil, response: nil, error: ex)
        } else {
            let uploadTask = self.sessionManager.uploadTaskWithStreamedRequest(request, progress: nil) { (response, responseObject, error) -> Void in
                completion?(task: nil, response: responseObject as? Dictionary<String,AnyObject>, error: error)
            }
            uploadTask.resume()
        }
    }
    
    func request(method method: HTTPMethod, path: String, parameters: AnyObject?, authenticated: Bool = true, completion: CompletionBlock?) {
        let authBlock: AuthCredentialBlock = { auth, error in
            if error == nil {
                let (successBlock, failureBlock) = self.afNetworkingBlocksForRequest(method, path: path, parameters: parameters, auth:auth, authenticated: authenticated, completion: completion)
                
                //TODO:: need use progress later
                switch(method) {
                case .DELETE:
                    self.sessionManager.DELETE(path, parameters: parameters, success: successBlock, failure: failureBlock)
                case .POST:
                    self.sessionManager.POST(path, parameters: parameters, progress: nil, success: successBlock, failure: failureBlock)
                case .PUT:
                    self.sessionManager.PUT(path, parameters: parameters, success: successBlock, failure: failureBlock)
                default:
                    self.sessionManager.GET(path, parameters: parameters, progress: nil, success: successBlock, failure: failureBlock)
                }
            } else {
                completion?(task: nil, response: nil, error: error)
            }
        }
        
        if authenticated {
            fetchAuthCredential(authBlock)
        } else {
            authBlock(nil, nil)
        }
    }
    
    
}

