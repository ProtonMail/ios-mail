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
    
    /// initially using for sending the fingerprint
    var challengeProperties: ChallengeProperties? { get }
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
    
    public var challengeProperties: ChallengeProperties? {
        return nil
    }
    
    /// This function should be used in networking layer or when you are trying to get the full request parameters from endpoints.
    ///     this function will combine the challenges properties with parameter properties
    /// - Returns: [String: Any] dictionary
    public var calculatedParameters: [String: Any]? {
        // check if challengeProperty exist
        guard let challengeProperty = challengeProperties else {
            // if the challengeProperty doesn't exist. it just return parameters. and the parameters are possibly nil
            return parameters
        }
        
        // if a challengeProperty is found, then build up the payload, which shall be returned even if parameters is empty
        var payload: [String: Any] = [:]
        for (index, data) in challengeProperty.challenges.enumerated() {
            payload["\(challengeProperty.productPrefix)-ios-v4-challenge-\(index)"] = data
        }
        
        // after built the payload. and check if the payload contains any challenges.
        //   If payload doesnt contain cchallenges. it just return parameters. and the parameters are possibly nil
        guard payload.count > 0 else {
            return parameters
        }
        
        // check if parameters exist
        guard var parameters = parameters else {
            // if there are no parameters. it just return the "Payload"
            // if the payload has a key but the value is empty that is fine. we will still send the [key: nil] to the backend
            return ["Payload": payload]
        }
        
        // when goes here. both parameters and payload must be not empty. insert Payload to parameters and return it.
        parameters["Payload"] = payload
        
        return parameters
    }
    
    public func test() {
        
    }
}
