//
//  APIService.swift
//  ProtonCore-Services - Created on 5/22/20.
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

// swiftlint:disable identifier_name todo function_parameter_count

import Foundation
import ProtonCore_Doh
import ProtonCore_Log
import ProtonCore_Utilities
import ProtonCore_Networking

extension Bundle {
    /// Returns the app version in a nice to read format
    var appVersion: String {
        return "\(majorVersion) (\(buildVersion))"
    }

    /// Returns the build version of the app.
    var buildVersion: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    /// Returns the major version of the app.
    public var majorVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
}

public protocol APIServerConfig {
    
    // host name    xxx.xxxxxxx.com
    var host: String { get }
    
    // http https ws wss etc ...
    var `protocol`: String { get }
    
    // prefixed path after host example:  /api
    var path: String { get }
    
    // full host with protocol, without path
    var hostUrl: String { get }
}

extension APIServerConfig {
    
    public var hostUrl: String {
        return self.protocol + "://" + self.host
    }
}

public typealias CompletionBlock = (_ task: URLSessionDataTask?, _ response: [String: Any]?, _ error: NSError?) -> Void

public protocol API {

    func request(method: HTTPMethod,
                 path: String,
                 parameters: Any?,
                 headers: [String: Any]?,
                 authenticated: Bool,
                 autoRetry: Bool,
                 customAuthCredential: AuthCredential?,
                 nonDefaultTimeout: TimeInterval?,
                 completion: CompletionBlock?)

    func download(byUrl url: String,
                  destinationDirectoryURL: URL,
                  headers: [String: Any]?,
                  authenticated: Bool,
                  customAuthCredential: AuthCredential?,
                  nonDefaultTimeout: TimeInterval?,
                  downloadTask: ((URLSessionDownloadTask) -> Void)?,
                  completion: @escaping ((URLResponse?, URL?, NSError?) -> Void))

    func upload(byPath path: String,
                parameters: [String: String],
                keyPackets: Data,
                dataPacket: Data,
                signature: Data?,
                headers: [String: Any]?,
                authenticated: Bool,
                customAuthCredential: AuthCredential?,
                nonDefaultTimeout: TimeInterval?,
                completion: @escaping CompletionBlock)
    
    func upload(byPath path: String,
                parameters: Any?,
                files: [String: URL],
                headers: [String: Any]?,
                authenticated: Bool,
                customAuthCredential: AuthCredential?,
                nonDefaultTimeout: TimeInterval?,
                uploadProgress: ProgressCompletion?,
                completion: @escaping CompletionBlock)

    func uploadFromFile(byPath path: String,
                        parameters: [String: String],
                        keyPackets: Data,
                        dataPacketSourceFileURL: URL,
                        signature: Data?,
                        headers: [String: Any]?,
                        authenticated: Bool,
                        customAuthCredential: AuthCredential?,
                        nonDefaultTimeout: TimeInterval?,
                        completion: @escaping CompletionBlock)
}

public extension API {

    func request(method: HTTPMethod,
                 path: String,
                 parameters: Any?,
                 headers: [String: Any]?,
                 authenticated: Bool,
                 autoRetry: Bool,
                 customAuthCredential: AuthCredential?,
                 completion: CompletionBlock?) {
        self.request(method: method, path: path, parameters: parameters, headers: headers,
                     authenticated: authenticated, autoRetry: autoRetry, customAuthCredential: customAuthCredential,
                     nonDefaultTimeout: nil, completion: completion)
    }

    func download(byUrl url: String,
                  destinationDirectoryURL: URL,
                  headers: [String: Any]?,
                  authenticated: Bool,
                  customAuthCredential: AuthCredential?,
                  downloadTask: ((URLSessionDownloadTask) -> Void)?,
                  completion: @escaping ((URLResponse?, URL?, NSError?) -> Void)) {
        self.download(byUrl: url, destinationDirectoryURL: destinationDirectoryURL, headers: headers,
                      authenticated: authenticated, customAuthCredential: customAuthCredential, nonDefaultTimeout: nil,
                      downloadTask: downloadTask, completion: completion)
    }

    func upload(byPath path: String,
                parameters: [String: String],
                keyPackets: Data,
                dataPacket: Data,
                signature: Data?,
                headers: [String: Any]?,
                authenticated: Bool,
                customAuthCredential: AuthCredential?,
                completion: @escaping CompletionBlock) {
        self.upload(byPath: path, parameters: parameters, keyPackets: keyPackets, dataPacket: dataPacket,
                    signature: signature, headers: headers, authenticated: authenticated, customAuthCredential: customAuthCredential,
                    nonDefaultTimeout: nil, completion: completion)
    }
    
    func upload(byPath path: String,
                parameters: Any?,
                files: [String: URL],
                headers: [String: Any]?,
                authenticated: Bool,
                customAuthCredential: AuthCredential?,
                uploadProgress: ProgressCompletion?,
                completion: @escaping CompletionBlock) {
        self.upload(byPath: path, parameters: parameters, files: files, headers: headers, authenticated: authenticated,
                    customAuthCredential: customAuthCredential, nonDefaultTimeout: nil,
                    uploadProgress: uploadProgress, completion: completion)
    }

    func uploadFromFile(byPath path: String,
                        parameters: [String: String],
                        keyPackets: Data,
                        dataPacketSourceFileURL: URL,
                        signature: Data?,
                        headers: [String: Any]?,
                        authenticated: Bool,
                        customAuthCredential: AuthCredential?,
                        completion: @escaping CompletionBlock) {
        self.uploadFromFile(byPath: path, parameters: parameters, keyPackets: keyPackets, dataPacketSourceFileURL: dataPacketSourceFileURL,
                            signature: signature, headers: headers, authenticated: authenticated, customAuthCredential: customAuthCredential,
                            nonDefaultTimeout: nil, completion: completion)
        
    }
}

public protocol APIServiceDelegate: AnyObject {

    var appVersion: String { get }
    
    var userAgent: String? { get }
    
    var locale: String { get }
    
    var additionalHeaders: [String: String]? { get }
    
    func onUpdate(serverTime: Int64)
    
    func isReachable() -> Bool

    func onDohTroubleshot()
}

public enum HumanVerifyFinishReason {
    public typealias HumanVerifyHeader = [String: Any]
    
    case verification(header: HumanVerifyHeader, verificationCodeBlock: SendVerificationCodeBlock?)
    case close
    case closeWithError(code: Int, description: String)
}

public enum HumanVerificationVersion: Equatable {
    case v2
    case v3
}

public protocol HumanVerifyDelegate: AnyObject {
    var version: HumanVerificationVersion { get }
    func onHumanVerify(parameters: HumanVerifyParameters, currentURL: URL?, error: NSError, completion: (@escaping (HumanVerifyFinishReason) -> Void))
    func getSupportURL() -> URL
}

public enum HumanVerifyEndResult {
    case success
    case cancel
}

public protocol HumanVerifyResponseDelegate: AnyObject {
    func onHumanVerifyStart()
    func onHumanVerifyEnd(result: HumanVerifyEndResult)
    func humanVerifyToken(token: String?, tokenType: String?)
}

public enum PaymentTokenStatusResult {
    case success
    case fail
}

public protocol HumanVerifyPaymentDelegate: AnyObject {
    var paymentToken: String? { get }
    func paymentTokenStatusChanged(status: PaymentTokenStatusResult)
}

public typealias AuthRefreshComplete = (_ auth: Credential?, _ hasError: AuthErrors?) -> Void

/// this is auth related delegate in background
public protocol AuthDelegate: AnyObject {
    func getToken(bySessionUID uid: String) -> AuthCredential?
    func onLogout(sessionUID uid: String)
    func onUpdate(auth: Credential)
    func onRefresh(bySessionUID uid: String, complete: @escaping AuthRefreshComplete)
}

public protocol APIService: API {
    func setSessionUID(uid: String)
    
    var sessionUID: String { get }
    var serviceDelegate: APIServiceDelegate? { get set }
    var authDelegate: AuthDelegate? { get set }
    var humanDelegate: HumanVerifyDelegate? { get set }
    var doh: DoH & ServerConfig { get set }
    var signUpDomain: String { get }
}

class TestResponse: Response {

}

typealias RequestComplete = (_ task: URLSessionDataTask?, _ response: Response) -> Void

public extension APIService {
    // init
    
    @available(*, deprecated, renamed: "exec(route:responseObject:)")
    func exec<T>(route: Request, response: T = T()) -> T? where T: Response {
        exec(route: route, responseObject: response)
    }
    
    func exec<T>(route: Request, responseObject: T) -> T? where T: Response {
        var ret_res: T?
        var ret_error: ResponseError?
        let sema = DispatchSemaphore(value: 0)
        // TODO :: 1 make a request, 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
        let completionWrapper: CompletionBlock = { task, responseDict, error in
            defer {
                sema.signal()
            }
            switch T.parseNetworkCallResults(responseObject: responseObject, originalResponse: task?.response, responseDict: responseDict, error: error) {
            case (_, let networkingError?):
                ret_error = networkingError
            case (let response, nil):
                ret_res = response
            }
        }
        // TODO:: missing auth
        self.request(method: route.method,
                     path: route.path,
                     parameters: route.parameters,
                     headers: route.header,
                     authenticated: route.isAuth,
                     autoRetry: route.autoRetry,
                     customAuthCredential: route.authCredential,
                     nonDefaultTimeout: route.nonDefaultTimeout,
                     completion: completionWrapper)

        // wait operations
        _ = sema.wait(timeout: DispatchTime.distantFuture)
        if let e = ret_error {
            // TODO::fix me
            PMLog.debug(e.localizedDescription)
        }
        return ret_res
    }
    
    @available(*, deprecated, renamed: "exec(route:responseObject:complete:)")
    func exec<T>(route: Request,
                 response: T = T(),
                 complete: @escaping  (_ task: URLSessionDataTask?, _ response: T) -> Void) where T: Response {
        exec(route: route, responseObject: response, complete: complete)
    }

    func exec<T>(route: Request,
                 responseObject: T,
                 complete: @escaping  (_ task: URLSessionDataTask?, _ response: T) -> Void) where T: Response {

        // 1 make a request , 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
        let completionWrapper: CompletionBlock = { task, responseDict, error in
            switch T.parseNetworkCallResults(responseObject: responseObject, originalResponse: task?.response, responseDict: responseDict, error: error) {
            case (let response, _?):
                // TODO: this was a previous logic — to parse response even if there's an error
                if let resRaw = responseDict {
                    _ = response.ParseResponse(resRaw)
                }
                DispatchQueue.main.async {
                    complete(task, response)
                }
            case (let response, nil):
                DispatchQueue.main.async {
                    complete(task, response)
                }
            }
        }

        self.request(method: route.method, path: route.path,
                     parameters: route.parameters,
                     headers: route.header,
                     authenticated: route.isAuth,
                     autoRetry: route.autoRetry,
                     customAuthCredential: route.authCredential,
                     nonDefaultTimeout: route.nonDefaultTimeout,
                     completion: completionWrapper)
    }
    
    @available(*, deprecated, renamed: "exec(route:responseObject:callCompletionUsing:complete:)")
    func exec<T>(route: Request,
                 response: T = T(),
                 callCompletionBlockOn: DispatchQueue = .main,
                 complete: @escaping (_ response: T) -> Void) where T: Response {
        exec(
            route: route,
            responseObject: response,
            callCompletionBlockUsing: .asyncExecutor(dispatchQueue: callCompletionBlockOn),
            complete: complete
        )
    }
    
    @available(*, deprecated, renamed: "exec(route:responseObject:callCompletionUsing:complete:)")
    func exec<T>(route: Request,
                 responseObject: T,
                 callCompletionBlockOn: DispatchQueue,
                 complete: @escaping (_ response: T) -> Void) where T: Response {
        exec(
            route: route,
            responseObject: responseObject,
            callCompletionBlockUsing: .asyncExecutor(dispatchQueue: callCompletionBlockOn),
            complete: complete
        )
    }

    func exec<T>(route: Request,
                 responseObject: T,
                 callCompletionBlockUsing executor: CompletionBlockExecutor = .asyncMainExecutor,
                 complete: @escaping (_ response: T) -> Void) where T: Response {

        // 1 make a request , 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
        let completionWrapper: CompletionBlock = { task, responseDict, error in
            executor.execute {
                switch T.parseNetworkCallResults(
                    responseObject: responseObject,
                    originalResponse: task?.response,
                    responseDict: responseDict,
                    error: error
                ) {
                case (let response, let originalError?):
                    // TODO: this was a previous logic — to parse response even if there's an error. should we move it to parseNetworkCallResults?
                    if let resRaw = responseDict {
                        _ = response.ParseResponse(resRaw)
                        // the error might have changed during the decoding try, morphing it into decode error.
                        // This leads to wrong or missing erro info. Hence I restore the original error
                        response.error = originalError
                    }

                    complete(response)
                case (let response, nil):
                    complete(response)
                }
            }
        }

        self.request(method: route.method, path: route.path,
                     parameters: route.parameters,
                     headers: route.header,
                     authenticated: route.isAuth,
                     autoRetry: route.autoRetry,
                     customAuthCredential: route.authCredential,
                     nonDefaultTimeout: route.nonDefaultTimeout,
                     completion: completionWrapper)
    }

    func exec<T>(route: Request, complete: @escaping (_ task: URLSessionDataTask?, _ result: Result<T, ResponseError>) -> Void) where T: Decodable {

        // 1 make a request , 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
        let completionWrapper: CompletionBlock = { task, res, error in
            do {
                if let res = res {
                    // this is a workaround for afnetworking, will change it
                    let responseData = try JSONSerialization.data(withJSONObject: res, options: .prettyPrinted)
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .decapitaliseFirstLetter
                    // server error code
                    if let errorResponse = try? decoder.decode(ErrorResponse.self, from: responseData) {
                        let responseError = ResponseError(httpCode: (task?.response as? HTTPURLResponse)?.statusCode,
                                                          responseCode: errorResponse.code,
                                                          userFacingMessage: errorResponse.error,
                                                          underlyingError: NSError(errorResponse))
                        DispatchQueue.main.async {
                            complete(task, .failure(responseError))
                        }
                        return
                    }
                    // server SRP
                    let decodedResponse = try decoder.decode(T.self, from: responseData)
                    DispatchQueue.main.async {
                        complete(task, .success(decodedResponse))
                    }
                } else if let error = error {
                    let responseError = ResponseError(httpCode: (task?.response as? HTTPURLResponse)?.statusCode,
                                                      responseCode: nil,
                                                      userFacingMessage: nil,
                                                      underlyingError: error)
                    DispatchQueue.main.async {
                        complete(task, .failure(responseError))
                    }
                    return
                } else {
                    let responseError = ResponseError(httpCode: (task?.response as? HTTPURLResponse)?.statusCode,
                                                      responseCode: nil,
                                                      userFacingMessage: nil,
                                                      underlyingError: nil)
                    DispatchQueue.main.async {
                        complete(task, .failure(responseError))
                    }
                }
            } catch let decodingError {
                let responseError = ResponseError(httpCode: (task?.response as? HTTPURLResponse)?.statusCode,
                                                  responseCode: nil, // unable to decode means no response
                                                  userFacingMessage: nil,
                                                  underlyingError: decodingError as NSError)
                DispatchQueue.main.async {
                    complete(task, .failure(responseError))
                }
            }
        }

        self.request(method: route.method,
                     path: route.path,
                     parameters: route.parameters,
                     headers: route.header,
                     authenticated: route.isAuth,
                     autoRetry: route.autoRetry,
                     customAuthCredential: route.authCredential,
                     nonDefaultTimeout: route.nonDefaultTimeout,
                     completion: completionWrapper)
    }

    func exec<T>(route: Request, complete: @escaping (_ result: Result<T, ResponseError>) -> Void) where T: Decodable {
        exec(route: route) { (_: URLSessionDataTask?, result: Result<T, ResponseError>) in
            complete(result)
        }
    }
}

public extension APIService {
    
    func upload<T>(route: Request,
                   files: [String: URL],
                   uploadProgress: ProgressCompletion?,
                   complete: @escaping (_ task: URLSessionDataTask?, _ result: Result<T, ResponseError>) -> Void) where T: Decodable {

        // 1 make a request , 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
        let completionWrapper: CompletionBlock = { task, res, error in
            do {
                if let res = res {
                    // this is a workaround for afnetworking, will change it
                    let responseData = try JSONSerialization.data(withJSONObject: res, options: .prettyPrinted)
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .decapitaliseFirstLetter
                    // server error code
                    if let errorResponse = try? decoder.decode(ErrorResponse.self, from: responseData) {
                        let responseError = ResponseError(httpCode: (task?.response as? HTTPURLResponse)?.statusCode,
                                                          responseCode: errorResponse.code,
                                                          userFacingMessage: errorResponse.error,
                                                          underlyingError: NSError(errorResponse))
                        DispatchQueue.main.async {
                            complete(task, .failure(responseError))
                        }
                        return
                    }
                    // server SRP
                    let decodedResponse = try decoder.decode(T.self, from: responseData)
                    DispatchQueue.main.async {
                        complete(task, .success(decodedResponse))
                    }
                } else if let error = error {
                    let responseError = ResponseError(httpCode: (task?.response as? HTTPURLResponse)?.statusCode,
                                                      responseCode: nil,
                                                      userFacingMessage: nil,
                                                      underlyingError: error)
                    DispatchQueue.main.async {
                        complete(task, .failure(responseError))
                    }
                    return
                } else {
                    let responseError = ResponseError(httpCode: (task?.response as? HTTPURLResponse)?.statusCode,
                                                      responseCode: nil,
                                                      userFacingMessage: nil,
                                                      underlyingError: nil)
                    DispatchQueue.main.async {
                        complete(task, .failure(responseError))
                    }
                }
            } catch let decodingError {
                let responseError = ResponseError(httpCode: (task?.response as? HTTPURLResponse)?.statusCode,
                                                  responseCode: nil, // unable to decode means no response
                                                  userFacingMessage: nil,
                                                  underlyingError: decodingError as NSError)
                DispatchQueue.main.async {
                    complete(task, .failure(responseError))
                }
            }
        }
        
        self.upload(byPath: route.path,
                    parameters: route.parameters,
                    files: files, headers: route.header,
                    authenticated: route.isAuth,
                    customAuthCredential: route.authCredential,
                    nonDefaultTimeout: route.nonDefaultTimeout,
                    uploadProgress: uploadProgress,
                    completion: completionWrapper)
    }
    
    func upload<T>(route: Request,
                   files: [String: URL],
                   uploadProgress: ProgressCompletion?,
                   complete: @escaping (_ result: Result<T, ResponseError>) -> Void) where T: Decodable {
        upload(route: route, files: files, uploadProgress: uploadProgress) { (_: URLSessionDataTask?, result: Result<T, ResponseError>) in
            complete(result)
        }
    }
}
