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

let sharedAPIService = APIService()

class APIService {
    typealias AFNetworkingFailureBlock = (NSURLSessionDataTask!, NSError!) -> Void
    typealias AFNetworkingSuccessBlock = (NSURLSessionDataTask!, AnyObject!) -> Void
    typealias AuthSuccessBlock = AuthCredential -> Void
    typealias CompletionBlock = NSError? -> Void
    typealias FailureBlock = NSError -> Void
    typealias SuccessBlock = NSDictionary -> Void
    
    enum APIError: Int {
        case authCredentialExpired
        case authCredentialInvalid
        case authInvalidGrant
        case authUnableToParseToken
        case unableToParseResponse
        case userNone
        case unknown
        
        var code: Int {
            switch(self) {
            default:
                return 0
            }
        }
        
        var localizedDescription: String {
            switch(self) {
            case .authCredentialInvalid:
                return NSLocalizedString("Invalid credential")
            case .authCredentialExpired:
                return NSLocalizedString("Token expired")
            case .authInvalidGrant:
                return NSLocalizedString("Invalid grant")
            case .authUnableToParseToken:
                return NSLocalizedString("Unable to parse token")
            case .unableToParseResponse:
                return NSLocalizedString("Unable to parse response")
            default:
                return NSLocalizedString("Unknown error")
            }
        }
        
        var localizedFailureReason: String? {
            switch(self) {
            case .authCredentialInvalid:
                return NSLocalizedString("The authentication credentials are invalid.")
            case .authCredentialExpired:
                return NSLocalizedString("The authentication token has expired.")
            case .authInvalidGrant:
                return NSLocalizedString("The supplied credentials are invalid.")
            case .authUnableToParseToken:
                return NSLocalizedString("Unable to parse authentication token!")
            case .unableToParseResponse:
                return NSLocalizedString("Unable to parse the response object.")
            default:
                return nil
            }
        }
        
        var localizedRecoverySuggestion: String? {
            switch(self) {
            default:
                return nil
            }
        }
        
        func asNSError() -> NSError {
            return NSError.protonMailError(code: code, localizedDescription: localizedDescription, localizedFailureReason: localizedFailureReason, localizedRecoverySuggestion: localizedRecoverySuggestion)
        }
    }
    
    // MARK: - Private variables
    
    internal let sessionManager: AFHTTPSessionManager
    
    // MARK: - Internal methods
    
    init() {
        sessionManager = AFHTTPSessionManager(baseURL: NSURL(string: BaseURLString)!)
        sessionManager.requestSerializer = AFJSONRequestSerializer() as AFHTTPRequestSerializer
        
        setupValueTransforms()
    }
    
    internal func fetchAuthCredential(#success: AuthSuccessBlock, failure: FailureBlock?) {
        if let credential = AuthCredential.fetchFromKeychain() {
            if !credential.isExpired {
                self.sessionManager.requestSerializer.setAuthorizationHeaderFieldWithCredential(credential)
                NSLog("credential: \(credential)")
                success(credential)
            } else {
                // TODO: Replace with logic that will refresh the authToken.
                failure?(APIError.authCredentialExpired.asNSError())
            }
        } else {
            // TODO: Replace with logic that prompt for username and password, if needed.
            failure?(APIError.authCredentialInvalid.asNSError())
        }
    }
    
    internal func isErrorResponse(response: AnyObject!) -> Bool {
        if let dict = response as? NSDictionary {
            return dict["error"] != nil
        }
        
        return false
    }
    
    // MARK: - Request methods
    
    internal func DELETE(path: String, parameters: AnyObject?, completion: CompletionBlock?) {
        let authSuccess: AuthSuccessBlock = { auth in
            let failureBlock = self.afNetworkingFailureBlockForCompletion(completion)
            let successBlock = self.afNetworkingSuccessBlockForCompletion(completion)
            
            self.sessionManager.DELETE(path, parameters: parameters, success: successBlock, failure: failureBlock)
        }
        
        fetchAuthCredential(success: authSuccess, failure: completion)
    }
    
    internal func DELETE(path: String, parameters: AnyObject?, success: (AnyObject? -> Void)?, failure: FailureBlock?) {
        let authSuccess: AuthSuccessBlock = { auth in
            let failureBlock = self.afNetworkingFailureBlockForFailure(failure)
            let successBlock = self.afNetworkingSuccessBlockForSuccess(success)
            
            self.sessionManager.DELETE(path, parameters: parameters, success: successBlock, failure: failureBlock)
        }
        
        fetchAuthCredential(success: authSuccess, failure: failure)
    }
    
    internal func GET(path: String, parameters: AnyObject?, success: SuccessBlock?, failure: FailureBlock?) {
        let authSuccess: AuthSuccessBlock = { auth in
            let failureBlock = self.afNetworkingFailureBlockForFailure(failure)
            let successBlock: AFNetworkingSuccessBlock = { task, responseObject in
                if let response = responseObject as? NSDictionary {
                    success?(response)
                } else {
                    failure?(APIError.unableToParseResponse.asNSError())
                }
            }
            
            self.sessionManager.GET(path, parameters: parameters, success: successBlock, failure: failureBlock)
        }
        
        fetchAuthCredential(success: authSuccess, failure: failure)
    }

    internal func POST(path: String, parameters: AnyObject?, completion: CompletionBlock?) {
        let authSuccess: AuthSuccessBlock = { auth in
            let failureBlock = self.afNetworkingFailureBlockForCompletion(completion)
            let successBlock = self.afNetworkingSuccessBlockForCompletion(completion)
            
            self.sessionManager.POST(path, parameters: parameters, success: successBlock, failure: failureBlock)
        }
        
        fetchAuthCredential(success: authSuccess, failure: completion)
    }
    internal func POST(path: String, parameters: AnyObject?, success: (AnyObject? -> Void)?, failure: FailureBlock?) {
        let authSuccess: AuthSuccessBlock = { auth in
            let failureBlock = self.afNetworkingFailureBlockForFailure(failure)
            let successBlock = self.afNetworkingSuccessBlockForSuccess(success)
            
            self.sessionManager.POST(path, parameters: parameters, success: successBlock, failure: failureBlock)
        }
        
        fetchAuthCredential(success: authSuccess, failure: failure)
    }
    
    internal func PUT(path: String, parameters: AnyObject?, completion: CompletionBlock?) {
        let authSuccess: AuthSuccessBlock = { auth in
            let failureBlock = self.afNetworkingFailureBlockForCompletion(completion)
            let successBlock = self.afNetworkingSuccessBlockForCompletion(completion)
            
            self.sessionManager.PUT(path, parameters: parameters, success: successBlock, failure: failureBlock)
        }
        
        fetchAuthCredential(success: authSuccess, failure: completion)
    }
    
    internal func PUT(path: String, parameters: AnyObject?, success: (AnyObject? -> Void)?, failure: FailureBlock?) {
        let authSuccess: AuthSuccessBlock = { auth in
            let failureBlock = self.afNetworkingFailureBlockForFailure(failure)
            let successBlock = self.afNetworkingSuccessBlockForSuccess(success)
            
            self.sessionManager.PUT(path, parameters: parameters, success: successBlock, failure: failureBlock)
        }
        
        fetchAuthCredential(success: authSuccess, failure: failure)
    }
    
    // MARK: - Private methods
    
    private func afNetworkingFailureBlockForCompletion(completion: CompletionBlock?) -> AFNetworkingFailureBlock? {
        if let completion = completion {
            return { task, error in
                completion(error)
            }
        }
        
        return nil
    }
    
    private func afNetworkingFailureBlockForFailure(failure: FailureBlock?) -> AFNetworkingFailureBlock? {
        if let failure = failure {
            return { task, error in
                failure(error)
            }
        }
        
        return nil
    }
    
    private func afNetworkingSuccessBlockForCompletion(completion: CompletionBlock?) -> AFNetworkingSuccessBlock? {
        if let completion = completion {
            return { task, responseObject in
                completion(nil)
            }
        }
        
        return nil
    }
    
    private func afNetworkingSuccessBlockForSuccess(success: (AnyObject? -> Void)?) -> AFNetworkingSuccessBlock? {
        if let success = success {
            return { task, responseObject in
                success(responseObject)
            }
        }
        
        return nil
    }
    
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
