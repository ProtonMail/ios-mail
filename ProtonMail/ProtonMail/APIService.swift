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


let APIServiceErrorDomain = NSError.protonMailErrorDomain(subdomain: "APIService")

let sharedAPIService = APIService()
class APIService {
    
    var tried : Int = 0
    var tokenRefreshing = false
    
    typealias CompletionBlock = (task: NSURLSessionDataTask!, response: Dictionary<String,AnyObject>?, error: NSError?) -> Void
    typealias CompletionFetchDetail = (task: NSURLSessionDataTask!, response: Dictionary<String,AnyObject>?, message:Message?, error: NSError?) -> Void

    enum HTTPMethod {
        case DELETE
        case GET
        case POST
        case PUT
    }
    
    // MARK: - Internal variables
    
    internal typealias AFNetworkingFailureBlock = (NSURLSessionDataTask!, NSError!) -> Void
    internal typealias AFNetworkingSuccessBlock = (NSURLSessionDataTask!, AnyObject!) -> Void
    
    // MARK: - Private variables
    
    private let sessionManager: AFHTTPSessionManager
    
    func getSession() ->AFHTTPSessionManager{
        return sessionManager;
    }
    
    // MARK: - Internal methods
    
    init() {
        sessionManager = AFHTTPSessionManager(baseURL: NSURL(string: AppConstants.BaseURLString)!)
        sessionManager.requestSerializer = AFJSONRequestSerializer() as AFHTTPRequestSerializer
        
        #if DEBUG
            sessionManager.securityPolicy.allowInvalidCertificates = true
        #endif
        
        //NSOperationQueueDefaultMaxConcurrentOperationCount sessionManager.operationQueue.maxConcurrentOperationCount
        //let defaultV = NSOperationQueueDefaultMaxConcurrentOperationCount;
        setupValueTransforms()
    }
    
    internal func afNetworkingBlocksForRequest(#method: HTTPMethod, path: String, parameters: AnyObject?, authenticated: Bool = true, completion: CompletionBlock?) -> (AFNetworkingSuccessBlock?, AFNetworkingFailureBlock?) {
        if let completion = completion {
            let failure: AFNetworkingFailureBlock = { task, error in
                PMLog.D("\(__FUNCTION__) Error: \(error)")
                
                var errorCode : Int = 200;
                if let errorUserInfo = error.userInfo {
                    if let detail = errorUserInfo["com.alamofire.serialization.response.error.response"] as? NSHTTPURLResponse {
                        errorCode = detail.statusCode
                    }
                    else {
                        errorCode = error.code
                    }
                }
                
                if authenticated && errorCode == 401 {
                    AuthCredential.expireOrClear()
                    if path.contains("https://api.protonmail.ch/refresh") { //tempery no need later
                        sharedUserDataService.signOut(true);
                    }else {
                        self.setApiVesion(1, appVersion: 1)
                        self.request(method: method, path: path, parameters: parameters, authenticated: authenticated, completion: completion)
                    }
                } else {
                    completion(task: task, response: nil, error: error)
                }
            }
            let success: AFNetworkingSuccessBlock = { task, responseObject in
                //PMLog("\(__FUNCTION__) Response: \(responseObject)")
                if let responseDictionary = responseObject as? Dictionary<String, AnyObject> {
                    let responseCode = responseDictionary["Code"] as? Int
                    if authenticated && responseCode == 401 {
                        AuthCredential.expireOrClear()
                        self.setApiVesion(1, appVersion: 1)
                        self.request(method: method, path: path, parameters: parameters, authenticated: authenticated, completion: completion)
                    } else if responseCode == 5001 || responseCode == 5002 || responseCode == 5003 || responseCode == 5004 {
                        NSError.alertUpdatedToast()
                        completion(task: task, response: responseDictionary, error: nil)
                        sharedUserDataService.signOut(true);
                    } else if responseCode == 7001 { //offline
                        NSError.alertOfflineToast()
                        completion(task: task, response: responseDictionary, error: nil)
                        sharedUserDataService.signOut(true);
                    }
                    else {
                        //TODO :: need add error handling here pass the respones if has error.
                        completion(task: task, response: responseDictionary, error: nil)
                    }
                } else if responseObject == nil {
                    completion(task: task, response: [:], error: nil)
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
    
    internal func fetchAuthCredential(#completion: AuthCredentialBlock) {
        if let credential = AuthCredential.fetchFromKeychain() {
            if !credential.isExpired {
                if (credential.password ?? "").isEmpty {
                    self.tried = 0
                    AuthCredential.clearFromKeychain()
                    completion(nil, NSError.authCacheBad())
                    sharedUserDataService.signOut(true)
                } else {
                    
                    self.tried = 0
                    self.sessionManager.requestSerializer.setAuthorizationHeaderFieldWithCredential(credential)
                    completion(credential, nil)
                }
            } else {
                self.tried += 1
                if (credential.password ?? "").isEmpty {
                    self.tried = 0
                    AuthCredential.clearFromKeychain()
                    completion(nil, NSError.authCacheBad())
                    sharedUserDataService.signOut(true)
                } else {
                    authRefresh (credential.password  ?? "") { (task, authCredential, error) -> Void in
                        if error == nil && self.tried < 8 {
                            self.fetchAuthCredential(completion: completion)
                        } else if error != nil && error!.domain == APIServiceErrorDomain && error!.code == APIErrorCode.AuthErrorCode.invalidGrant {
                            AuthCredential.clearFromKeychain()
                            self.fetchAuthCredential(completion: completion)
                        } else if error != nil && error!.domain == APIServiceErrorDomain && error!.code == APIErrorCode.AuthErrorCode.localCacheBad {
                            AuthCredential.clearFromKeychain()
                            completion(authCredential, error)
                            sharedUserDataService.signOut(true)
                        } else if self.tried > 7 {
                            self.tried = 0
                            AuthCredential.clearFromKeychain()
                            completion(nil, NSError.authCacheBad())
                            sharedUserDataService.signOut(true)
                        }
                        else {
                            completion(authCredential, error)
                        }
                    }
                }
            }
        } else {
            AuthCredential.clearFromKeychain()
            if sharedUserDataService.isSignedIn {
                completion(nil, NSError.authCacheBad())
                sharedUserDataService.signOut(true)
                userCachedStatus.signOut()
                NSError.alertBadTokenToast()
            }
        }
    }
    
    // MARK: - Request methods
    
    /// downloadTask returns the download task for use with UIProgressView+AFNetworking
    internal func download(#path: String, destinationDirectoryURL: NSURL, downloadTask: ((NSURLSessionDownloadTask) -> Void)?, completion: ((NSURLResponse?, NSURL?, NSError?) -> Void)?) {
        //AuthCredential.expireOrClear()
        //        fetchAuthCredential() { _, error in
        //            if error == nil {
        if let url = NSURL(string: path, relativeToURL: self.sessionManager.baseURL) {
            var serializeError: NSError?
            if let request = self.sessionManager.requestSerializer.requestWithMethod("GET", URLString: url.absoluteString!, parameters: nil, error: &serializeError) {
                if let sessionDownloadTask = self.sessionManager.downloadTaskWithRequest(
                    request,
                    progress: nil,
                    destination: { (targetURL, response) -> NSURL! in
                        //let fileName = response.suggestedFilename!
                        return destinationDirectoryURL//.URLByAppendingPathComponent(fileName)
                    },
                    completionHandler: completion)
                {
                        downloadTask?(sessionDownloadTask)
                        sessionDownloadTask.resume()
                }
            } else {
                completion?(nil, nil, serializeError)
            }
            
        } else {
            completion?(nil, nil, NSError.badPath(path))
            return
        }
        //            } else {
        //                completion?(nil, nil, error)
        //            }
        //        }
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
    internal func upload (url: String, parameters: AnyObject?, keyPackets : NSData!, dataPacket : NSData!, completion: CompletionBlock?) { //TODO / RUSH : need add respons handling, progress bar later
        var serializeError: NSError?
        if let request = sessionManager.requestSerializer.multipartFormRequestWithMethod("POST", URLString: url, parameters: parameters as! [String:String], constructingBodyWithBlock: { formData in
            let data: AFMultipartFormData = formData
            data.appendPartWithFileData(keyPackets, name: "KeyPackets", fileName: "KeyPackets.txt", mimeType: "" )
            data.appendPartWithFileData(dataPacket, name: "DataPacket", fileName: "DataPacket.txt", mimeType: "" )
            
            }, error: &serializeError) {
                let uploadTask = self.sessionManager.uploadTaskWithStreamedRequest(request, progress: nil) { (response, responseObject, error) -> Void in
                    completion?(task: nil, response: responseObject as? Dictionary<String,AnyObject>, error: error)
                }
                uploadTask.resume()
        }
    }
    
    func request(#method: HTTPMethod, path: String, parameters: AnyObject?, authenticated: Bool = true, completion: CompletionBlock?) {
        let authBlock: AuthCredentialBlock = { _, error in
            if error == nil {
                let (successBlock, failureBlock) = self.afNetworkingBlocksForRequest(method: method, path: path, parameters: parameters, authenticated: authenticated, completion: completion)

                switch(method) {
                case .DELETE:
                    self.sessionManager.DELETE(path, parameters: parameters, success: successBlock, failure: failureBlock)
                case .POST:
                    self.sessionManager.POST(path, parameters: parameters, success: successBlock, failure: failureBlock)
                case .PUT:
                    self.sessionManager.PUT(path, parameters: parameters, success: successBlock, failure: failureBlock)
                default:
                    self.sessionManager.GET(path, parameters: parameters, success: successBlock, failure: failureBlock)
                }
            } else {
                completion?(task: nil, response: nil, error: error)
            }
        }
        
        if authenticated {
            fetchAuthCredential(completion: authBlock)
        } else {
            authBlock(nil, nil)
        }
    }
    
    // MARK: - Private methods
    private func setupValueTransforms() {
        let boolTransformer = GRTValueTransformer.reversibleTransformerWithBlock { (value) -> AnyObject! in
            if let bool = value as? NSString {
                return bool.boolValue
            } else if let bool = value as? Bool {
                return bool
            }
            
            return nil
        }
        NSValueTransformer.setValueTransformer(boolTransformer, forName: "BoolTransformer")
        
        let dateTransformer = GRTValueTransformer.reversibleTransformerWithBlock { (value) -> AnyObject! in
            if let timeString = value as? NSString {
                let time = timeString.doubleValue as NSTimeInterval
                if time != 0 {
                    return time.asDate()
                }
            } else if let date = value as? NSDate {
                return date.timeIntervalSince1970
            } else if let dateNumber = value as? NSNumber {
                let time = dateNumber.doubleValue as NSTimeInterval
                if time != 0 {
                    return time.asDate()
                }
            }
            
            return nil
        }
        NSValueTransformer.setValueTransformer(dateTransformer, forName: "DateTransformer")
        
        let numberTransformer = GRTValueTransformer.reversibleTransformerWithBlock { (value) -> AnyObject! in
            if let number = value as? String {
                return number.toInt() ?? 0 as NSNumber
            } else if let number = value as? NSNumber {
                return number
            }
            
            return nil
        }
        NSValueTransformer.setValueTransformer(numberTransformer, forName: "NumberTransformer")
        
        let tagTransformer = GRTValueTransformer.reversibleTransformerWithBlock { (value) -> AnyObject! in
            if let tag = value as? String {
                return tag.rangeOfString(Message.Constants.starredTag) != nil
            }
            
            return nil
        }
        
        let JsonStringTransformer = GRTValueTransformer.reversibleTransformerWithBlock { (value) -> AnyObject! in
            if let tag = value as? NSArray {
                let bytes : NSData = NSJSONSerialization.dataWithJSONObject(tag, options: NSJSONWritingOptions.allZeros, error: nil)!
                let strJson : String = NSString(data: bytes, encoding: NSUTF8StringEncoding)! as String
                return strJson
            }
            return "";
        }
        NSValueTransformer.setValueTransformer(JsonStringTransformer, forName: "JsonStringTransformer")
        
        let encodedDataTransformer = GRTValueTransformer.reversibleTransformerWithBlock { (value) -> NSData! in
            if let tag = value as? String {
                if let data: NSData = NSData(base64EncodedString: tag, options: NSDataBase64DecodingOptions(rawValue: 0)) {
                    return data
                }
            }
            return nil;
        }
        NSValueTransformer.setValueTransformer(JsonStringTransformer, forName: "EncodedDataTransformer")
        
        let transforDataNoID = GRTValueTransformer.reversibleTransformerWithBlock { (value) -> AnyObject! in
            if let idArray = value as? NSArray {
                var fixedArray = [Dictionary<String, AnyObject>]()
                for labelID in idArray {
                    fixedArray.append(["ID" : labelID])
                }
                return fixedArray
            }
            return value;
        }
        NSValueTransformer.setValueTransformer(transforDataNoID, forName: "TransforDataNoID")
    }
}

