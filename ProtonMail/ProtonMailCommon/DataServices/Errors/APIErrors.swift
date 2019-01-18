//
//  APIErrors.swift
//  ProtonMail - Created on 7/20/15.
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

public class APIErrorCode {
    static public let responseOK = 1000
    
    static public let HTTP503 = 503
    static public let HTTP504 = 504
    
    static public let badParameter = 1
    static public let badPath = 2
    static public let unableToParseResponse = 3
    static public let badResponse = 4
    
    public struct AuthErrorCode {
        static public let credentialExpired = 10
        static public let credentialInvalid = 20
        static public let invalidGrant = 30
        static public let unableToParseToken = 40
        static public let localCacheBad = 50
        static public let networkIusse = 60
        static public let unableToParseAuthInfo = 70
        static public let authServerSRPInValid = 80
        static public let authUnableToGenerateSRP = 90
        static public let authUnableToGeneratePwd = 100
        static public let authInValidKeySalt = 110
        
        static public let authCacheLocked = 665
        
        static public let Cache_PasswordEmpty = 0x10000001
    }
    
    static public let API_offline = 7001
    
    public struct UserErrorCode {
        static public let userNameExsit = 12011
        static public let currentWrong = 12021
        static public let newNotMatch = 12022
        static public let pwdUpdateFailed = 12023
        static public let pwdEmpty = 12024
    }

}


// MARK: - NSError APIService extension

//localized
extension NSError {
    
    public class func apiServiceError(code: Int, localizedDescription: String, localizedFailureReason: String?, localizedRecoverySuggestion: String? = nil) -> NSError {
        return NSError(
            domain: APIServiceErrorDomain,
            code: code,
            localizedDescription: localizedDescription,
            localizedFailureReason: localizedFailureReason,
            localizedRecoverySuggestion: localizedRecoverySuggestion)
    }
    
    public class func badParameter(_ parameter: Any?) -> NSError {
        return apiServiceError(
            code: APIErrorCode.badParameter,
            localizedDescription: LocalString._error_bad_parameter_title,
            localizedFailureReason: String(format: LocalString._error_bad_parameter_desc, "\(String(describing: parameter))"))
    }
    
    public class func badResponse() -> NSError {
        return apiServiceError(
            code: APIErrorCode.badResponse,
            localizedDescription: LocalString._error_bad_response_title,
            localizedFailureReason: LocalString._error_cant_parse_response_body)
    }
    //TODO:: move to other place
    public class func encryptionError() -> NSError {
        return apiServiceError(
            code: APIErrorCode.badParameter,
            localizedDescription: "Attachment encryption failed",
            localizedFailureReason: "Attachment encryption failed")
    }
    public class func lockError() -> NSError {
        return apiServiceError(
            code: APIErrorCode.badParameter,
            localizedDescription: "Parameter locked or cache unaccessible",
            localizedFailureReason: "Parameter locked or cache unaccessible")
    }
    
    public class func unableToParseResponse(_ response: Any?) -> NSError {
        let noObject = LocalString._error_no_object
        return apiServiceError(
            code: APIErrorCode.unableToParseResponse,
            localizedDescription: LocalString._error_unable_to_parse_response_title,
            localizedFailureReason: String(format: LocalString._error_unable_to_parse_response_desc, "\(response ?? noObject)"))
    }
}

