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
import ProtonCore_Networking
import ProtonCore_Services
import class ProtonCore_Services.APIErrorCode

extension APIErrorCode {
    static let forcePasswordChange = 2011

    // Device token
    static let deviceTokenIsInvalid = 11200
    static let deviceTokenDoesNotExist = 11211

}

// MARK: - NSError APIService extension

// localized
extension NSError {

    class func apiServiceError(code: Int, localizedDescription: String, localizedFailureReason: String?, localizedRecoverySuggestion: String? = nil) -> NSError {
        return NSError(
            domain: APIServiceErrorDomain,
            code: code,
            localizedDescription: localizedDescription,
            localizedFailureReason: localizedFailureReason,
            localizedRecoverySuggestion: localizedRecoverySuggestion)
    }

    // FIXME: fix message content
    class func userLoggedOut() -> NSError {
        return apiServiceError(code: 9999,
                               localizedDescription: "Sender account has been logged out!",
                               localizedFailureReason: "Sender account has been logged out!")
    }

    class func badParameter(_ parameter: Any?) -> NSError {
        let desc: String
        if let parameter = parameter {
            desc = String(describing: parameter)
        } else {
            desc = ""
        }
        return apiServiceError(
            code: APIErrorCode.badParameter,
            localizedDescription: LocalString._error_bad_parameter_title,
            localizedFailureReason: String(format: LocalString._error_bad_parameter_desc, "\(desc)"))
    }

    class func badResponse() -> NSError {
        return apiServiceError(
            code: APIErrorCode.badResponse,
            localizedDescription: LocalString._error_bad_response_title,
            localizedFailureReason: LocalString._error_cant_parse_response_body)
    }
    // TODO:: move to other place
    class func encryptionError() -> NSError {
        return apiServiceError(
            code: APIErrorCode.badParameter,
            localizedDescription: "Attachment encryption failed",
            localizedFailureReason: "Attachment encryption failed")
    }
    class func lockError() -> NSError {
        return apiServiceError(
            code: APIErrorCode.badParameter,
            localizedDescription: "App was locked",
            localizedFailureReason: "You had locked the app before it managed to finish its task. Please try again")
    }

    class func unableToParseResponse(_ response: Any?) -> NSError {
        let noObject = LocalString._error_no_object
        return apiServiceError(
            code: APIErrorCode.unableToParseResponse,
            localizedDescription: LocalString._error_unable_to_parse_response_title,
            localizedFailureReason: String(format: LocalString._error_unable_to_parse_response_desc, "\(response ?? noObject)"))
    }
}

extension ResponseError {
    var toNSError: NSError {
        if let responseCode = responseCode {
            return NSError(domain: "ch.proton.ProtonCore.ResponseError", code: responseCode, localizedDescription: localizedDescription)
        } else {
            return underlyingError ?? (self as NSError)
        }
    }
}
