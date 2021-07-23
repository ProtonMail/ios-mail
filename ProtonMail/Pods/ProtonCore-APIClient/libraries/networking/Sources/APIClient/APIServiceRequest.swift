//
//  APIServiceRequest.swift
//  ProtonCore-APIClient - Created on 6/18/15.
//
//  Copyright (c) 2019 Proton Technologies AG
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

// swiftlint:disable identifier_name todo

import Foundation
import PromiseKit
import AwaitKit
import ProtonCore_Networking
import ProtonCore_Services

public protocol ApiPackage {
    /**
     conver requset object to dictionary

     :returns: request dictionary
     */
    func toDictionary() -> [String: Any]?
}

// abstract api request base class
open class ApiRequest<T: ApiResponse>: ApiPackage {

    init () { }

    // add error response
    public typealias ResponseCompletionBlock = (_ task: URLSessionDataTask?, _ response: T?, _ hasError: Bool) -> Void

    public func toDictionary() -> [String: Any]? {
        return nil
    }

    /**
     get current api request
     
     :returns: int version number
     */
    func apiVersion() -> Int {
        return 1
    }

    func getHeaders() -> [String: Any] {
        return [String: Any]()
    }

    /**
     get is current function need auth check
     
     :returns: default is true
     */
    func getIsAuthFunction() -> Bool {
        return true
    }

    func authRetry() -> Bool {
        return true
    }

    var authCredential: AuthCredential?

    /**
     get request path
     
     :returns: String value
     */
    func path() -> String {
        fatalError("This method must be overridden")
    }

    public func method() -> HTTPMethod {
        return .get
    }

    func call(api: API, _ complete: ResponseCompletionBlock?) {
        // 1 make a request , 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
        let completionWrapper: CompletionBlock = { task, responseDict, error in
            switch T.parseNetworkCallResults(to: T.self, response: task?.response, responseDict: responseDict, error: error) {
            case (let response, _?):
                complete?(task, response, true)
            case (let response, nil):
                complete?(task, response, false)
            }
        }

        var header = self.getHeaders()
        if self.apiVersion() != -1 {
            header["x-pm-apiversion"] = self.apiVersion()
        }

        api.request(method: self.method(),
                    path: self.path(),
                    parameters: self.toDictionary(),
                    headers: header,
                    authenticated: self.getIsAuthFunction(), autoRetry: self.authRetry(),
                    customAuthCredential: self.authCredential,
                    completion: completionWrapper)
    }

    public func syncCall(api: API) throws -> T? {
        var ret_res: T?
        var ret_error: ResponseError?
        let sema = DispatchSemaphore(value: 0)
        // TODO :: 1 make a request , 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
        let completionWrapper: CompletionBlock = { task, responseDict, error in
            defer {
                sema.signal()
            }
            switch T.parseNetworkCallResults(to: T.self, response: task?.response, responseDict: responseDict, error: error) {
            case (_, let networkingError?):
                ret_error = networkingError
            case (let response, nil):
                ret_res = response
            }
        }

        // TODO:: missing auth
        api.request(method: self.method(), path: self.path(),
                    parameters: self.toDictionary(), headers: [HTTPHeader.apiVersion: self.apiVersion()],
                    authenticated: self.getIsAuthFunction(), autoRetry: self.authRetry(), customAuthCredential: self.authCredential, completion: completionWrapper)

        // wait operations
        _ = sema.wait(timeout: DispatchTime.distantFuture)
        if let e = ret_error {
            throw e
        }
        return ret_res
    }
}

// abstract api request base class
open class ApiRequestNew<T: ApiResponse>: ApiPackage {

    public init (api: API) {
        self.apiService = api
    }

    // add error response
    // public typealias ResponseCompletionBlock = (_ task: URLSessionDataTask?, _ response: T?, _ hasError : Bool) -> Void

    open func toDictionary() -> [String: Any]? {
        return nil
    }

    /**
     get current api request
     
     :returns: int version number
     */
    open func apiVersion() -> Int {
        return 1
    }

    /**
     get is current function need auth check
     
     :returns: default is true
     */
    open func getIsAuthFunction() -> Bool {
        return true
    }

    open func authRetry() -> Bool {
        return true
    }

    open var authCredential: AuthCredential?

    private let apiService: API

    /**
     get request path
     
     :returns: String value
     */
    open func path() -> String {
        fatalError("This method must be overridden")
    }

    open func method() -> HTTPMethod {
        return .get
    }

    open func run() -> Promise<T> {
        // 1 make a request , 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
        let deferred = Promise<T>.pending()
        let completionWrapper: CompletionBlock = { task, responseDict, error in

            switch T.parseNetworkCallResults(to: T.self, response: task?.response, responseDict: responseDict, error: error) {
            case (_, let networkingError?):
                deferred.resolver.reject(networkingError)
            case (let response, nil):
                deferred.resolver.fulfill(response)
            }
        }

        // TODO:: missing auth
        apiService.request(method: self.method(), path: self.path(),
                    parameters: self.toDictionary(), headers: [HTTPHeader.apiVersion: self.apiVersion()],
                    authenticated: self.getIsAuthFunction(), autoRetry: self.authRetry(), customAuthCredential: self.authCredential, completion: completionWrapper)

        return deferred.promise

    }
}

extension NSError {
    public class func apiServiceError(code: Int, localizedDescription: String, localizedFailureReason: String?, localizedRecoverySuggestion: String? = nil) -> NSError {
        return NSError(
            domain: "APIService",
            code: code,
            localizedDescription: localizedDescription,
            localizedFailureReason: localizedFailureReason,
            localizedRecoverySuggestion: localizedRecoverySuggestion)
    }

    public class func badResponse() -> NSError {
        return apiServiceError(
            code: APIErrorCode.badResponse,
            localizedDescription: "Bad response",
            localizedFailureReason: "Bad response")
    }
}
