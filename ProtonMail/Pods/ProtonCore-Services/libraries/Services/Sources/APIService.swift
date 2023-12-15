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

// swiftlint:disable identifier_name todo

import Foundation
import ProtonCoreDoh
import ProtonCoreLog
import ProtonCoreFoundations
import ProtonCoreUtilities
import ProtonCoreNetworking

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
    typealias DecodableCompletion<T> = (_ task: URLSessionDataTask?, _ result: Result<T, APIError>) -> Void where T: APIDecodableResponse
    // TODO: modernize the download as well?
    typealias DownloadCompletion = (URLResponse?, URL?, NSError?) -> Void

    func request(method: HTTPMethod,
                 path: String,
                 parameters: Any?,
                 headers: [String: Any]?,
                 authenticated: Bool,
                 authRetry: Bool,
                 customAuthCredential: AuthCredential?,
                 nonDefaultTimeout: TimeInterval?,
                 retryPolicy: ProtonRetryPolicy.RetryMode,
                 onDataTaskCreated: @escaping (URLSessionDataTask) -> Void,
                 jsonCompletion: @escaping JSONCompletion)

    func request<T>(method: HTTPMethod,
                    path: String,
                    parameters: Any?,
                    headers: [String: Any]?,
                    authenticated: Bool,
                    authRetry: Bool,
                    customAuthCredential: AuthCredential?,
                    nonDefaultTimeout: TimeInterval?,
                    retryPolicy: ProtonRetryPolicy.RetryMode,
                    onDataTaskCreated: @escaping (URLSessionDataTask) -> Void,
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

// Variants without `onDataTaskCreated: @escaping (URLSessionDataTask) -> Void` parameter
public extension API {
    func request(method: HTTPMethod,
                 path: String,
                 parameters: Any?,
                 headers: [String: Any]?,
                 authenticated: Bool,
                 authRetry: Bool,
                 customAuthCredential: AuthCredential?,
                 nonDefaultTimeout: TimeInterval?,
                 retryPolicy: ProtonRetryPolicy.RetryMode,
                 jsonCompletion: @escaping JSONCompletion) {
        self.request(method: method,
                     path: path,
                     parameters: parameters,
                     headers: headers,
                     authenticated: authenticated,
                     authRetry: authRetry,
                     customAuthCredential: customAuthCredential,
                     nonDefaultTimeout: nonDefaultTimeout,
                     retryPolicy: retryPolicy,
                     onDataTaskCreated: { _ in },
                     jsonCompletion: jsonCompletion)
    }

    func request<T>(method: HTTPMethod,
                    path: String,
                    parameters: Any?,
                    headers: [String: Any]?,
                    authenticated: Bool,
                    authRetry: Bool,
                    customAuthCredential: AuthCredential?,
                    nonDefaultTimeout: TimeInterval?,
                    retryPolicy: ProtonRetryPolicy.RetryMode,
                    decodableCompletion: @escaping DecodableCompletion<T>) where T: APIDecodableResponse {
        self.request(method: method,
                     path: path,
                     parameters: parameters,
                     headers: headers,
                     authenticated: authenticated,
                     authRetry: authRetry,
                     customAuthCredential: customAuthCredential,
                     nonDefaultTimeout: nonDefaultTimeout,
                     retryPolicy: retryPolicy,
                     onDataTaskCreated: { _ in },
                     decodableCompletion: decodableCompletion)
    }
}

public extension API {

    @available(*, deprecated, message: "Please use the variant returning either DecodableResponseCompletion or JSONResponseCompletion")
    func request(method: HTTPMethod,
                 path: String,
                 parameters: Any?,
                 headers: [String: Any]?,
                 authenticated: Bool,
                 authRetry: Bool,
                 customAuthCredential: AuthCredential?,
                 nonDefaultTimeout: TimeInterval?,
                 retryPolicy: ProtonRetryPolicy.RetryMode = .userInitiated,
                 completion: CompletionBlock?) {
        request(method: method, path: path, parameters: parameters, headers: headers, authenticated: authenticated, authRetry: authRetry,
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
                 authRetry: Bool,
                 customAuthCredential: AuthCredential?,
                 retryPolicy: ProtonRetryPolicy.RetryMode = .userInitiated,
                 completion: CompletionBlock?) {
        self.request(method: method, path: path, parameters: parameters, headers: headers,
                     authenticated: authenticated, authRetry: authRetry, customAuthCredential: customAuthCredential,
                     nonDefaultTimeout: nil, retryPolicy: retryPolicy, completion: completion)
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

public typealias AuthRefreshResultCompletion = (Result<Credential, AuthErrors>) -> Void

public protocol AuthSessionInvalidatedDelegate: AnyObject {
    /// This method is called whenever session is invalidated.
    /// * If the unauthenticated session is invalidate, we can fetch new one without any user input,
    ///   so this method should have no user-visible effects, just clear the credentials from persistance.
    /// * If the authenticated session is invalidated, we cannot recreate the auth session
    ///   without user providing the credentials. So this method should cause the logout:
    ///     * clear credentials from persistance
    ///     * remove all user cache and data from memory
    ///     * present the login/signup flow
    func sessionWasInvalidated(for sessionUID: String, isAuthenticatedSession: Bool)
}

public protocol AuthDelegate: AnyObject {

    /// Accessors for the credentials. They are used by APIService to fill in
    /// the authentication header in the requests.
    /// These typically require a trip to the keychain, so it's advantageous to make them async.
    func authCredential(sessionUID: String) async -> AuthCredential?
    func credential(sessionUID: String) async -> Credential?

    /// This method is called when the credentials are updated — after the credentials refresh call made:
    /// * due to 401 from the server
    /// * invoked manually during login to fetch latest scopes
    ///
    /// Conceptually, it's used when there are already credentials for this particular session available, we just update them.
    func onUpdate(credential: Credential, sessionUID: String)

    /// This method is called when the session is obtained or upgraded:
    /// * after the unauth session acquisition call succeeds
    /// * after the auth call succeeds (unauth session upgraded OR auth session established if unauth session feature disabled)
    ///
    /// Conceptually, it's used when it's the first time that we get the credentials for particular session.
    func onSessionObtaining(credential: Credential)

    /// This method is for adding the additional user information into the credentials
    /// during the login/signup.
    /// It's called only during the login/signup.
    func onAdditionalCredentialsInfoObtained(sessionUID: String, password: String?, salt: String?, privateKey: String?)

    /// This delegate is used, as name states, only for login/signup flow
    /// It should inform the login flow about the authenticated session being invalidated,
    /// so that the logic can return to the initial screen
    var authSessionInvalidatedDelegateForLoginAndSignup: AuthSessionInvalidatedDelegate? { get set }

    /// This method ic called when the authenticated session is invalidated.
    /// We cannot recreate the auth session without user providing the credentials,
    /// so this method should cause the logout (hence the name):
    ///   * clear credentials from persistance
    ///   * remove all user cache and data from memory
    ///   * present the login/signup flow
    func onAuthenticatedSessionInvalidated(sessionUID: String)

    /// This method is called when the unauthenticated session is invalidated.
    /// We can fetch new unauth session without any user input, transparently,
    /// so this method should have no user-visible effects, just clear the credentials from persistance
    func onUnauthenticatedSessionInvalidated(sessionUID: String)
}

public typealias AuthRefreshComplete = (_ auth: Credential?, _ hasError: AuthErrors?) -> Void

public enum SessionAcquiringResult {
    case sessionFetchedAndAvailable(AuthCredential)
    case sessionAlreadyPresent(AuthCredential)
    case sessionUnavailableAndNotFetched
}

public enum AuthCredentialFetchingResult: Equatable {
    case found(credentials: AuthCredential)
    case notFound
    case wrongConfigurationNoDelegate

    public var toNSError: NSError? {
        switch self {
        case .found: return nil
        case .notFound: return AuthCredentialFetchingResult.emptyTokenError
        case .wrongConfigurationNoDelegate: return AuthCredentialFetchingResult.noAuthDelegateError
        }
    }

    static var noAuthDelegateError: NSError { .protonMailError(0, localizedDescription: "AuthDelegate is required") }

    static var emptyTokenError: NSError { .protonMailError(0, localizedDescription: "Empty token") }
}

public protocol APIService: API, RequestPerforming {

    // session and credentials management
    var sessionUID: String { get }
    func setSessionUID(uid: String)
    func acquireSessionIfNeeded(completion: @escaping (Result<SessionAcquiringResult, APIError>) -> Void)
    func fetchAuthCredentials(completion: @escaping (AuthCredentialFetchingResult) -> Void)
    // delegates
    var authDelegate: AuthDelegate? { get set }
    var serviceDelegate: APIServiceDelegate? { get set }
    var humanDelegate: HumanVerifyDelegate? { get set }
    var forceUpgradeDelegate: ForceUpgradeDelegate? { get set }
    var challengeParametersProvider: ChallengeParametersProvider { get set }

    // doh
    var dohInterface: DoHInterface { get }

    // signup up
    var signUpDomain: String { get }
}

typealias RequestComplete = (_ task: URLSessionDataTask?, _ response: Response) -> Void

public extension APIService {

    func perform(request route: Request,
                 callCompletionBlockUsing executor: CompletionBlockExecutor = .asyncMainExecutor,
                 onDataTaskCreated: @escaping (URLSessionDataTask) -> Void = { _ in },
                 jsonDictionaryCompletion: @escaping (_ task: URLSessionDataTask?, _ result: Result<JSONDictionary, ResponseError>) -> Void) {
        // TODO: add executor to request so it can be passed to DoH
        request(method: route.method,
                path: route.path,
                parameters: route.calculatedParameters,
                headers: route.header,
                authenticated: route.isAuth,
                authRetry: route.authRetry,
                customAuthCredential: route.authCredential,
                nonDefaultTimeout: route.nonDefaultTimeout,
                retryPolicy: route.retryPolicy,
                onDataTaskCreated: onDataTaskCreated) { (task, result: Result<JSONDictionary, APIError>) in
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

    /// Asynchronous variant of `perform(request:callCompletionBlockUsing:jsonDictionaryCompletion)`.
    ///  - Return a tuple of type `(URLSessionDataTask?, JSONDictionary)` if success.
    ///  - Throw an error of type `ResponseError` if failure.
    @available(macOS 10.15, *)
    func perform(request route: Request,
                 onDataTaskCreated: @escaping (URLSessionDataTask) -> Void = { _ in },
                 callCompletionBlockUsing executor: CompletionBlockExecutor = .asyncMainExecutor)
    async throws -> (URLSessionDataTask?, JSONDictionary) {
        try await withCheckedThrowingContinuation { continuation in
            perform(request: route,
                    callCompletionBlockUsing: executor,
                    onDataTaskCreated: onDataTaskCreated) { task, result in
                switch result {
                case .success(let jsonDictionary):
                    continuation.resume(returning: (task, jsonDictionary))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func perform<R>(request route: Request,
                    response: R,
                    callCompletionBlockUsing executor: CompletionBlockExecutor = .asyncMainExecutor,
                    onDataTaskCreated: @escaping (URLSessionDataTask) -> Void = { _ in },
                    responseCompletion: @escaping (_ task: URLSessionDataTask?, _ response: R) -> Void) where R: ResponseType {
        request(method: route.method,
                path: route.path,
                parameters: route.calculatedParameters,
                headers: route.header,
                authenticated: route.isAuth,
                authRetry: route.authRetry,
                customAuthCredential: route.authCredential,
                nonDefaultTimeout: route.nonDefaultTimeout,
                retryPolicy: route.retryPolicy,
                onDataTaskCreated: onDataTaskCreated) { (task, result: Result<JSONDictionary, APIError>) in
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

    /// Asynchronous variant of `perform(request:response:callCompletionBlockUsing:responseCompletion)`.
    /// - Return a tuple of type `(URLSessionDataTask?, some ResponseType)`
    @available(macOS 10.15, *)
    func perform<R>(request route: Request,
                    response: R,
                    callCompletionBlockUsing executor: CompletionBlockExecutor = .asyncMainExecutor,
                    onDataTaskCreated: @escaping (URLSessionDataTask) -> Void = { _ in })
    async -> (URLSessionDataTask?, R) where R: ResponseType {
        await withCheckedContinuation { continuation in
            perform(request: route,
                    response: response,
                    callCompletionBlockUsing: executor,
                    onDataTaskCreated: onDataTaskCreated) { task, result in
                continuation.resume(returning: (task, result))
            }
        }
    }

    func perform<T>(request route: Request,
                    callCompletionBlockUsing executor: CompletionBlockExecutor = .asyncMainExecutor,
                    onDataTaskCreated: @escaping (URLSessionDataTask) -> Void = { _ in },
                    decodableCompletion: @escaping (_ task: URLSessionDataTask?, _ result: Result<T, ResponseError>) -> Void)
    where T: APIDecodableResponse {
        request(method: route.method,
                path: route.path,
                parameters: route.calculatedParameters,
                headers: route.header,
                authenticated: route.isAuth,
                authRetry: route.authRetry,
                customAuthCredential: route.authCredential,
                nonDefaultTimeout: route.nonDefaultTimeout,
                retryPolicy: route.retryPolicy,
                onDataTaskCreated: onDataTaskCreated) { (task: URLSessionDataTask?, result: Result<T, APIError>) in
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
                    decodableCompletion(task, .success(object))
                }
            }
        }
    }

    /// Asynchronous variant of `perform(request:callCompletionBlockUsing:decodableCompletion)`.
    /// - Return a tuple of type `(URLSessionDataTask?, APIDecodableResponse)` if success.
    /// - Throw an error of type `ResponseError` if failure.
    @available(macOS 10.15, *)
    func perform<R>(request route: Request,
                    callCompletionBlockUsing executor: CompletionBlockExecutor = .asyncMainExecutor,
                    onDataTaskCreated: @escaping (URLSessionDataTask) -> Void = { _ in })
    async throws -> (URLSessionDataTask?, R) where R: APIDecodableResponse {
        try await withCheckedThrowingContinuation { continuation in
            perform(request: route,
                    callCompletionBlockUsing: executor,
                    onDataTaskCreated: onDataTaskCreated,
                    decodableCompletion: { (task: URLSessionDataTask?, result: Result<R, ResponseError>) in
                switch result {
                case .success(let object):
                    continuation.resume(returning: (task, object))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
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
               parameters: route.calculatedParameters,
               files: files,
               headers: route.header,
               authenticated: route.isAuth,
               customAuthCredential: route.authCredential,
               nonDefaultTimeout: route.nonDefaultTimeout,
               retryPolicy: route.retryPolicy,
               uploadProgress: uploadProgress) { (task: URLSessionDataTask?, result: Result<JSONDictionary, APIService.APIError>) in

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
                    if let responseError = error as? ResponseError { complete(task, .failure(responseError)); return }
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
               parameters: route.calculatedParameters,
               files: files,
               headers: route.header,
               authenticated: route.isAuth,
               customAuthCredential: route.authCredential,
               nonDefaultTimeout: route.nonDefaultTimeout,
               retryPolicy: route.retryPolicy,
               uploadProgress: uploadProgress) { (task: URLSessionDataTask?, result: Result<T, APIService.APIError>) in
            executor.execute {
                let httpCode = task.flatMap(\.response).flatMap { $0 as? HTTPURLResponse }.map(\.statusCode)
                switch result {
                case .success(let response):
                    complete(task, .success(response))
                case .failure(let error):
                    if let responseError = error as? ResponseError { complete(task, .failure(responseError)); return }
                    let responseCode = error.domain == ResponseErrorDomains.withResponseCode.rawValue ? error.code : nil
                    let responseError = ResponseError(httpCode: httpCode, responseCode: responseCode, userFacingMessage: nil, underlyingError: error)
                    complete(task, .failure(responseError))
                }
            }
        }
    }

}

// MARK: - Deprecated APIs

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
                     parameters: route.calculatedParameters,
                     headers: route.header,
                     authenticated: route.isAuth,
                     authRetry: route.authRetry,
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
                     parameters: route.calculatedParameters,
                     headers: route.header,
                     authenticated: route.isAuth,
                     authRetry: route.authRetry,
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
                     parameters: route.calculatedParameters,
                     headers: route.header,
                     authenticated: route.isAuth,
                     authRetry: route.authRetry,
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
                     parameters: route.calculatedParameters,
                     headers: route.header,
                     authenticated: route.isAuth,
                     authRetry: route.authRetry,
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
                    parameters: route.calculatedParameters,
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

extension APIService {
    public func performRequest(request: Request,
                               parameters: Any?,
                               headers: [String: Any]?,
                               onDataTaskCreated: @escaping (URLSessionDataTask) -> Void = { _ in },
                               jsonCompletion: JSONCompletion?) {
        self.request(
            method: request.method,
            path: request.path,
            parameters: parameters,
            headers: headers,
            authenticated: request.isAuth,
            authRetry: request.authRetry,
            customAuthCredential: request.authCredential,
            nonDefaultTimeout: request.nonDefaultTimeout,
            retryPolicy: request.retryPolicy,
            onDataTaskCreated: onDataTaskCreated,
            jsonCompletion: { task, result in
                jsonCompletion?(task, result)
            }
        )
    }
}

// swiftlint:enable identifier_name todo
