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
        case delete
        case get
        case post
        case put
        
        func toString() -> String {
            switch self {
            case .delete:
                return "DELETE"
            case .get:
                return "GET"
            case .post:
                return "POST"
            case .put:
                return "PUT"
            }
        }
    }
    
    enum AuthStatus {
        case resCheck
        case ask2FA
    }
    
    struct GeneralResponse {
        static let errorCode                    = "Code"
        static let errorMsg                     = "Error"
        static let errorDesc                    = "ErrorDescription"
    }
    
    internal typealias CompletionBlock = (_ task: URLSessionDataTask?, _ response: [String : Any]?, _ error: NSError?) -> Void
    internal typealias CompletionFetchDetail = (_ task: URLSessionDataTask?, _ response: [String : Any]?, _ message:Message?, _ error: NSError?) -> Void

    // MARK: - Internal variables
    
    internal typealias AFNetworkingFailureBlock = (URLSessionDataTask?, Error?) -> Void
    internal typealias AFNetworkingSuccessBlock = (URLSessionDataTask?, Any?) -> Void

    internal typealias AuthInfo                 = (accessToken: String?, expiresId: TimeInterval?, refreshToken: String?, userID: String?)
    internal typealias AuthComplete             = (_ task: URLSessionDataTask?, _ mailpassword: String?, _ hasError : NSError?) -> Void
    internal typealias AuthRefreshComplete      = (_ task: URLSessionDataTask?, _ auth:AuthCredential?, _ hasError : NSError?) -> Void

    
    internal typealias AuthCredentialBlock      = (AuthCredential?, NSError?) -> Void
    internal typealias AuthCompleteBlock        = (_ task: URLSessionDataTask?, _ mailpassword: String?, _ authStatus: AuthStatus, _ error : NSError?) -> Void

}
