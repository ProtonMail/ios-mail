//
//  APIErrors.swift
//  ProtonMail - Created on 7/20/15.
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

public class APIErrorCode {
    static public let responseOK = 1000
    
    static public let HTTP503 = 503
    static public let HTTP504 = 504
    static public let HTTP404 = 404
    
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
        static public let networkIusse = -1004
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
    
    //FIXME: fix message content
    public class func userLoggedOut() -> NSError {
        return apiServiceError(code: 9999,
                               localizedDescription: "Sender account has been logged out!",
                               localizedFailureReason: "Sender account has been logged out!")
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
            localizedDescription: "App was locked",
            localizedFailureReason: "You had locked the app before it managed to finish its task. Please try again")
    }
    
    public class func unableToParseResponse(_ response: Any?) -> NSError {
        let noObject = LocalString._error_no_object
        return apiServiceError(
            code: APIErrorCode.unableToParseResponse,
            localizedDescription: LocalString._error_unable_to_parse_response_title,
            localizedFailureReason: String(format: LocalString._error_unable_to_parse_response_desc, "\(response ?? noObject)"))
    }
}

