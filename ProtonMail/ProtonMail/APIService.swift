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

private let BaseURLString = "http://protonmail.xyz"

let APIServiceErrorDomain = NSError.protonMailErrorDomain(subdomain: "APIService")

let sharedAPIService = APIService()

class APIService {

    typealias CompletionBlock = (NSURLSessionDataTask!, Dictionary<String,AnyObject>?, NSError?) -> Void

    struct ErrorCode {
        static let unableToParseResponse = 1
    }

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
    
    // MARK: - Internal methods
    
    init() {
        sessionManager = AFHTTPSessionManager(baseURL: NSURL(string: BaseURLString)!)
        sessionManager.requestSerializer = AFJSONRequestSerializer() as AFHTTPRequestSerializer
        
        setupValueTransforms()
    }

    internal func afNetworkingBlocksForCompletion(completion: CompletionBlock?) -> (AFNetworkingSuccessBlock?, AFNetworkingFailureBlock?) {
        if let completion = completion {
            let failure: AFNetworkingFailureBlock = { task, error in
                completion(task, nil, error)
            }
            let success: AFNetworkingSuccessBlock = { task, responseObject in
                if let responseDictionary = responseObject as? Dictionary<String, AnyObject> {
                    completion(task, responseDictionary, nil)
                } else if responseObject == nil {
                    completion(task, [:], nil)
                } else {
                    completion(task, nil, NSError.unableToParseResponse(responseObject))
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
                completion?(task, nil, error)
            } else {
                if let parsedResponse = response?[key] as? Dictionary<String, AnyObject> {
                    completion?(task, parsedResponse, nil)
                } else {
                    completion?(task, nil, NSError.unableToParseResponse(response))
                }
            }
        }
    }
    
    internal func fetchAuthCredential(#completion: AuthCredentialBlock) {
        if let credential = AuthCredential.fetchFromKeychain() {
            if !credential.isExpired {
                self.sessionManager.requestSerializer.setAuthorizationHeaderFieldWithCredential(credential)
                NSLog("credential: \(credential)")
                completion(credential, nil)
            } else {
                // TODO: Replace with logic that will refresh the authToken.
                completion(nil, NSError.authCredentialExpired())
            }
        } else {
            // TODO: Replace with logic that prompt for username and password, if needed.
            completion(nil, NSError.authCredentialInvalid())
        }
    }
    
    // MARK: - Request methods
    
    internal func request(#method: HTTPMethod, path: String, parameters: AnyObject?, authenticated: Bool = true, completion: CompletionBlock?) {
        let authBlock: AuthCredentialBlock = { _, error in
            if error == nil {
                let (successBlock, failureBlock) = self.afNetworkingBlocksForCompletion(completion)
                
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
                completion?(nil, nil, error)
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
        let dateTransformer = GRTValueTransformer.reversibleTransformerWithBlock { (value) -> AnyObject! in
            if let timeString = value as? NSString {
                let time = timeString.doubleValue as NSTimeInterval
                if time != 0 {
                    return time.asDate()
                }
            } else if let date = value as? NSDate {
                return date.timeIntervalSince1970
            }
            
            return nil
        }
        
        NSValueTransformer.setValueTransformer(dateTransformer, forName: "DateTransformer")

        let numberTransformer = GRTValueTransformer.reversibleTransformerWithBlock { (value) -> AnyObject! in
            if let number = value as? String {
                return number.toInt() ?? 0 as NSNumber
            } else if let number = value as? NSNumber {
                return number.stringValue
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
        
        NSValueTransformer.setValueTransformer(tagTransformer, forName: "TagTransformer")
    }
}

// MARK: - NSError APIService extension

extension NSError {
    
    class func apiServiceError(#code: Int, localizedDescription: String, localizedFailureReason: String?, localizedRecoverySuggestion: String? = nil) -> NSError {
        return NSError(
            domain: APIServiceErrorDomain,
            code: code,
            localizedDescription: localizedDescription,
            localizedFailureReason: localizedFailureReason,
            localizedRecoverySuggestion: localizedRecoverySuggestion)
    }
    
    class func unableToParseResponse(response: AnyObject?) -> NSError {
        let noObject = NSLocalizedString("<no object>")
        
        return apiServiceError(
            code: APIService.ErrorCode.unableToParseResponse,
            localizedDescription: NSLocalizedString("Unable to parse response"),
            localizedFailureReason: NSLocalizedString("Unable to parse the response object:\n\(response ?? noObject)"))
    }
}
