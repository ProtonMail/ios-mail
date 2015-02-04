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
    
    func fetchAuthCredential(#success: (AuthCredential -> Void), failure: (NSError -> Void)) {
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
    
    func isErrorResponse(response: AnyObject!) -> Bool {
        if let dict = response as? NSDictionary {
            return dict["error"] != nil
        }
        
        return false
    }
    
    func newManagedObjectContext() -> NSManagedObjectContext {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.parentContext = appDelegate.managedObjectContext

        return managedObjectContext
    }
}
