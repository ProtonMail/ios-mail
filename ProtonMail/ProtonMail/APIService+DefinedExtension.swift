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
    
    struct GeneralResponse {
        static let errorCode = "Code"
        static let errorMsg = "Error"
        static let errorDesc = "ErrorDescription"
    }
    
    internal typealias CompletionBlock = (task: NSURLSessionDataTask!, response: Dictionary<String,AnyObject>?, error: NSError?) -> Void
    internal typealias CompletionFetchDetail = (task: NSURLSessionDataTask!, response: Dictionary<String,AnyObject>?, message:Message?, error: NSError?) -> Void
    
    // MARK: - Internal variables
    
    internal typealias AFNetworkingFailureBlock = (NSURLSessionDataTask!, NSError!) -> Void
    internal typealias AFNetworkingSuccessBlock = (NSURLSessionDataTask!, AnyObject!) -> Void
    
    
    internal typealias AuthCredentialBlock = (AuthCredential?, NSError?) -> Void
    internal typealias AuthInfo = (accessToken: String?, expiresId: NSTimeInterval?, refreshToken: String?, userID: String?)
    
    
    internal typealias AuthComplete = (task: NSURLSessionDataTask?, mailpassword: String?, hasError : NSError?) -> Void
    internal typealias AuthRefreshComplete = (task: NSURLSessionDataTask?, auth:AuthCredential?, hasError : NSError?) -> Void
    
    
    
    enum AuthStatus {
        case ResCheck
        case Ask2FA
    }
    
    internal typealias AuthCompleteBlock = (task: NSURLSessionDataTask?, mailpassword: String?, authStatus: AuthStatus, error : NSError?) -> Void

}
