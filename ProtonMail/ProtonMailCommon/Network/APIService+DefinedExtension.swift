//
//  APIService+DefinedExtension.swift
//  ProtonMail - Created on 8/16/16.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
        static let errorCode = "Code"
        static let errorMsg  = "Error"
    }
    
    internal typealias CompletionBlock = (_ task: URLSessionDataTask?, _ response: [String : Any]?, _ error: NSError?) -> Void
    internal typealias CompletionFetchDetail = (_ task: URLSessionDataTask?, _ response: [String : Any]?, _ message:Message.ObjectIDContainer?, _ error: NSError?) -> Void

    // MARK: - Internal variables
    
    internal typealias AFNetworkingFailureBlock = (URLSessionDataTask?, Error?) -> Void
    internal typealias AFNetworkingSuccessBlock = (URLSessionDataTask?, Any?) -> Void

    internal typealias AuthInfo                 = (accessToken: String?, expiresId: TimeInterval?, refreshToken: String?, userID: String?)
    internal typealias AuthComplete             = (_ task: URLSessionDataTask?, _ mailpassword: String?, _ hasError : NSError?) -> Void
    internal typealias AuthRefreshComplete      = (_ task: URLSessionDataTask?, _ auth:AuthCredential?, _ hasError : NSError?) -> Void

    
    internal typealias AuthCredentialBlock      = (AuthCredential?, NSError?) -> Void
    internal typealias AuthCompleteBlock        = (_ task: URLSessionDataTask?, _ mailpassword: String?, _ authStatus: AuthStatus, _ error : NSError?) -> Void

}
