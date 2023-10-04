//
//  ProtonMailAPIService.swift
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

import Foundation
import ProtonCoreDoh
import ProtonCoreLog
import ProtonCoreFoundations
import ProtonCoreNetworking
import ProtonCoreUtilities
import ProtonCoreEnvironment

#if canImport(TrustKit)
import TrustKit
#endif

// MARK: - Public API types

public protocol TrustKitProvider {
    var noTrustKit: Bool { get }
    var trustKit: TrustKit? { get }
}

public protocol URLCacheInterface {
    func removeAllCachedResponses()
}

extension URLCache: URLCacheInterface {}

public enum PMAPIServiceTrustKitProviderWrapper: TrustKitProvider {
    case instance
    public var noTrustKit: Bool { PMAPIService.noTrustKit }
    public var trustKit: TrustKit? { PMAPIService.trustKit }
}

extension PMAPIService.APIResponseCompletion {
 
    func call<T>(task: URLSessionDataTask?, error: API.APIError)
    where Left == JSONCompletion, Right == (_ task: URLSessionDataTask?, _ result: Result<T, API.APIError>) -> Void, T: APIDecodableResponse {
        switch self {
        case .left(let jsonCompletion): jsonCompletion(task, .failure(error))
        case .right(let decodableCompletion): decodableCompletion(task, .failure(error))
        }
    }
    
    func call<T>(task: URLSessionDataTask?, response: Either<[String: Any], T>)
    where Left == JSONCompletion, Right == (_ task: URLSessionDataTask?, _ result: Result<T, API.APIError>) -> Void, T: APIDecodableResponse {
        switch (self, response) {
        case (.left(let jsonCompletion), .left(let jsonObject)): jsonCompletion(task, .success(jsonObject))
        case (.right(let decodableCompletion), .right(let decodableObject)): decodableCompletion(task, .success(decodableObject))
        default:
            assertionFailure("Passing wrong response here indicates a programmers error")
        }
    }
}

extension PMAPIService.ResponseFromSession {
    
    func possibleError<T>() -> SessionResponseError?
    where Left == Result<JSONDictionary, SessionResponseError>, Right == Result<T, SessionResponseError>, T: SessionDecodableResponse {
        switch self {
        case .left(.success), .right(.success): return nil
        case .left(.failure(let error)), .right(.failure(let error)): return error
        }
    }
}

extension ResponseError: APIResponse {
    
    public var code: Int? {
        get { responseCode }
        set { self = ResponseError(httpCode: httpCode, responseCode: newValue, userFacingMessage: userFacingMessage, underlyingError: underlyingError) }
    }
    
    public var error: String? {
        get { userFacingMessage }
        set { self = ResponseError(httpCode: httpCode, responseCode: responseCode, userFacingMessage: newValue, underlyingError: underlyingError) }
    }
    
    public var details: APIResponseDetails? {
        guard let sessionError = underlyingError as? SessionResponseError else { return nil }
        switch sessionError {
        case .responseBodyIsNotAJSONDictionary(let body?, _), .responseBodyIsNotADecodableObject(let body?, _):
            if let humanVerificationDetails = try? JSONDecoder.decapitalisingFirstLetter.decode(ResponseWithHumanVerificationDetails.self, from: body).details {
                return .humanVerification(humanVerificationDetails)
            }
            
            if let deviceVerificationDetails = try? JSONDecoder.decapitalisingFirstLetter.decode(ResponseWithDeviceVerificationDetails.self, from: body).details {
                return .deviceVerification(deviceVerificationDetails)
            }
            
            if let missingScopesDetails = try? JSONDecoder.decapitalisingFirstLetter.decode(ResponseWithMissingScopesDetails.self, from: body).details {
                return .missingScopes(missingScopesDetails)
            }
            
            return nil
        case .configurationError, .networkingEngineError, .responseBodyIsNotAJSONDictionary(body: nil, _), .responseBodyIsNotADecodableObject(body: nil, _): return nil
        }
    }
}

extension Either: APIResponse where Left == JSONDictionary, Right == ResponseError {
    
    var responseDictionary: JSONDictionary { mapRight { $0.serialized }.value() }
    
    public var code: Int? {
        get { mapLeft { $0.code }.mapRight { $0.code }.value() }
        set { self = mapLeft { var tmp = $0; tmp.code = newValue; return tmp }.mapRight { var tmp = $0; tmp.code = newValue; return tmp } }
    }
    
    public var error: String? {
        get { mapLeft { $0.error }.mapRight { $0.error }.value() }
        set { self = mapLeft { var tmp = $0; tmp.error = newValue; return tmp }.mapRight { var tmp = $0; tmp.error = newValue; return tmp } }
    }
    
    public var details: APIResponseDetails? {
        mapLeft { $0.details }.mapRight { $0.details }.value()
    }
}

public class PMAPIService: APIService {
    
    typealias ResponseFromSession<T> = Either<Result<JSONDictionary, SessionResponseError>, Result<T, SessionResponseError>> where T: SessionDecodableResponse
    typealias ResponseInPMAPIService<T> = Either<Result<JSONDictionary, API.APIError>, Result<T, API.APIError>> where T: APIDecodableResponse
    typealias APIResponseCompletion<T> = Either<JSONCompletion, DecodableCompletion<T>> where T: APIDecodableResponse

    public weak var forceUpgradeDelegate: ForceUpgradeDelegate?
    public weak var humanDelegate: HumanVerifyDelegate?
    public weak var authDelegate: AuthDelegate?
    public weak var loggingDelegate: APIServiceLoggingDelegate?
    public weak var serviceDelegate: APIServiceDelegate?
    public weak var missingScopesDelegate: MissingScopesDelegate?
    
    public static var noTrustKit: Bool = false
    public static var trustKit: TrustKit?
    
    /// the session ID. this can be changed
    public var sessionUID: String = ""
    
    @available(*, deprecated, message: "This will be changed to DoHInterface type")
    public var doh: DoH & ServerConfig { get { dohInterface as! DoH & ServerConfig } set { dohInterface = newValue } }

    public var dohInterface: DoHInterface
    
    public var signUpDomain: String {
        return self.dohInterface.getSignUpString()
    }
    
    let jsonDecoder: JSONDecoder = .decapitalisingFirstLetter
    
    private(set) var session: Session
    
    private(set) var isHumanVerifyUIPresented = Atomic(false)
    private(set) var isForceUpgradeUIPresented = Atomic(false)
    private(set) var isPasswordVerifyUIPresented = Atomic(false)
    
    let protonMailResponseCodeHandler = ProtonMailResponseCodeHandler()
    let hvDispatchGroup = DispatchGroup()

    // DispatchQueue for synchronization of the device verification process
    private(set) var isDeviceVerifyProcessing = Atomic(false)
    let dvSynchronizingQueue = DispatchQueue(label: "ch.proton.api.device_verification_async", qos: .userInitiated, attributes: .concurrent)
    let dvCompletionQueue = DispatchQueue.main
    let dvDispatchGroup = DispatchGroup()
    
    let fetchAuthCredentialsAsyncQueue = DispatchQueue(label: "ch.proton.api.credential_fetch_async", qos: .userInitiated)
    let fetchAuthCredentialsSyncSerialQueue = DispatchQueue(label: "ch.proton.api.credential_fetch_sync", qos: .userInitiated)
    let fetchAuthCredentialCompletionBlockBackgroundQueue = DispatchQueue(
        label: "ch.proton.api.refresh_completion", qos: .userInitiated, attributes: [.concurrent]
    )

    public var challengeParametersProvider: ChallengeParametersProvider
    var deviceFingerprints: ChallengeProperties {
        ChallengeProperties(challenges: challengeParametersProvider.provideParametersForSessionFetching(),
                            productPrefix: challengeParametersProvider.prefix)
    }
    
    /**
     `createAPIService` creates `PMAPIService` with `doh` and `sessionID`
     It should be used when user is loged in and there is a `sessionUID` in cached `Credentials`

     - Parameter doh: required doh parameter conforming to the `DoHInterface` to encrypt domain name
     - Parameter sessionUID: required sessionUID parameter taken from cached `Credentials`
     - Parameter sessionFactory: sessionFactory parameter conforming to the `SessionFactoryInterface`, Default parameter creates `SessionFactory` instance that uses `Alamofire` session and request
     - Parameter cacheToClear: cacheToClear parameter conforming to the `URLCacheInterface`. Default parameter creates `URLCache` shared instance
     - Parameter trustKitProvider: trustKitProvider parameter conforming to the `TrustKitProvider`. Default parameter creates `PMAPIServiceTrustKitProviderWrapper` instance which allows or not to use the TrustKit
     - Returns:`PMAPIService` instance
     */
    public static func createAPIService(doh: DoHInterface,
                                        sessionUID: String,
                                        sessionFactory: SessionFactoryInterface = SessionFactory.instance,
                                        cacheToClear: URLCacheInterface = URLCache.shared,
                                        trustKitProvider: TrustKitProvider = PMAPIServiceTrustKitProviderWrapper.instance,
                                        challengeParametersProvider: ChallengeParametersProvider) -> PMAPIService {
        .init(dohInterface: doh,
              sessionUID: sessionUID,
              sessionFactory: sessionFactory,
              cacheToClear: cacheToClear,
              trustKitProvider: trustKitProvider,
              challengeParametersProvider: challengeParametersProvider)
    }

    /**
     `createAPIServiceWithoutSession` creates `PMAPIService` with `doh` and without `sessionID`
     It should be used when user has logged out or never logged in

     - Parameter doh: required doh parameter conforming to the `DoHInterface` to encrypt domain name
     - Parameter sessionFactory: sessionFactory parameter conforming to the `SessionFactoryInterface`, Default parameter creates `SessionFactory` instance that uses `Alamofire` session and request
     - Parameter cacheToClear: cacheToClear parameter conforming to the `URLCacheInterface`. Default parameter creates `URLCache` shared instance
     - Parameter trustKitProvider: trustKitProvider parameter conforming to the `TrustKitProvider`. Default parameter creates `PMAPIServiceTrustKitProviderWrapper` instance which allows or not to use the TrustKit
     - Returns:`PMAPIService` instance
     */
    public static func createAPIServiceWithoutSession(doh: DoHInterface,
                                                      sessionFactory: SessionFactoryInterface = SessionFactory.instance,
                                                      cacheToClear: URLCacheInterface = URLCache.shared,
                                                      trustKitProvider: TrustKitProvider = PMAPIServiceTrustKitProviderWrapper.instance,
                                                      challengeParametersProvider: ChallengeParametersProvider) -> PMAPIService {
        .init(dohInterface: doh,
              sessionUID: nil,
              sessionFactory: sessionFactory,
              cacheToClear: cacheToClear,
              trustKitProvider: trustKitProvider,
              challengeParametersProvider: challengeParametersProvider)
    }

    /**
     `createAPIService` creates `PMAPIService` with `environment` and `sessionID`
     It should be used when user is loged in and there is a `sessionUID` in cached `Credentials`

     - Parameter environment: required environment parameter which contains `doh` needed  to encrypt domain name
     - Parameter sessionUID: required sessionUID parameter taken from cached `Credentials`
     - Parameter sessionFactory: sessionFactory parameter conforming to the `SessionFactoryInterface`, Default parameter creates `SessionFactory` instance that uses `Alamofire` session and request
     - Parameter cacheToClear: cacheToClear parameter conforming to the `URLCacheInterface`. Default parameter creates `URLCache` shared instance
     - Parameter trustKitProvider: trustKitProvider parameter conforming to the `TrustKitProvider`. Default parameter creates `PMAPIServiceTrustKitProviderWrapper` instance which allows or not to use the TrustKit
     - Returns:`PMAPIService` instance
     */
    public static func createAPIService(environment: ProtonCoreEnvironment.Environment,
                                        sessionUID: String,
                                        sessionFactory: SessionFactoryInterface = SessionFactory.instance,
                                        cacheToClear: URLCacheInterface = URLCache.shared,
                                        trustKitProvider: TrustKitProvider = PMAPIServiceTrustKitProviderWrapper.instance,
                                        challengeParametersProvider: ChallengeParametersProvider) -> PMAPIService {
        .init(dohInterface: environment.doh,
              sessionUID: sessionUID,
              sessionFactory: sessionFactory,
              cacheToClear: cacheToClear,
              trustKitProvider: trustKitProvider,
              challengeParametersProvider: challengeParametersProvider)
    }
    
    /**
     `createAPIServiceWithoutSession` creates `PMAPIService` with `environment` and without `sessionID`
     It should be used when user has logged out or never logged in

     - Parameter environment: required environment parameter which contains `doh` needed  to encrypt domain name
     - Parameter sessionFactory: sessionFactory parameter conforming to the `SessionFactoryInterface`, Default parameter creates `SessionFactory` instance that uses `Alamofire` session and request
     - Parameter cacheToClear: cacheToClear parameter conforming to the `URLCacheInterface`. Default parameter creates `URLCache` shared instance
     - Parameter trustKitProvider: trustKitProvider parameter conforming to the `TrustKitProvider`. Default parameter creates `PMAPIServiceTrustKitProviderWrapper` instance which allows or not to use the TrustKit
     - Returns:`PMAPIService` instance
     */
    public static func createAPIServiceWithoutSession(environment: ProtonCoreEnvironment.Environment,
                                                      sessionFactory: SessionFactoryInterface = SessionFactory.instance,
                                                      cacheToClear: URLCacheInterface = URLCache.shared,
                                                      trustKitProvider: TrustKitProvider = PMAPIServiceTrustKitProviderWrapper.instance,
                                                      challengeParametersProvider: ChallengeParametersProvider) -> PMAPIService {
        .init(dohInterface: environment.doh,
              sessionUID: nil,
              sessionFactory: sessionFactory,
              cacheToClear: cacheToClear,
              trustKitProvider: trustKitProvider,
              challengeParametersProvider: challengeParametersProvider)
    }

    public func acquireSessionIfNeeded(completion: @escaping (Result<SessionAcquiringResult, APIError>) -> Void) {
        fetchExistingCredentialsOrAcquireNewUnauthCredentials(deviceFingerprints: deviceFingerprints) { result in
            switch result {
            case .foundExisting:
                completion(.success(.sessionAlreadyPresent))
            case .triedAcquiringNew(.wrongConfigurationNoDelegate):
                completion(.success(.sessionUnavailableAndNotFetched))
            case .triedAcquiringNew(.acquired):
                completion(.success(.sessionFetchedAndAvailable))
            case .triedAcquiringNew(.acquiringError(let error)):
                // no http code means the request failed because the servers are not reachable — we need to return the error
                if error.httpCode == nil {
                    completion(.failure(error.underlyingError ?? error as NSError))

                // http code means the request failed because of the server error — we just fail silently then
                } else {
                    completion(.success(.sessionUnavailableAndNotFetched))
                }
            }
        }
    }

    private init(dohInterface: DoHInterface,
                 sessionUID: String?,
                 sessionFactory: SessionFactoryInterface,
                 cacheToClear: URLCacheInterface,
                 trustKitProvider: TrustKitProvider,
                 challengeParametersProvider: ChallengeParametersProvider) {
        // TODO: remove this check once we drop doh property
        guard dohInterface is (DoH & ServerConfig) else {
            fatalError("DoH doesn't conform to DoH & ServerConfig")
        }
        self.dohInterface = dohInterface
        self.sessionUID = sessionUID ?? ""
        self.challengeParametersProvider = challengeParametersProvider
        cacheToClear.removeAllCachedResponses()

        let apiHostUrl = self.dohInterface.getCurrentlyUsedHostUrl()
        self.session = sessionFactory.createSessionInstance(url: apiHostUrl)

        self.session.setChallenge(noTrustKit: trustKitProvider.noTrustKit, trustKit: trustKitProvider.trustKit)

        dohInterface.setUpCookieSynchronization(storage: self.session.sessionConfiguration.httpCookieStorage)
    }
    
    public func getSession() -> Session? {
        return session
    }
    
    public func setSessionUID(uid: String) {
        self.sessionUID = uid
    }
    
    func transformJSONCompletion(_ jsonCompletion: @escaping JSONCompletion) -> JSONCompletion {
        
        { task, result in
            switch result {
            case .failure: jsonCompletion(task, result)
            case .success(let dict):
                if let httpResponse = task?.response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    let error: NSError
                    if let responseCode = dict["Code"] as? Int {
                        error = NSError(
                            domain: ResponseErrorDomains.withResponseCode.rawValue,
                            code: responseCode,
                            localizedDescription: dict["Error"] as? String ?? ""
                        )
                    } else {
                        error = NSError(
                            domain: ResponseErrorDomains.withStatusCode.rawValue,
                            code: httpResponse.statusCode,
                            localizedDescription: dict["Error"] as? String ?? ""
                        )
                    }
                    jsonCompletion(task, .failure(error))
                } else {
                    jsonCompletion(task, .success(dict))
                }
            }
        }
    }
}

// MARK: - Deprecated API

extension PMAPIService {

    /// by default will create a non auth api service. after calling the auth function, it will set the session. then use the delation to fetch the auth data  for this session.
    @available(*, deprecated, message: "This will be removed, use createAPIService, or createAPIServiceWithoutSession methods instead.")
    public convenience init(doh: DoH & ServerConfig,
                            sessionUID: String = "",
                            sessionFactory: SessionFactoryInterface = SessionFactory.instance,
                            cacheToClear: URLCacheInterface = URLCache.shared,
                            trustKitProvider: TrustKitProvider = PMAPIServiceTrustKitProviderWrapper.instance,
                            challengeParametersProvider: ChallengeParametersProvider) {
        self.init(dohInterface: doh, sessionUID: sessionUID,
                  sessionFactory: sessionFactory, cacheToClear: cacheToClear,
                  trustKitProvider: trustKitProvider,
                  challengeParametersProvider: challengeParametersProvider)
    }

    @available(*, deprecated, message: "This will be removed, use createAPIService, or createAPIServiceWithoutSession methods instead.")
    public convenience init(doh: DoHInterface,
                            sessionUID: String = "",
                            sessionFactory: SessionFactoryInterface = SessionFactory.instance,
                            cacheToClear: URLCacheInterface = URLCache.shared,
                            trustKitProvider: TrustKitProvider = PMAPIServiceTrustKitProviderWrapper.instance,
                            challengeParametersProvider: ChallengeParametersProvider) {
        self.init(dohInterface: doh, sessionUID: sessionUID,
                  sessionFactory: sessionFactory, cacheToClear: cacheToClear,
                  trustKitProvider: trustKitProvider,
                  challengeParametersProvider: challengeParametersProvider)
    }

    @available(*, deprecated, message: "This will be removed, use createAPIService, or createAPIServiceWithoutSession methods instead.")
    public convenience init(environment: ProtonCoreEnvironment.Environment,
                            sessionUID: String = "",
                            sessionFactory: SessionFactoryInterface = SessionFactory.instance,
                            cacheToClear: URLCacheInterface = URLCache.shared,
                            trustKitProvider: TrustKitProvider = PMAPIServiceTrustKitProviderWrapper.instance,
                            challengeParametersProvider: ChallengeParametersProvider) {
        self.init(dohInterface: environment.doh, sessionUID: sessionUID,
                  sessionFactory: sessionFactory, cacheToClear: cacheToClear,
                  trustKitProvider: trustKitProvider,
                  challengeParametersProvider: challengeParametersProvider)
    }
    
    internal func getResponseError(task: URLSessionDataTask?, response: APIResponse, error: NSError?) -> ResponseError {
        return ResponseError(httpCode: (task?.response as? HTTPURLResponse)?.statusCode,
                             responseCode: response.code,
                             userFacingMessage: response.errorMessage,
                             underlyingError: error)
    }
    
}
