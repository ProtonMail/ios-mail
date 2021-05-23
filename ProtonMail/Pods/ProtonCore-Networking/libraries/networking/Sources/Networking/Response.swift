//
//  Response.swift
//  Pods
//
//  Created on 5/25/20.
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

// swiftlint:disable identifier_name todo

import Foundation

public struct ResponseError: Error, Equatable {

    public let httpCode: Int?
    public let responseCode: Int?
    public let userFacingMessage: String?
    public let underlyingError: NSError?

    public var localizedDescription: String { userFacingMessage ?? underlyingError?.localizedDescription ?? "" }

    public init(httpCode: Int?, responseCode: Int?, userFacingMessage: String?, underlyingError: NSError?) {
        self.httpCode = httpCode
        self.responseCode = responseCode
        self.userFacingMessage = userFacingMessage
        self.underlyingError = underlyingError
    }

    public func withUpdated(userFacingMessage: String) -> ResponseError {
        ResponseError(httpCode: httpCode, responseCode: responseCode, userFacingMessage: userFacingMessage, underlyingError: underlyingError)
    }

    public func withUpdated(underlyingError: LocalizedError) -> ResponseError {
        ResponseError(httpCode: httpCode,
                      responseCode: responseCode,
                      userFacingMessage: underlyingError.localizedDescription,
                      underlyingError: underlyingError as NSError)
    }
}

public protocol ResponseType: AnyObject {
    var responseCode: Int? { get set }
    var httpCode: Int? { get set }
    var error: ResponseError? { get set }
    init()
    func ParseResponse(_ response: [String: Any]) -> Bool
}

public extension ResponseType {

    static func parseNetworkCallResults<T>(
        to: T.Type, response: URLResponse?, responseDict: [String: Any]?, error: NSError?
    ) -> (T, ResponseError?) where T: ResponseType {
        let apiRes = T()

        if let error = error {
            let networkingError = apiRes.parseTaskError(response: response, taskError: error, responseDict: responseDict)
            return (apiRes, networkingError)
        }

        var hasError = apiRes.parseResponseError(responseDict: responseDict)
        if !hasError, let responseDict = responseDict {
            hasError = !apiRes.ParseResponse(responseDict)
        }
        if hasError, let error = apiRes.error {
            return (apiRes, error)
        } else {
            return (apiRes, nil)
        }
    }

    func checkHttpStatus() -> Bool {
        return httpCode == 200
    }

    func checkResponseStatus() -> Bool {
        return responseCode == 1000 || responseCode == 1001
    }

    private func parseTaskError(response: URLResponse?, taskError: NSError, responseDict: [String: Any]?) -> ResponseError {
        if let httpResponse = response as? HTTPURLResponse {
            httpCode = httpResponse.statusCode
        }
        responseCode = responseCode(from: responseDict)
        let userFacingMessage = responseErrorMessage(from: responseDict)
        let networkingError = ResponseError(httpCode: httpCode,
                                              responseCode: responseCode,
                                              userFacingMessage: userFacingMessage,
                                              underlyingError: taskError)
        error = networkingError
        return networkingError
    }

    private func parseResponseError(responseDict: [String: Any]?) -> Bool {
        if let responseCode = error?.responseCode {
            // response was already parsed, no need for further work
            return doesResponseCodeIndicateSuccess(code: responseCode)
        }

        guard let responseDict = responseDict else {
            // no response means something went wrong, but no more information can be extracted
            return true
        }

        guard let responseCode = responseCode(from: responseDict) else {
            // there is no code in the response dict. we are assuming it's good news and default to successful 1000 status
            self.responseCode = 1000
            guard let userFacingMessage = responseErrorMessage(from: responseDict) else {
                // no error message in the response dict means there is no indication of the response failure
                return false
            }
            // there is an error message in the response dict, meaning response failed. this information takes precedence over previous error value
            error = error?.withUpdated(userFacingMessage: userFacingMessage)
                ?? ResponseError(httpCode: nil, responseCode: nil, userFacingMessage: userFacingMessage, underlyingError: nil)
            return true
        }

        self.responseCode = responseCode

        guard doesResponseCodeIndicateSuccess(code: responseCode) else {
            // update the error so that the previous information is kept, but the one from the response, if available, takes precedence
            error = ResponseError(httpCode: error?.httpCode,
                                    responseCode: responseCode,
                                    userFacingMessage: responseErrorMessage(from: responseDict) ?? error?.userFacingMessage,
                                    underlyingError: error?.underlyingError)
            return true
        }
        return false
    }

    private func doesResponseCodeIndicateSuccess(code: Int) -> Bool {
        code == 1000 || code == 1001
    }

    private func responseCode(from responseDict: [String: Any]?) -> Int? {
        responseDict?["Code"] as? Int
    }

    private func responseErrorMessage(from responseDict: [String: Any]?) -> String? {
        responseDict?["Error"] as? String
    }
}

open class Response: ResponseType {
    public required init() {}

    public var responseCode: Int?
    public var httpCode: Int?
    public var error: ResponseError?

    open func ParseResponse(_ response: [String: Any]) -> Bool {
        return true
    }
}
