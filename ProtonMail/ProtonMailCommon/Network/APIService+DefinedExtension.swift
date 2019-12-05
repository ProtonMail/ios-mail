//
//  APIService+DefinedExtension.swift
//  ProtonMail - Created on 8/16/16.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


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
    internal typealias AuthCompleteBlock        = (_ task: URLSessionDataTask?, _ mailpassword: String?, _ authStatus: AuthStatus, _ res: AuthResponse?, _ error : NSError?) -> Void

}
