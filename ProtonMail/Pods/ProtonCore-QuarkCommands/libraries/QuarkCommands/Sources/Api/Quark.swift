//
//  Quark.swift
//  ProtonCore-QuarkCommands - Created on 08.12.2023.
//
// Copyright (c) 2023. Proton Technologies AG
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
import Combine
import os.log
import ProtonCoreDoh
import ProtonCoreLog

public typealias OnQuarkResponse = (URLResponse, Data?, Error?) -> Void

extension URLRequest {
    mutating func internalUrl(baseUrl: String, route: String, args: [String]) {
        let filteredArgs = args.filter { !$0.isEmpty }
        let joinedArgs = filteredArgs.joined(separator: "&")
        guard let finalUrl = URL(string: "\(baseUrl)/internal/\(route)?\(joinedArgs)") else { return }
        url = finalUrl
    }
}

/**
 * Represents a command for making HTTP requests with Quark internal api.
 */
public class Quark {

    /** Properties **/
    private var route: String?
    private var proxyToken: String?
    private var baseUrl: String?
    private var args: [String] = []
    private var onRequestBuilder: ((inout URLRequest) -> Void)?
    private var httpClientTimeout: TimeInterval = 15
    private var httpClientReadTimeout: TimeInterval = 30
    private var httpClientWriteTimeout: TimeInterval = 30
    private var onResponse: OnQuarkResponse?

    public init() {
    }

    /**
     * The HTTP client used to send requests.
     */
    public var client: URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = httpClientTimeout
        config.timeoutIntervalForResource = httpClientReadTimeout
        return URLSession(configuration: config)
    }

    /**
     * Sets the route for the request.
     * - Parameter route: the route as a string
     * - Returns: the Quark instance for chaining
     */
    @discardableResult
    public func route(_ route: String) -> Quark {
        self.route = route
        return self
    }

    /**
     * Sets the arguments for the request.
     * - Parameter args: the array of strings to set as arguments
     * - Returns: the Quark instance for chaining
     */
    @discardableResult
    public func args(_ args: [String]) -> Quark {
        self.args = args
        return self
    }

    /**
     * Sets the base URL for the request.
     * - Parameter baseUrl: the base URL as a string
     * - Returns: the Quark instance for chaining
     */
    @discardableResult
    public func baseUrl(_ doh: DoH) -> Quark {
        self.baseUrl = doh.getCurrentlyUsedHostUrl()
        return self
    }

    /**
     * Sets the base URL for the request.
     * - Parameter baseUrl: the base URL as a string
     * - Returns: the Quark instance for chaining
     */
    @discardableResult
    public func baseUrl(_ baseUrl: String) -> Quark {
        self.baseUrl = baseUrl
        return self
    }

    /**
     * Sets the proxy token for the request.
     * - Parameter proxyToken: the proxy token as a string
     * - Returns: the Quark instance for chaining
     */
    @discardableResult
    public func proxyToken(_ proxyToken: String) -> Quark {
        self.proxyToken = proxyToken
        return self
    }

    /**
     * Customizes the request using a builder block.
     * - Parameter requestBuilderBlock: the block with custom request configuration
     * - Returns: the Quark instance for chaining
     */
    @discardableResult
    public func onRequestBuilder(_ requestBuilderBlock: @escaping (inout URLRequest) -> Void) -> Quark {
        self.onRequestBuilder = requestBuilderBlock
        return self
    }

    /**
     * Configures the Quark to execute a responseBlock based on the server response.
     *
     * - Parameter responseBlock: Block to execute to handle the server response
     * - Returns: The Quark instance with response handling set
     */
    @discardableResult
    public func onResponse(_ responseBlock: @escaping OnQuarkResponse) -> Quark {
        self.onResponse = responseBlock
        return self
    }

    /**
     Configures the timeout settings for HTTP requests.
     - Parameters:
       - request
       - resource
     * - Returns: The Quark instance with response handling set
     */
    public func configureTimeouts(request: TimeInterval, resource: TimeInterval) -> Quark {
        httpClientTimeout = request
        httpClientReadTimeout = resource
        return self
    }

    /**
     * Builds the URLRequest object to be sent.
     * - Throws: Error if the base URL or route is not specified
     * - Returns: the URLRequest object
     */
    public func build() throws -> URLRequest {
        guard let baseUrl = self.baseUrl else {
            throw NSError(domain: "QuarkCommandError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Internal API base URL is not specified"])
        }

        guard let route = self.route else {
            throw NSError(domain: "QuarkCommandError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Internal API route is not specified"])
        }

        var request = URLRequest(url: URL(string: "https://dummy")!) // Using a dummy URL, internalUrl will replace it
        request.internalUrl(baseUrl: baseUrl, route: route, args: self.args)

        onRequestBuilder?(&request)

        if let token = proxyToken {
            request.addValue(token, forHTTPHeaderField: "x-atlas-secret")
        }

        // Reset properties
        args = []
        onRequestBuilder = nil
        self.route = nil

        PMLog.info(request.url!.absoluteString)
        return request
    }

    /**
     * Executes a Quark HTTP request using the given HTTP client.
     * - Parameter request: the URLRequest to execute
     * - Returns: the URLSession data task publisher
     */
    public func executeQuarkRequest(_ request: URLRequest) throws -> (data: Data, response: URLResponse) {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<(Data, URLResponse), Error>!

        let task = client.dataTask(with: request) { data, response, error in
            if let error = error {
                result = .failure(error)
            } else if let data = data, let response = response {
                result = .success((data, response))
            }
            semaphore.signal()
        }

        task.resume()

        semaphore.wait()

        switch result {
        case .success(let dataAndResponse):
            return dataAndResponse
        case .failure(let error):
            throw error
        case .none:
            throw NSError(domain: "Unknown error", code: -1, userInfo: nil)
        }
    }
}
