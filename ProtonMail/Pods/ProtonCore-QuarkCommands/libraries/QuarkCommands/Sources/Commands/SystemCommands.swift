//
//  SystemCommands.swift
//  ProtonCore-QuarkCommands - Created on 08.12.2023.
//
// Copyright (c) 2023. Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation

private let systemEnvRoute: String = "system/env"

// variable: FINGERPRINT_RESPONSE
public enum FingerprintResponse: String {
    case ok = "{\\\"code\\\": 1000, \\\"result\\\": \\\"ok\\\", \\\"message\\\":\\\"{\\\\\\\"VerifyMethods\\\\\\\":[\\\\\\\"captcha\\\\\\\", \\\\\\\"email\\\\\\\", \\\\\\\"sms\\\\\\\"]}\\\"}"
    case whitelist = "{\\\"code\\\": 1001, \\\"result\\\": \\\"whitelist\\\"}"
    case captcha = "{\\\"code\\\": 2000, \\\"result\\\": \\\"captcha\\\"}"
    case proofOfWork = "{\\\"code\\\": 2004, \\\"result\\\": \\\"pow\\\"}"
    case block = "{\\\"code\\\": 3000, \\\"result\\\": \\\"block\\\", \\\"message\\\":\\\"Any error message you want\\\"}"
    case evil = "{\\\"code\\\": 3002, \\\"result\\\": \\\"evil\\\"}"
    case ownershipVerification = "{\\\"code\\\": 2001, \\\"result\\\": \\\"verify\\\"}"
    case captchaAndVerify = "{\\\"code\\\": 2003, \\\"result\\\": \\\"captcha+verify\\\"}"
    case userFacingErrorMessage = "{\\\"code\\\": 2000, \\\"result\\\": \\\"captcha\\\", \\\"message\\\":\\\"Please, solve CAPTCHA before continuing\\\"}"
    case deviceLocationISP = "{\\\"code\\\": 2000, \\\"result\\\": \\\"captcha\\\", \\\"user_device\\\":\\\"Mac OS X, MacBook Pro 13inch 2020 M1\\\", \\\"user_location\\\":\\\"Geneva, Switzerland\\\", \\\"user_internet_provider\\\":\\\"AT&T\\\"}"
}

// variable: PROTON_CAPTCHA_VERIFY_RESPONSE
public enum ProtonCaptchaVerifyResponse: String {
    case pass = "{\\\"status\\\": \\\"pass\\\"}"
    case fail = "{\\\"status\\\": \\\"fail\\\"}"
}

public extension Quark {

    @discardableResult
    func systemEnv(variable: String, value: String) throws -> (data: Data, response: URLResponse) {

        let args = "\(variable)=\(value)"

        let request = try route(systemEnvRoute)
            .args([args])
            .httpMethod("POST")
            .build()

        let (textData, response) = try executeQuarkRequest(request)

        try validateHTTPResponse(response, textData)

        return (textData, response)
    }

    @discardableResult
    func systemEnvVariableAsJson(variable: String, value: String) throws -> (data: Data, response: URLResponse) {

        let jsonString = "{\"env\":\"\(variable)='\(value)'\"}"
        let data = jsonString.data(using: .utf8)!

        let request = try route(systemEnvRoute)
            .httpMethod("POST")
            .setRawData(data) // This assumes `setRawData` properly sets the HTTP body.
            .build()

        let (textData, response) = try executeQuarkRequest(request)

        try validateHTTPResponse(response, textData)

        return (textData, response)
    }
}

func validateHTTPResponse(_ response: URLResponse, _ textData: Data) throws {
    guard let httpResponse = response as? HTTPURLResponse else {
        throw QuarkError(urlResponse: response, message: "Cannot get response \(String(describing: String(data: textData, encoding: .utf8)))")
    }

    if !(200...299).contains(httpResponse.statusCode) {
        throw QuarkError(urlResponse: response, message: "Wrong json data sent, please double check \(String(describing: String(data: textData, encoding: .utf8)))")
    }
}
