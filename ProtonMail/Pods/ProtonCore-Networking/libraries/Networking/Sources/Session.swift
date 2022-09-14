//
//  Session.swift
//  ProtonCore-Networking - Created on 6/24/21.
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
import TrustKit

public typealias JSONDictionary = [String: Any]

public typealias SessionDecodableResponse = Decodable

public struct HumanVerificationDetails: Codable, Equatable {
    
    let token: String?
    let title: String?
    let methods: [String]?
    
    enum CodingKeys: String, CodingKey {
        // even though the server response JSON use uppercase keys, we specify the lowercase keys here
        // because we handle the uppercase keys globally by using the JSONDecoder
        // that uses the custom KeyDecodingStrategy called JSONDecoder.decapitaliseFirstLetter
        case token = "humanVerificationToken"
        case title = "title"
        case methods = "humanVerificationMethods"
        
        // we provide the uppercase variants for when we work with JSON dictionary and not with Codable objects
        var uppercased: String {
            "\(rawValue.prefix(1).uppercased())\(rawValue.dropFirst())"
        }
    }
    
    public var serialized: [String: Any] {
        var responseDict: [String: Any] = [:]
        if let token = token { responseDict[CodingKeys.token.uppercased] = token }
        if let title = title { responseDict[CodingKeys.title.uppercased] = title }
        if let methods = methods { responseDict[CodingKeys.methods.uppercased] = methods }
        return responseDict
    }
    
    public init(token: String?, title: String?, methods: [String]?) {
        self.token = token
        self.title = title
        self.methods = methods
    }
    
    init(jsonDictionary details: [String: Any]) {
        self.token = details[HumanVerificationDetails.CodingKeys.token.uppercased] as? String
        self.title = details[HumanVerificationDetails.CodingKeys.title.uppercased] as? String
        self.methods = details[HumanVerificationDetails.CodingKeys.methods.uppercased] as? [String]
    }
}

public protocol APIResponse {
    var code: Int? { get set }
    var error: String? { get set }
    
    // HV part
    var details: HumanVerificationDetails? { get }
}

public extension APIResponse {
    var errorMessage: String? { get { error } set { error = newValue } }
}

extension APIResponse {
    public var serialized: [String: Any] {
        var responseDict: [String: Any] = [:]
        if let code = code { responseDict["Code"] = code }
        if let error = error { responseDict["Error"] = error }
        if let details = details { responseDict["Details"] = details.serialized }
        return responseDict
    }
}

extension Dictionary: APIResponse where Key == String, Value == Any {
    
    public var code: Int? { get { self["Code"] as? Int } set { self["Code"] = newValue } }
    
    public var error: String? { get { self["Error"] as? String } set { self["Error"] = newValue } }
    
    public var details: HumanVerificationDetails? {
        guard let details = self["Details"] as? [String: Any] else { return nil }
        return HumanVerificationDetails(jsonDictionary: details)
    }
}

public typealias APIDecodableResponse = APIResponse & SessionDecodableResponse

public enum SessionResponseError: Error {
    
    case configurationError
    case responseBodyIsNotAJSONDictionary(body: Data?, response: HTTPURLResponse?)
    case responseBodyIsNotADecodableObject(body: Data?, response: HTTPURLResponse?)
    case networkingEngineError(underlyingError: NSError)
    
    private var withoutResponse: SessionResponseError {
        switch self {
        case .configurationError: return self
        case .responseBodyIsNotAJSONDictionary(let body, _): return .responseBodyIsNotAJSONDictionary(body: body, response: nil)
        case .responseBodyIsNotADecodableObject(let body, _): return .responseBodyIsNotADecodableObject(body: body, response: nil)
        case .networkingEngineError: return self
        }
    }
    
    public var underlyingError: NSError {
        switch self {
        case .configurationError: return self as NSError
        case .responseBodyIsNotAJSONDictionary(let data, let response?), .responseBodyIsNotADecodableObject(let data, let response?):
            if let data = data, let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return ResponseError(httpCode: response.statusCode, responseCode: object["Code"] as? Int, userFacingMessage: object["Error"] as? String,
                                     underlyingError: self.withoutResponse as NSError) as NSError
            } else {
                return ResponseError(httpCode: response.statusCode, responseCode: nil, userFacingMessage: nil,
                                     underlyingError: self.withoutResponse as NSError) as NSError
            }
        case .responseBodyIsNotAJSONDictionary, .responseBodyIsNotADecodableObject:
            return self as NSError
        case .networkingEngineError(let underlyingError): return underlyingError
        }
    }
}

@available(*, deprecated, message: "Use the signatures with either a JSON dictionary or codable type in the response")
public typealias ResponseCompletion = (_ task: URLSessionDataTask?, _ response: Any?, _ error: NSError?) -> Void

public typealias DownloadCompletion = (_ response: URLResponse?, _ url: URL?, _ error: NSError?) -> Void
public typealias ProgressCompletion = (_ progress: Progress) -> Void

public let defaultTimeout: TimeInterval = 60.0

public func handleAuthenticationChallenge(
    didReceive challenge: URLAuthenticationChallenge,
    noTrustKit: Bool,
    trustKit: TrustKit?,
    challengeCompletionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void,
    trustKitCompletionHandler: @escaping(URLSession.AuthChallengeDisposition,
                                         URLCredential?, @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void = { disposition, credential, completionHandler in completionHandler(disposition, credential) }
) {
    if noTrustKit {
        guard let trust = challenge.protectionSpace.serverTrust else {
            challengeCompletionHandler(.performDefaultHandling, nil)
            return
        }
        let credential = URLCredential(trust: trust)
        challengeCompletionHandler(.useCredential, credential)
        
    } else if let tk = trustKit {
        let wrappedCompletionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void = { disposition, credential in
            trustKitCompletionHandler(disposition, credential, challengeCompletionHandler)
        }
        guard tk.pinningValidator.handle(challenge, completionHandler: wrappedCompletionHandler) else {
            // TrustKit did not handle this challenge: perhaps it was not for server trust
            // or the domain was not pinned. Fall back to the default behavior
            challengeCompletionHandler(.performDefaultHandling, nil)
            return
        }
        
    } else {
        assertionFailure("TrustKit not initialized correctly")
        challengeCompletionHandler(.performDefaultHandling, nil)
        
    }
}

public protocol Session {
    
    typealias DecodableResponseCompletion<T> = (_ task: URLSessionDataTask?,
                                                _ result: Result<T, SessionResponseError>) -> Void where T: SessionDecodableResponse
    
    typealias JSONResponseCompletion = (_ task: URLSessionDataTask?, _ result: Result<JSONDictionary, SessionResponseError>) -> Void
    
    func generate(with method: HTTPMethod,
                  urlString: String,
                  parameters: Any?,
                  timeout: TimeInterval?,
                  retryPolicy: ProtonRetryPolicy.RetryMode) throws -> SessionRequest
    
    func request(with request: SessionRequest, completion: @escaping JSONResponseCompletion)
    
    func request<T>(with request: SessionRequest,
                    jsonDecoder: JSONDecoder?,
                    completion: @escaping DecodableResponseCompletion<T>) where T: SessionDecodableResponse
    
    func download(with request: SessionRequest,
                  destinationDirectoryURL: URL,
                  completion: @escaping DownloadCompletion)

    // swiftlint:disable function_parameter_count
    func upload(with request: SessionRequest,
                keyPacket: Data,
                dataPacket: Data,
                signature: Data?,
                completion: @escaping JSONResponseCompletion,
                uploadProgress: ProgressCompletion?)
    
    // swiftlint:disable function_parameter_count
    func upload<T>(with request: SessionRequest,
                   keyPacket: Data,
                   dataPacket: Data,
                   signature: Data?,
                   jsonDecoder: JSONDecoder?,
                   completion: @escaping DecodableResponseCompletion<T>,
                   uploadProgress: ProgressCompletion?) where T: SessionDecodableResponse
    
    func upload(with request: SessionRequest,
                files: [String: URL],
                completion: @escaping JSONResponseCompletion,
                uploadProgress: ProgressCompletion?)
    
    func upload<T>(with request: SessionRequest,
                   files: [String: URL],
                   jsonDecoder: JSONDecoder?,
                   completion: @escaping DecodableResponseCompletion<T>,
                   uploadProgress: ProgressCompletion?) where T: SessionDecodableResponse

    // swiftlint:disable function_parameter_count
    func uploadFromFile(with request: SessionRequest,
                        keyPacket: Data,
                        dataPacketSourceFileURL: URL,
                        signature: Data?,
                        completion: @escaping JSONResponseCompletion,
                        uploadProgress: ProgressCompletion?)
    
    // swiftlint:disable function_parameter_count
    func uploadFromFile<T>(with request: SessionRequest,
                           keyPacket: Data,
                           dataPacketSourceFileURL: URL,
                           signature: Data?,
                           jsonDecoder: JSONDecoder?,
                           completion: @escaping DecodableResponseCompletion<T>,
                           uploadProgress: ProgressCompletion?) where T: SessionDecodableResponse
    
    func setChallenge(noTrustKit: Bool, trustKit: TrustKit?)
    
    func failsTLS(request: SessionRequest) -> String?
    
    var sessionConfiguration: URLSessionConfiguration { get }
}

public extension Session {
    
    @available(*, deprecated, message: "Please use the variant returning either DecodableResponseCompletion or JSONResponseCompletion")
    func request(with request: SessionRequest, completion: @escaping ResponseCompletion) {
        self.request(with: request) { task, result in
            switch result {
            case .success(let response): completion(task, response, nil)
            case .failure(let error):
                completion(task, nil, error.underlyingError)
            }
        }
    }
    
    @available(*, deprecated, message: "Please use the variant returning either DecodableResponseCompletion or JSONResponseCompletion")
    func upload(with request: SessionRequest,
                keyPacket: Data,
                dataPacket: Data,
                signature: Data?,
                completion: @escaping ResponseCompletion) {
        self.upload(with: request,
                    keyPacket: keyPacket,
                    dataPacket: dataPacket,
                    signature: signature,
                    completion: completion,
                    uploadProgress: nil)
    }

    @available(*, deprecated, message: "Please use the variant returning either DecodableResponseCompletion or JSONResponseCompletion")
    // swiftlint:disable function_parameter_count
    func upload(with request: SessionRequest,
                keyPacket: Data, dataPacket: Data, signature: Data?,
                completion: @escaping ResponseCompletion,
                uploadProgress: ProgressCompletion?) {
        upload(with: request, keyPacket: keyPacket, dataPacket: dataPacket, signature: signature) { task, result in
            switch result {
            case .success(let response): completion(task, response, nil)
            case .failure(let error): completion(task, nil, error.underlyingError)
            }
        } uploadProgress: { progress in
            uploadProgress?(progress)
        }
    }
    
    @available(*, deprecated, message: "Please use the variant returning either DecodableResponseCompletion or JSONResponseCompletion")
    func upload(with request: SessionRequest,
                files: [String: URL],
                completion: @escaping ResponseCompletion) {
        self.upload(with: request, files: files, completion: completion, uploadProgress: nil)
    }
    
    @available(*, deprecated, message: "Please use the variant returning either DecodableResponseCompletion or JSONResponseCompletion")
    func upload(with request: SessionRequest,
                files: [String: URL],
                completion: @escaping ResponseCompletion,
                uploadProgress: ProgressCompletion?) {
        self.upload(with: request, files: files) { task, result in
            switch result {
            case .success(let response): completion(task, response, nil)
            case .failure(let error): completion(task, nil, error.underlyingError)
            }
        } uploadProgress: { progress in
            uploadProgress?(progress)
        }
    }

    @available(*, deprecated, message: "Please use the variant returning either DecodableResponseCompletion or JSONResponseCompletion")
    func uploadFromFile(with request: SessionRequest,
                        keyPacket: Data,
                        dataPacketSourceFileURL: URL,
                        signature: Data?,
                        completion: @escaping ResponseCompletion) {
        self.uploadFromFile(with: request,
                            keyPacket: keyPacket,
                            dataPacketSourceFileURL: dataPacketSourceFileURL,
                            signature: signature,
                            completion: completion,
                            uploadProgress: nil)
    }

    @available(*, deprecated, message: "Please use the variant returning either DecodableResponseCompletion or JSONResponseCompletion")
    // swiftlint:disable function_parameter_count
    func uploadFromFile(with request: SessionRequest,
                        keyPacket: Data,
                        dataPacketSourceFileURL: URL,
                        signature: Data?,
                        completion: @escaping ResponseCompletion,
                        uploadProgress: ProgressCompletion?) {
        self.uploadFromFile(with: request,
                            keyPacket: keyPacket,
                            dataPacketSourceFileURL: dataPacketSourceFileURL,
                            signature: signature) { task, result in
            switch result {
            case .success(let response): completion(task, response, nil)
            case .failure(let error): completion(task, nil, error.underlyingError)
            }
        } uploadProgress: { progress in
            uploadProgress?(progress)
        }
    }
}

extension Session {
    
    public func generate(with method: HTTPMethod, urlString: String, parameters: Any? = nil, timeout: TimeInterval? = nil, retryPolicy: ProtonRetryPolicy.RetryMode) throws -> SessionRequest {
        return SessionRequest.init(parameters: parameters,
                                   urlString: urlString,
                                   method: method,
                                   timeout: timeout ?? defaultTimeout,
                                   retryPolicy: retryPolicy)
    }
}

public protocol SessionFactoryInterface {
    func createSessionInstance(url apiHostUrl: String) -> Session
    func createSessionRequest(parameters: Any?, urlString: String, method: HTTPMethod, timeout: TimeInterval, retryPolicy: ProtonRetryPolicy.RetryMode) -> SessionRequest
}

public final class SessionFactory: SessionFactoryInterface {
    
    public static let instance = SessionFactory()
    
    private init() {}
    
    public static func createSessionInstance(url apiHostUrl: String) -> Session {
        instance.createSessionInstance(url: apiHostUrl)
    }
    
    public static func createSessionRequest(parameters: Any?,
                                            urlString: String,
                                            method: HTTPMethod,
                                            timeout: TimeInterval,
                                            retryPolicy: ProtonRetryPolicy.RetryMode = .userInitiated) -> SessionRequest {
        instance.createSessionRequest(parameters: parameters, urlString: urlString, method: method, timeout: timeout, retryPolicy: retryPolicy)
    }
    
    public func createSessionInstance(url apiHostUrl: String) -> Session {
        #if canImport(Alamofire)
        AlamofireSession()
        #elseif canImport(AFNetworking)
        AFNetworkingSession(url: apiHostUrl)
        #endif
    }
    
    public func createSessionRequest(
        parameters: Any?, urlString: String, method: HTTPMethod, timeout: TimeInterval, retryPolicy: ProtonRetryPolicy.RetryMode = .userInitiated
    ) -> SessionRequest {
        #if canImport(Alamofire)
        AlamofireRequest(parameters: parameters, urlString: urlString, method: method, timeout: timeout, retryPolicy: retryPolicy)
        #elseif canImport(AFNetworking)
        SessionRequest(parameters: parameters, urlString: urlString, method: method, timeout: timeout)
        #endif
    }
}

public class SessionRequest {
    init(parameters: Any?, urlString: String, method: HTTPMethod, timeout: TimeInterval, retryPolicy: ProtonRetryPolicy.RetryMode = .userInitiated) {
        self.parameters = parameters
        self.method = method
        self.urlString = urlString
        self.timeout = timeout
        self.interceptor = ProtonRetryPolicy(mode: retryPolicy)
    }
    
    var _request: URLRequest?
    public var request: URLRequest? {
        get {
            return self._request
        }
        set {
            self._request = newValue
            self._request?.timeoutInterval = self.timeout
        }
    }
    
    let parameters: Any?
    let urlString: String
    let method: HTTPMethod
    let timeout: TimeInterval
    let interceptor: ProtonRetryPolicy
    
    // in the future this dict may have race condition issue. fix it later
    private var headers: [String: String] = [:]
    
    internal func headerCounts() -> Int {
        return self.headers.count
    }
    
    internal func exsit(key: String) -> Bool {
        return self.headers[key] != nil
    }
    
    internal func matches(key: String, value: String) -> Bool {
        guard let v = self.headers[key] else {
            return false
        }
        return v == value
    }
    
    internal func value(key: String) -> String? {
        return self.headers[key]
    }
    
    public func setValue(header: String, _ value: String) {
        self.headers[header] = value
    }
    
    // must call after the request be set
    public func updateHeader() {
        for (header, value) in self.headers {
            self.request?.setValue(value, forHTTPHeaderField: header)
        }
    }
}
