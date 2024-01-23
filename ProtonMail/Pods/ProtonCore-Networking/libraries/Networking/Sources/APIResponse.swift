//
//  APIResponse.swift
//  ProtonCore-Networking - Created on 19.04.23.
//
//  Copyright (c) 2023 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

public protocol APIResponse {
    var code: Int? { get set }
    var error: String? { get set }
    var details: APIResponseDetails? { get }
}

public extension APIResponse {
    var errorMessage: String? { get { error } set { error = newValue } }
}

extension APIResponse {
    public var serialized: [String: Any] {
        var responseDict: [String: Any] = [:]
        if let code = code { responseDict["Code"] = code }
        if let error = error { responseDict["Error"] = error }
        if let details = details { responseDict["Details"] = details.serializedDetails }
        return responseDict
    }
}

extension Dictionary: APIResponse where Key == String, Value == Any {

    public var code: Int? { get { self["Code"] as? Int } set { self["Code"] = newValue } }

    public var error: String? { get { self["Error"] as? String } set { self["Error"] = newValue } }

    public var details: APIResponseDetails? {
        get {
            guard let details = self["Details"] as? [String: Any],
                  let code = self["Code"] as? Int else { return nil }
            return detailsFromDictionary(jsonDictionary: details, code: code)
        }
        set {
            self["Details"] = newValue?.serializedDetails
        }
    }

    private func detailsFromDictionary(jsonDictionary: [String: Any], code: Int) -> APIResponseDetails {
        if code == APIErrorCode.humanVerificationRequired,
           let token = jsonDictionary[HumanVerificationDetails.CodingKeys.token.uppercased] as? String,
           let title = jsonDictionary[HumanVerificationDetails.CodingKeys.title.uppercased] as? String,
           let methods = jsonDictionary[HumanVerificationDetails.CodingKeys.methods.uppercased] as? [String] {
            return .humanVerification(.init(token: token, title: title, methods: methods))
        }

        if code == APIErrorCode.deviceVerificationRequired,
           let type = jsonDictionary[DeviceVerificationDetails.CodingKeys.type.uppercased] as? Int,
           let payload = jsonDictionary[DeviceVerificationDetails.CodingKeys.payload.uppercased] as? String {
            return .deviceVerification(.init(type: type, payload: payload))
        }

        if code == APIErrorCode.HTTP403,
           let missingScopes = jsonDictionary[MissingScopesDetails.CodingKeys.missingScopes.uppercased] as? [String] {
            return .missingScopes(.init(missingScopes: missingScopes))
        }

        return .empty
    }

    private struct APIErrorCode {
        static let humanVerificationRequired = 9001
        static let deviceVerificationRequired = 9002
        static let HTTP403 = 403
    }
}
