//
//  Route.swift
//  ProtonCore-Networking - Created on 5/22/20.
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

// swiftlint:disable identifier_name

import Foundation

public protocol Package {
    /**
     conver requset object to dictionary
     
     :returns: request dictionary
     */
    var parameters: [String: Any]? { get }
}

///
public enum HTTPMethod: String {
    case delete = "DELETE"
    case get = "GET"
    case post = "POST"
    case put = "PUT"

    @available(*, deprecated, renamed: "rawValue")
    public func toString() -> String {
        self.rawValue
    }
}

// APIClient is the api client base
public protocol Request: Package {
    var path: String { get }
    var header: [String: Any] { get }
    var method: HTTPMethod { get }
    var nonDefaultTimeout: TimeInterval? { get }

    var isAuth: Bool { get }

    var authCredential: AuthCredential? { get }
    var autoRetry: Bool { get }
    var retryPolicy: ProtonRetryPolicy.RetryMode { get }
}

extension Request {
    public var isAuth: Bool {
        return true
    }

    public var autoRetry: Bool {
        return true
    }

    public var header: [String: Any] {
        return [:]
    }

    public var authCredential: AuthCredential? {
        return nil
    }

    public var method: HTTPMethod {
        return .get
    }

    public var parameters: [String: Any]? {
        return nil
    }
    
    public var nonDefaultTimeout: TimeInterval? {
        return nil
    }

    public var retryPolicy: ProtonRetryPolicy.RetryMode {
        return .userInitiated
    }
}
