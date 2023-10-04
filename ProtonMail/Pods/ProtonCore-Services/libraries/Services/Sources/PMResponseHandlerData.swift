//
//  PMResponseHandlerData.swift
//  ProtonCore-Services - Created on 09.05.23.
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

import Foundation
import ProtonCoreNetworking

public struct PMResponseHandlerData {
    public var method: HTTPMethod
    public var path: String
    public var parameters: Any?
    public var headers: [String: Any]?
    public var authenticated: Bool
    public var authRetry: Bool
    public var authRetryRemains: Int
    public var customAuthCredential: AuthCredential?
    public var nonDefaultTimeout: TimeInterval?
    public var retryPolicy: ProtonRetryPolicy.RetryMode
    public var task: URLSessionDataTask?
    public var onDataTaskCreated: (URLSessionDataTask) -> Void
    
    public init(method: HTTPMethod,
                path: String,
                parameters: Any? = nil,
                headers: [String: Any]? = nil,
                authenticated: Bool,
                authRetry: Bool,
                authRetryRemains: Int,
                customAuthCredential: AuthCredential? = nil,
                nonDefaultTimeout: TimeInterval? = nil,
                retryPolicy: ProtonRetryPolicy.RetryMode,
                task: URLSessionDataTask? = nil,
                onDataTaskCreated: @escaping (URLSessionDataTask) -> Void) {
        self.method = method
        self.path = path
        self.parameters = parameters
        self.headers = headers
        self.authenticated = authenticated
        self.authRetry = authRetry
        self.authRetryRemains = authRetryRemains
        self.customAuthCredential = customAuthCredential
        self.nonDefaultTimeout = nonDefaultTimeout
        self.retryPolicy = retryPolicy
        self.task = task
        self.onDataTaskCreated = onDataTaskCreated
    }
}
