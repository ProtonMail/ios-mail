//
//  Endpoint.swift
//  ProtonCore-Networking - Created on 20/02/2020.
//
//  Copyright (c) 2022 Proton Technologies AG
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

protocol Endpoint {
    associatedtype Response: Codable
    var request: URLRequest { get }
}

public struct ErrorResponse: SessionDecodableResponse {

    public var code: Int
    public var error: String
    public var errorDescription: String?

    public init(code: Int, error: String, errorDescription: String) {
        self.code = code
        self.error = error
        self.errorDescription = errorDescription
    }
    
    enum CodingKeys: String, CodingKey {
        case code = "code"
        case error = "error"
        case details = "exception"
        case description = "errorDescription"
    }
}

extension ErrorResponse {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        code = try values.decode(Int.self, forKey: .code)
        error = try values.decode(String.self, forKey: .error)
        errorDescription = try values.decodeIfPresent(String.self, forKey: .description) ?? values.decode(String.self, forKey: .details)
    }
}

public extension NSError {
    convenience init(_ serverError: ErrorResponse) {
        let userInfo = [NSLocalizedDescriptionKey: serverError.error,
                        NSLocalizedFailureReasonErrorKey: serverError.errorDescription ?? ""]

        self.init(domain: "ProtonCore-Networking", code: serverError.code, userInfo: userInfo)
    }
}
