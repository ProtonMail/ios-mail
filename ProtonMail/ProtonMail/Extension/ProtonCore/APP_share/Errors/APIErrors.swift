//
//  APIErrors.swift
//  Proton Mail - Created on 7/20/15.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCoreNetworking
import ProtonCoreServices
import class ProtonCoreServices.APIErrorCode

extension APIErrorCode {
    static let forcePasswordChange = 2011
    /// The error means "Message has already been sent"
    static let alreadyExist = 2500
    /// Close the composer where the message has already been sent
    static let updateDraftHasBeenSent = 15034
    static let resourceDoesNotExist = 2501
    /// The model exists but its current state doesn't allow to execute the action
    static let incompatible = 2511
    static let invalidRequirements = 2000

    static let deviceHavingLowConnectivity = 111222333
    /// Total size or number of attachments exceeds limit
    /// Maximum size is 25mb
    /// Maximum number is 100 attachments
    static let tooManyAttachments = 2024
    /// Even though the error code is the same as for `tooManyAttachments`, this error can also be returned when we do an operation
    /// that requires storage and the user has reached the limit (e.g. create a contact)
    static let storageQuotaExceeded = 2024

    /// For example, trying to upload attachment when account storage usage is 101mb/100mb
    static let accountStorageQuotaExceeded = 11100
    static let connectionAppearsToBeOffline = -1009
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
