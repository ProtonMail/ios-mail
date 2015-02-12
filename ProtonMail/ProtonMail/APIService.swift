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
    
    internal enum Method: String {
        case PUT = "PUT"
    }
    
    // MARK: - Private variables
    
    internal let sessionManager: AFHTTPSessionManager
    
    private var writeInProgress: Bool = false
    private let writeQueue: NetworkQueue
    
    // MARK: - Internal methods
    
    init() {
        sessionManager = AFHTTPSessionManager(baseURL: NSURL(string: BaseURLString)!)
        sessionManager.requestSerializer = AFJSONRequestSerializer() as AFHTTPRequestSerializer
        
        writeQueue = NetworkQueue(queueName: "writeQueue")
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
    
    internal func GET(path: String, parameters: AnyObject?, success: SuccessBlock, failure: FailureBlock?) {
        let authSuccess: AuthSuccessBlock = { auth in
            let failureBlock: AFNetworkingFailureBlock = { task, error in
                failure?(error)
                return
            }
            
            let successBlock: AFNetworkingSuccessBlock = { task, responseObject in
                if let response = responseObject as? NSDictionary {
                    success(response)
                } else {
                    failure?(APIError.unableToParseResponse.asNSError())
                }
            }
            
            self.sessionManager.GET(path, parameters: parameters, success: successBlock, failure: failureBlock)
        }
        
        fetchAuthCredential(success: authSuccess, failure: failure)
    }
    
    internal func isErrorResponse(response: AnyObject!) -> Bool {
        if let dict = response as? NSDictionary {
            return dict["error"] != nil
        }
        
        return false
    }
    
    internal func writeRequest(method: Method, path: String, parameters: AnyObject?) {
        writeQueue.addRequest(method: method.rawValue, path: path, parameters: parameters)
        processQueueIfNeeded(writeQueue)
    }
    
    // MARK: - Private methods
    
    private func processQueueIfNeeded(queue: NetworkQueue) {
        if writeInProgress {
            return
        }
        
        if let (uuid, methodString, path, parameters: AnyObject?) = queue.nextRequest() {
            let method = Method(rawValue: methodString)
            
            let failureBlock: AFNetworkingFailureBlock  = { (task, error) in
                NSLog("\(__FUNCTION__) failed with error: \(error)")
                
                // TODO: add authentication failure handling
                
                self.writeInProgress = false
            }
            
            let successBlock: AFNetworkingSuccessBlock = { (task, responseObject) in
                if let response = responseObject as? NSDictionary {
                    
                } else {
                    NSLog("\(__FUNCTION__) unable to parse response:\n\(responseObject)\nRemoving from queue.")
                }
                
                queue.remove(elementID: uuid)
                
                self.writeInProgress = false
                
                self.processQueueIfNeeded(queue)
            }
            
            var authSuccess: AuthSuccessBlock
            
            switch(method) {
            case .Some(.PUT):
                authSuccess = { auth in
                    self.sessionManager.PUT(path, parameters: parameters, success: successBlock, failure: failureBlock)
                    return
                }
            default:
                NSLog("\(__FUNCTION__) Unsupported method \(methodString), removing from queue.")
                queue.remove(elementID: uuid)
                
                return
            }
            
            writeInProgress = true
            
            fetchAuthCredential(success: authSuccess, failure: { error in
                self.writeInProgress = false})
        }
    }
}
