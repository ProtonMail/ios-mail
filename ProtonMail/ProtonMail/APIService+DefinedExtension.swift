//
//  APIService+DefinedExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/16/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation

extension APIService {
    
    enum HTTPMethod {
        case DELETE
        case GET
        case POST
        case PUT
    }
    
    
    typealias CompletionBlock = (task: NSURLSessionDataTask!, response: Dictionary<String,AnyObject>?, error: NSError?) -> Void
    typealias CompletionFetchDetail = (task: NSURLSessionDataTask!, response: Dictionary<String,AnyObject>?, message:Message?, error: NSError?) -> Void
    
    // MARK: - Internal variables
    
    internal typealias AFNetworkingFailureBlock = (NSURLSessionDataTask!, NSError!) -> Void
    internal typealias AFNetworkingSuccessBlock = (NSURLSessionDataTask!, AnyObject!) -> Void
    
    
    
    typealias AuthCredentialBlock = (AuthCredential?, NSError?) -> Void
    typealias AuthInfo = (accessToken: String?, expiresId: NSTimeInterval?, refreshToken: String?, userID: String?)
    
    
    typealias AuthComplete = (task: NSURLSessionDataTask?, hasError : NSError?) -> Void
    typealias AuthRefreshComplete = (task: NSURLSessionDataTask?, auth:AuthCredential?, hasError : NSError?) -> Void
    
    
    struct GeneralResponse {
        static let errorCode = "Code"
        static let errorMsg = "Error"
        static let errorDesc = "ErrorDescription"
    }
}