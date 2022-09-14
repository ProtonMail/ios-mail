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

@available(*, deprecated, message: "Use the signatures with either a JSON dictionary or codable type in the response")
public typealias CompletionBlock = (_ task: URLSessionDataTask?, _ response: [String: Any]?, _ error: NSError?) -> Void

public protocol API {
    
    // TODO: consider switching to a proper error, if it's even resonable without a major rewrite
    typealias APIError = NSError
    typealias JSONCompletion = (_ task: URLSessionDataTask?, _ result: Result<JSONDictionary, APIError>) -> Void
    typealias DecodableCompletion<T> = (_ task: URLSessionDataTask?, _ result: Result<T, APIError>) -> Void where T: APIDecodableResponse
    // TODO: modernize the download as well?
    typealias DownloadCompletion = (URLResponse?, URL?, NSError?) -> Void
    
    func request(method: HTTPMethod,
                 path: String,
                 parameters: Any?,
                 headers: [String: Any]?,
                 authenticated: Bool,
                 autoRetry: Bool,
                 customAuthCredential: AuthCredential?,
                 nonDefaultTimeout: TimeInterval?,
                 retryPolicy: ProtonRetryPolicy.RetryMode,
                 jsonCompletion: @escaping JSONCompletion)
    
    func request<T>(method: HTTPMethod,
                    path: String,
                    parameters: Any?,
                    headers: [String: Any]?,
                    authenticated: Bool,
                    autoRetry: Bool,
                    customAuthCredential: AuthCredential?,
                    nonDefaultTimeout: TimeInterval?,
                    retryPolicy: ProtonRetryPolicy.RetryMode,
                    decodableCompletion: @escaping DecodableCompletion<T>) where T: APIDecodableResponse
    
    func download(byUrl url: String,
                  destinationDirectoryURL: URL,
                  headers: [String: Any]?,
                  authenticated: Bool,
                  customAuthCredential: AuthCredential?,
                  nonDefaultTimeout: TimeInterval?,
                  retryPolicy: ProtonRetryPolicy.RetryMode,
                  downloadTask: ((URLSessionDownloadTask) -> Void)?,
                  downloadCompletion: @escaping DownloadCompletion)
    
    func upload(byPath path: String,
                parameters: [String: String],
                keyPackets: Data,
                dataPacket: Data,
                signature: Data?,
                headers: [String: Any]?,
                authenticated: Bool,
                customAuthCredential: AuthCredential?,
                nonDefaultTimeout: TimeInterval?,
                retryPolicy: ProtonRetryPolicy.RetryMode,
                uploadProgress: ProgressCompletion?,
                jsonCompletion: @escaping JSONCompletion)
    
    func upload<T>(byPath path: String,
                   parameters: [String: String],
                   keyPackets: Data,
                   dataPacket: Data,
                   signature: Data?,
                   headers: [String: Any]?,
                   authenticated: Bool,
                   customAuthCredential: AuthCredential?,
                   nonDefaultTimeout: TimeInterval?,
                   retryPolicy: ProtonRetryPolicy.RetryMode,
                   uploadProgress: ProgressCompletion?,
                   decodableCompletion: @escaping DecodableCompletion<T>) where T: APIDecodableResponse
    
    func upload(byPath path: String,
                parameters: Any?,
                files: [String: URL],
                headers: [String: Any]?,
                authenticated: Bool,
                customAuthCredential: AuthCredential?,
                nonDefaultTimeout: TimeInterval?,
                retryPolicy: ProtonRetryPolicy.RetryMode,
                uploadProgress: ProgressCompletion?,
                jsonCompletion: @escaping JSONCompletion)
    
    func upload<T>(byPath path: String,
                   parameters: Any?,
                   files: [String: URL],
                   headers: [String: Any]?,
                   authenticated: Bool,
                   customAuthCredential: AuthCredential?,
                   nonDefaultTimeout: TimeInterval?,
                   retryPolicy: ProtonRetryPolicy.RetryMode,
                   uploadProgress: ProgressCompletion?,
                   decodableCompletion: @escaping DecodableCompletion<T>) where T: APIDecodableResponse
    
    func uploadFromFile(byPath path: String,
                        parameters: [String: String],
                        keyPackets: Data,
                        dataPacketSourceFileURL: URL,
                        signature: Data?,
                        headers: [String: Any]?,
                        authenticated: Bool,
                        customAuthCredential: AuthCredential?,
                        nonDefaultTimeout: TimeInterval?,
                        retryPolicy: ProtonRetryPolicy.RetryMode,
                        uploadProgress: ProgressCompletion?,
                        jsonCompletion: @escaping JSONCompletion)
    
    func uploadFromFile<T>(byPath path: String,
                           parameters: [String: String],
                           keyPackets: Data,
                           dataPacketSourceFileURL: URL,
                           signature: Data?,
                           headers: [String: Any]?,
                           authenticated: Bool,
                           customAuthCredential: AuthCredential?,
                           nonDefaultTimeout: TimeInterval?,
                           retryPolicy: ProtonRetryPolicy.RetryMode,
                           uploadProgress: ProgressCompletion?,
                           decodableCompletion: @escaping DecodableCompletion<T>) where T: APIDecodableResponse
}

public extension API {
    
    @available(*, deprecated, message: "Please use the variant returning either DecodableResponseCompletion or JSONResponseCompletion")
    func request(method: HTTPMethod,
                 path: String,
                 parameters: Any?,
                 headers: [String: Any]?,
                 authenticated: Bool,
                 autoRetry: Bool,
                 customAuthCredential: AuthCredential?,
                 nonDefaultTimeout: TimeInterval?,
                 retryPolicy: ProtonRetryPolicy.RetryMode = .userInitiated,
                 completion: CompletionBlock?) {
        request(method: method, path: path, parameters: parameters, headers: headers, authenticated: authenticated, autoRetry: autoRetry,
                customAuthCredential: customAuthCredential, nonDefaultTimeout: nonDefaultTimeout, retryPolicy: retryPolicy) { task, result in
            switch result {
            case .success(let dict): completion?(task, dict, nil)
            case .failure(let error): completion?(task, nil, error)
            }
        }
    }
    
    @available(*, deprecated, message: "Please use the variant returning either DecodableResponseCompletion or JSONResponseCompletion")
    func request(method: HTTPMethod,
                 path: String,
                 parameters: Any?,
                 headers: [String: Any]?,
                 authenticated: Bool,
                 autoRetry: Bool,
                 customAuthCredential: AuthCredential?,
                 retryPolicy: ProtonRetryPolicy.RetryMode = .userInitiated,
                 completion: CompletionBlock?) {
        self.request(method: method, path: path, parameters: parameters, headers: headers,
                     authenticated: authenticated, autoRetry: autoRetry, customAuthCredential: customAuthCredential,
                     nonDefaultTimeout: nil, retryPolicy: retryPolicy, completion: completion)
    }
    
    @available(*, deprecated, message: "Please use the variant returning either DecodableResponseCompletion or JSONResponseCompletion")
    func request(method: HTTPMethod,
                 path: String,
                 parameters: Any?,
                 headers: [String: Any]?,
                 authenticated: Bool,
                 nonDefaultTimeout: TimeInterval?,
                 completion: CompletionBlock?) {
        // TODO: should autoRetry be false or true
        self.request(method: method, path: path, parameters: parameters, headers: headers,
                     authenticated: authenticated, autoRetry: false, customAuthCredential: nil,
                     nonDefaultTimeout: nil, completion: completion)
    }
    
    @available(*, deprecated, message: "Please use the variant returning either DecodableResponseCompletion or JSONResponseCompletion")
    func download(byUrl url: String,
                  destinationDirectoryURL: URL,
                  headers: [String: Any]?,
                  authenticated: Bool,
                  customAuthCredential: AuthCredential?,
                  retryPolicy: ProtonRetryPolicy.RetryMode = .userInitiated,
                  downloadTask: ((URLSessionDownloadTask) -> Void)?,
                  completion: @escaping ((URLResponse?, URL?, NSError?) -> Void)) {
        self.download(byUrl: url, destinationDirectoryURL: destinationDirectoryURL, headers: headers,
                      authenticated: authenticated, customAuthCredential: customAuthCredential, nonDefaultTimeout: nil, retryPolicy: retryPolicy,
                      downloadTask: downloadTask, downloadCompletion: completion)
    }
    
    @available(*, deprecated, message: "Please use the variant returning either DecodableResponseCompletion or JSONResponseCompletion")
    func upload(byPath path: String,
                parameters: [String: String],
                keyPackets: Data,
                dataPacket: Data,
                signature: Data?,
                headers: [String: Any]?,
                authenticated: Bool,
                customAuthCredential: AuthCredential?,
                nonDefaultTimeout: TimeInterval?,
                retryPolicy: ProtonRetryPolicy.RetryMode = .userInitiated,
                completion: @escaping CompletionBlock) {
        upload(byPath: path, parameters: parameters, keyPackets: keyPackets, dataPacket: dataPacket, signature: signature,
               headers: headers, authenticated: authenticated, customAuthCredential: customAuthCredential,
               nonDefaultTimeout: nonDefaultTimeout, retryPolicy: retryPolicy, uploadProgress: nil) { task, result in
            switch result {
            case .success(let dict): completion(task, dict, nil)
            case .failure(let error): completion(task, nil, error)
            }
        }
    }
    
    @available(*, deprecated, message: "Please use the variant returning either DecodableResponseCompletion or JSONResponseCompletion")
    func upload(byPath path: String,
                parameters: Any?,
                files: [String: URL],
                headers: [String: Any]?,
                authenticated: Bool,
                customAuthCredential: AuthCredential?,
                nonDefaultTimeout: TimeInterval?,
                retryPolicy: ProtonRetryPolicy.RetryMode = .userInitiated,
                uploadProgress: ProgressCompletion?,
                completion: @escaping CompletionBlock) {
        upload(byPath: path, parameters: parameters, files: files, headers: headers, authenticated: authenticated,
               customAuthCredential: customAuthCredential, nonDefaultTimeout: nonDefaultTimeout, retryPolicy: retryPolicy,
               uploadProgress: uploadProgress) { task, result in
            switch result {
            case .success(let dict): completion(task, dict, nil)
            case .failure(let error): completion(task, nil, error)
            }
        }
    }
    
    @available(*, deprecated, message: "Please use the variant returning either DecodableResponseCompletion or JSONResponseCompletion")
    func uploadFromFile(byPath path: String,
                        parameters: [String: String],
                        keyPackets: Data,
                        dataPacketSourceFileURL: URL,
                        signature: Data?,
                        headers: [String: Any]?,
                        authenticated: Bool,
                        customAuthCredential: AuthCredential?,
                        nonDefaultTimeout: TimeInterval?,
                        retryPolicy: ProtonRetryPolicy.RetryMode = .userInitiated,
                        completion: @escaping CompletionBlock) {
        uploadFromFile(byPath: path, parameters: parameters, keyPackets: keyPackets, dataPacketSourceFileURL: dataPacketSourceFileURL,
                       signature: signature, headers: headers, authenticated: authenticated, customAuthCredential: customAuthCredential,
                       nonDefaultTimeout: nonDefaultTimeout, retryPolicy: retryPolicy, uploadProgress: nil) { task, result in
            switch result {
            case .success(let dict): completion(task, dict, nil)
            case .failure(let error): completion(task, nil, error)
            }
        }
    }
    
    @available(*, deprecated, message: "Please use the variant returning either DecodableResponseCompletion or JSONResponseCompletion")
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
                            nonDefaultTimeout: nil, retryPolicy: .userInitiated, completion: completion)
        
    }
    
    @available(*, deprecated, message: "Please use the variant returning either DecodableResponseCompletion or JSONResponseCompletion")
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
                    nonDefaultTimeout: nil, retryPolicy: .userInitiated, completion: completion)
    }
    
    @available(*, deprecated, message: "Please use the variant returning either DecodableResponseCompletion or JSONResponseCompletion")
    func upload(byPath path: String,
                parameters: Any?,
                files: [String: URL],
                headers: [String: Any]?,
                authenticated: Bool,
                customAuthCredential: AuthCredential?,
                uploadProgress: ProgressCompletion?,
                completion: @escaping CompletionBlock) {
        self.upload(byPath: path, parameters: parameters, files: files, headers: headers, authenticated: authenticated,
                    customAuthCredential: customAuthCredential, nonDefaultTimeout: nil, retryPolicy: .userInitiated,
                    uploadProgress: uploadProgress, completion: completion)
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
    func onHumanVerify(parameters: HumanVerifyParameters, currentURL: URL?, completion: (@escaping (HumanVerifyFinishReason) -> Void))
    func getSupportURL() -> URL
}

extension HumanVerifyDelegate {
    
    @available(*, deprecated, message: "The error parameter is no longer used, please use the version without it")
    func onHumanVerify(parameters: HumanVerifyParameters, currentURL: URL?, error _: NSError, completion: (@escaping (HumanVerifyFinishReason) -> Void)) {
        onHumanVerify(parameters: parameters, currentURL: currentURL, completion: completion)
    }
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

public typealias AuthRefreshResultCompletion = (Result<Credential, AuthErrors>) -> Void

public protocol AuthDelegate: AnyObject {
    
    func authCredential(sessionUID: String) -> AuthCredential?
    func credential(sessionUID: String) -> Credential?
    
    func onRefresh(sessionUID: String, service: APIService, complete: @escaping AuthRefreshResultCompletion)
    func onUpdate(credential: Credential, sessionUID: String)
    func onLogout(sessionUID: String)
    
    // deprecated API
    
    @available(*, deprecated, message: "Please use onUpdate(auth:sessionUID:) instead")
    func onUpdate(auth: Credential)
    
    @available(*, deprecated, message: "Please use onRefresh(sessionUID:service:complete:) instead")
    func onRefresh(bySessionUID: String, complete: @escaping AuthRefreshComplete)
    
    @available(*, deprecated, message: "Please use authCredential(sessionUID:) instead")
    func getToken(bySessionUID: String) -> AuthCredential?
}

public typealias AuthRefreshComplete = (_ auth: Credential?, _ hasError: AuthErrors?) -> Void

// empty default implementations so that the objects conforming to the protocol are not required to add them by themselves
public extension AuthDelegate {
    
    @available(*, deprecated, message: "Please use authCredential(sessionUID:) instead")
    func getToken(bySessionUID: String) -> AuthCredential? { authCredential(sessionUID: bySessionUID) }
    
    @available(*, deprecated, message: "Please use onUpdate(auth:sessionUID:) instead")
    func onUpdate(auth: Credential) { }
    
    @available(*, deprecated, message: "Please use onRefresh(sessionUID:for:complete:) instead")
    func onRefresh(bySessionUID: String, complete: @escaping AuthRefreshComplete) { }
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
    
    func perform(request route: Request,
                 callCompletionBlockUsing executor: CompletionBlockExecutor = .asyncMainExecutor,
                 jsonDictionaryCompletion: @escaping (_ task: URLSessionDataTask?, _ result: Result<JSONDictionary, ResponseError>) -> Void) {
        // TODO: add executor to request so it can be passed to DoH
        request(method: route.method,
                path: route.path,
                parameters: route.parameters,
                headers: route.header,
                authenticated: route.isAuth,
                autoRetry: route.autoRetry,
                customAuthCredential: route.authCredential,
                nonDefaultTimeout: route.nonDefaultTimeout,
                retryPolicy: route.retryPolicy) { (task, result: Result<JSONDictionary, APIError>) in
            executor.execute {
                let httpCode = task.flatMap(\.response).flatMap { $0 as? HTTPURLResponse }.map(\.statusCode)
                switch result {
                case .failure(let error):
                    if let responseError = error as? ResponseError {
                        jsonDictionaryCompletion(task, .failure(responseError))
                    } else {
                        let responseCode = error.domain == ResponseErrorDomains.withResponseCode.rawValue ? error.code : nil
                        jsonDictionaryCompletion(
                            task, .failure(.init(httpCode: httpCode, responseCode: responseCode, userFacingMessage: error.localizedDescription, underlyingError: error))
                        )
                    }
                case .success(let object):
                    if let code = object.code, code != 1000, code != 1001 {
                        jsonDictionaryCompletion(
                            task, .failure(.init(httpCode: httpCode, responseCode: code, userFacingMessage: object.errorMessage, underlyingError: nil))
                        )
                    } else {
                        jsonDictionaryCompletion(task, .success(object))
                    }
                }
            }
        }
    }
    
    func perform<R>(request route: Request,
                    response: R,
                    callCompletionBlockUsing executor: CompletionBlockExecutor = .asyncMainExecutor,
                    responseCompletion: @escaping (_ task: URLSessionDataTask?, _ response: R) -> Void) where R: ResponseType {
        request(method: route.method,
                path: route.path,
                parameters: route.parameters,
                headers: route.header,
                authenticated: route.isAuth,
                autoRetry: route.autoRetry,
                customAuthCredential: route.authCredential,
                nonDefaultTimeout: route.nonDefaultTimeout,
                retryPolicy: route.retryPolicy) { (task, result: Result<JSONDictionary, APIError>) in
            executor.execute {
                let httpCode = task.flatMap(\.response).flatMap { $0 as? HTTPURLResponse }.map(\.statusCode)
                switch result {
                case .failure(let error):
                    let responseCode = error.domain == ResponseErrorDomains.withResponseCode.rawValue ? error.code : nil
                    response.httpCode = httpCode
                    response.responseCode = responseCode
                    if let responseError = error as? ResponseError {
                        response.error = responseError
                    } else {
                        response.error = .init(httpCode: httpCode, responseCode: responseCode, userFacingMessage: error.localizedDescription, underlyingError: error)
                    }
                    responseCompletion(task, response)
                case .success(let jsonDictionary):
                    let (processedResponse, possibleError) = R.parseNetworkCallResults(
                        responseObject: response,
                        originalResponse: task?.response,
                        responseDict: jsonDictionary,
                        error: result.error
                    )
                    // we keep the previous logic of enforcing response parsing even in case of error,
                    // for the sake of staying compatible with the previous implementations and not breaking client's assumptions
                    if let possibleError = possibleError {
                        _ = response.ParseResponse(jsonDictionary)
                        // the error might have changed during the decoding try, morphing it into decode error.
                        // This leads to wrong or missing erro info. Hence I restore the original error
                        response.error = possibleError
                    }
                    responseCompletion(task, processedResponse)
                }
            }
        }
    }
    
    func perform<T>(request route: Request,
                    callCompletionBlockUsing executor: CompletionBlockExecutor = .asyncMainExecutor,
                    decodableCompletion: @escaping (_ task: URLSessionDataTask?, _ result: Result<T, ResponseError>) -> Void)
    where T: APIDecodableResponse {
        request(method: route.method,
                path: route.path,
                parameters: route.parameters,
                headers: route.header,
                authenticated: route.isAuth,
                autoRetry: route.autoRetry,
                customAuthCredential: route.authCredential,
                nonDefaultTimeout: route.nonDefaultTimeout,
                retryPolicy: route.retryPolicy) { (task, result: Result<T, APIError>) in
            executor.execute {
                let httpCode = task.flatMap(\.response).flatMap { $0 as? HTTPURLResponse }.map(\.statusCode)
                switch result {
                case .failure(let error):
                    if let responseError = error as? ResponseError {
                        decodableCompletion(task, .failure(responseError))
                    } else {
                        let responseCode = error.domain == ResponseErrorDomains.withResponseCode.rawValue ? error.code : nil
                        decodableCompletion(
                            task, .failure(.init(httpCode: httpCode, responseCode: responseCode, userFacingMessage: error.localizedDescription, underlyingError: error))
                        )
                    }
                case .success(let object):
                    if let code = object.code, code != 1000, code != 1001 {
                        decodableCompletion(
                            task, .failure(.init(httpCode: httpCode, responseCode: code, userFacingMessage: object.errorMessage, underlyingError: nil))
                        )
                    } else {
                        decodableCompletion(task, .success(object))
                    }
                }
            }
        }
    }
}

public extension APIService {
    
    func performUpload(request route: Request,
                       files: [String: URL],
                       callCompletionBlockUsing executor: CompletionBlockExecutor = .asyncMainExecutor,
                       uploadProgress: ProgressCompletion?,
                       jsonDictionaryCompletion complete: @escaping (_ task: URLSessionDataTask?, _ result: Result<JSONDictionary, ResponseError>) -> Void) {
        
        upload(byPath: route.path,
               parameters: route.parameters,
               files: files,
               headers: route.header,
               authenticated: route.isAuth,
               customAuthCredential: route.authCredential,
               nonDefaultTimeout: route.nonDefaultTimeout,
               retryPolicy: route.retryPolicy,
               uploadProgress: uploadProgress) { (task, result: Result<JSONDictionary, APIService.APIError>) in
            
            executor.execute {
                let httpCode = task.flatMap(\.response).flatMap { $0 as? HTTPURLResponse }.map(\.statusCode)
                switch result {
                case .success(let response):
                    if let code = response.code, let errorMessage = response.errorMessage {
                        let responseError = ResponseError(httpCode: httpCode, responseCode: code, userFacingMessage: errorMessage, underlyingError: nil)
                        complete(task, .failure(responseError))
                    
                    } else {
                        complete(task, .success(response))
                    }
                case .failure(let error):
                    let responseCode = error.domain == ResponseErrorDomains.withResponseCode.rawValue ? error.code : nil
                    let responseError = ResponseError(httpCode: httpCode, responseCode: responseCode, userFacingMessage: nil, underlyingError: error)
                    complete(task, .failure(responseError))
                }
            }
        }
    }
    
    func performUpload<T>(request route: Request,
                          files: [String: URL],
                          callCompletionBlockUsing executor: CompletionBlockExecutor = .asyncMainExecutor,
                          uploadProgress: ProgressCompletion?,
                          decodableCompletion complete: @escaping (_ task: URLSessionDataTask?, _ result: Result<T, ResponseError>) -> Void) where T: APIDecodableResponse {
        
        upload(byPath: route.path,
               parameters: route.parameters,
               files: files,
               headers: route.header,
               authenticated: route.isAuth,
               customAuthCredential: route.authCredential,
               nonDefaultTimeout: route.nonDefaultTimeout,
               retryPolicy: route.retryPolicy,
               uploadProgress: uploadProgress) { (task, result: Result<T, APIService.APIError>) in
            executor.execute {
                let httpCode = task.flatMap(\.response).flatMap { $0 as? HTTPURLResponse }.map(\.statusCode)
                switch result {
                case .success(let response):
                    if let code = response.code, let errorMessage = response.errorMessage {
                        let responseError = ResponseError(httpCode: httpCode, responseCode: code, userFacingMessage: errorMessage, underlyingError: nil)
                        complete(task, .failure(responseError))
                    
                    } else {
                        complete(task, .success(response))
                    }
                case .failure(let error):
                    let responseCode = error.domain == ResponseErrorDomains.withResponseCode.rawValue ? error.code : nil
                    let responseError = ResponseError(httpCode: httpCode, responseCode: responseCode, userFacingMessage: nil, underlyingError: error)
                    complete(task, .failure(responseError))
                }
            }
        }
    }
    
}

// MARK: - deprecated APIs

public extension APIService {
    
    @available(*, deprecated, message: "Use perform method")
    func exec<T>(route: Request, response: T = T()) -> T? where T: Response {
        exec(route: route, responseObject: response)
    }
    
    @available(*, deprecated, message: "Use perform method")
    func exec<T>(route: Request, responseObject: T) -> T? where T: Response {
        var ret_res: T?
        var ret_error: ResponseError?
        let sema = DispatchSemaphore(value: 0)
        // 1 make a request, 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
        let completionWrapper: JSONCompletion = { task, result in
            defer {
                sema.signal()
            }
            switch T.parseNetworkCallResults(responseObject: responseObject, originalResponse: task?.response, responseDict: result.value, error: result.error) {
            case (_, let networkingError?):
                ret_error = networkingError
            case (let response, nil):
                ret_res = response
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
                     retryPolicy: route.retryPolicy,
                     jsonCompletion: completionWrapper)
        
        // wait operations
        _ = sema.wait(timeout: DispatchTime.distantFuture)
        if let e = ret_error {
            PMLog.debug(e.localizedDescription)
        }
        return ret_res
    }
    
    @available(*, deprecated, message: "Use perform method")
    func exec<T>(route: Request,
                 response: T = T(),
                 complete: @escaping  (_ task: URLSessionDataTask?, _ response: T) -> Void) where T: Response {
        exec(route: route, responseObject: response, complete: complete)
    }
    
    @available(*, deprecated, message: "Use perform method")
    func exec<T>(route: Request,
                 responseObject: T,
                 complete: @escaping  (_ task: URLSessionDataTask?, _ response: T) -> Void) where T: Response {
        
        // 1 make a request , 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
        let completionWrapper: JSONCompletion = { task, result in
            switch T.parseNetworkCallResults(responseObject: responseObject, originalResponse: task?.response, responseDict: result.value, error: result.error) {
            case (let response, _?):
                // this was a previous logic — to parse response even if there's an error
                if let resRaw = result.value {
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
                     retryPolicy: route.retryPolicy,
                     jsonCompletion: completionWrapper)
    }
    
    @available(*, deprecated, message: "Use perform method")
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
    
    @available(*, deprecated, message: "Use perform method")
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
    
    @available(*, deprecated, message: "Use perform method")
    func exec<T>(route: Request,
                 responseObject: T,
                 callCompletionBlockUsing executor: CompletionBlockExecutor = .asyncMainExecutor,
                 complete: @escaping (_ response: T) -> Void) where T: Response {
        
        // 1 make a request , 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
        let completionWrapper: JSONCompletion = { task, result in
            executor.execute {
                switch T.parseNetworkCallResults(
                    responseObject: responseObject,
                    originalResponse: task?.response,
                    responseDict: result.value,
                    error: result.error
                ) {
                case (let response, let originalError?):
                    // this was a previous logic — to parse response even if there's an error. should we move it to parseNetworkCallResults?
                    if let resRaw = result.value {
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
                     retryPolicy: route.retryPolicy,
                     jsonCompletion: completionWrapper)
    }
    
    @available(*, deprecated, message: "Use perform method")
    func exec<T>(route: Request, complete: @escaping (_ task: URLSessionDataTask?, _ result: Result<T, ResponseError>) -> Void) where T: Decodable {
        
        // 1 make a request , 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
        let completionWrapper: JSONCompletion = { task, result in
            do {
                if let res = result.value {
                    // this is a workaround for afnetworking, will change it
                    let responseData = try JSONSerialization.data(withJSONObject: res, options: .prettyPrinted)
                    let decoder = JSONDecoder.decapitalisingFirstLetter
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
                } else if let error = result.error {
                    let responseCode = error.domain == ResponseErrorDomains.withResponseCode.rawValue ? error.code : nil
                    let responseError = ResponseError(httpCode: (task?.response as? HTTPURLResponse)?.statusCode,
                                                      responseCode: responseCode,
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
                     retryPolicy: route.retryPolicy,
                     jsonCompletion: completionWrapper)
    }
    
    @available(*, deprecated, message: "Use perform method")
    func exec<T>(route: Request, complete: @escaping (_ result: Result<T, ResponseError>) -> Void) where T: Decodable {
        exec(route: route) { (_: URLSessionDataTask?, result: Result<T, ResponseError>) in
            complete(result)
        }
    }
    
    @available(*, deprecated, message: "Use performUpload")
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
                    let decoder = JSONDecoder.decapitalisingFirstLetter
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
                    let responseCode = error.domain == ResponseErrorDomains.withResponseCode.rawValue ? error.code : nil
                    let responseError = ResponseError(httpCode: (task?.response as? HTTPURLResponse)?.statusCode,
                                                      responseCode: responseCode,
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
                    retryPolicy: route.retryPolicy,
                    uploadProgress: uploadProgress,
                    completion: completionWrapper)
    }
    
    @available(*, deprecated, message: "Use performUpload")
    func upload<T>(route: Request,
                   files: [String: URL],
                   uploadProgress: ProgressCompletion?,
                   complete: @escaping (_ result: Result<T, ResponseError>) -> Void) where T: Decodable {
        upload(route: route, files: files, uploadProgress: uploadProgress) { (_: URLSessionDataTask?, result: Result<T, ResponseError>) in
            complete(result)
        }
    }
}
