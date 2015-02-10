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
    
    let sessionManager: AFHTTPSessionManager
    
    init() {
        sessionManager = AFHTTPSessionManager(baseURL: NSURL(string: BaseURLString)!)
        sessionManager.requestSerializer = AFJSONRequestSerializer() as AFHTTPRequestSerializer
    }
    
    func fetchAuthCredential(#success: AuthSuccessBlock, failure: FailureBlock) {
        if let credential = AuthCredential.fetchFromKeychain() {
            if !credential.isExpired {
                self.sessionManager.requestSerializer.setAuthorizationHeaderFieldWithCredential(credential)
                NSLog("credential: \(credential)")
                success(credential)
            } else {
                // TODO: Replace with logic that will refresh the authToken.
                failure(APIError.authCredentialExpired.asNSError())
            }
        } else {
            // TODO: Replace with logic that prompt for username and password, if needed.
            failure(APIError.authCredentialInvalid.asNSError())
        }
    }
    
    func GET(path: String, parameters: AnyObject?, success: SuccessBlock, failure: FailureBlock) {
        let authSuccess: AuthSuccessBlock = { auth in
            let successBlock = self.networkingSuccessBlockForFailure(failure, success: success)
            let failureBlock = self.networkingFailureBlockForFailure(failure)
            
            self.sessionManager.GET(path, parameters: parameters, success: successBlock, failure: failureBlock)
        }
        
        fetchAuthCredential(success: authSuccess, failure: failure)
    }
    
    func isErrorResponse(response: AnyObject!) -> Bool {
        if let dict = response as? NSDictionary {
            return dict["error"] != nil
        }
        
        return false
    }
    
    // MARK: - Private methods
    
    private func networkingFailureBlockForFailure(failure: FailureBlock) -> AFNetworkingFailureBlock {
        return { task, error in
            failure(error)
        }
    }
    
    private func networkingSuccessBlockForFailure(failure: FailureBlock, success: SuccessBlock) -> AFNetworkingSuccessBlock {
        return { task, responseObject in
            if let response = responseObject as? NSDictionary {
                success(response)
            } else {
                failure(APIError.unableToParseResponse.asNSError())
            }
        }
    }
}
