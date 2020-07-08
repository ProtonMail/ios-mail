//
//  SignInManager.swift
//  PMAuthentication
//
//  Created by Anatoly Rosencrantz on 19/02/2020.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation

public protocol SrpAuthProtocol: class {
    init?(_ version: Int, username: String?, password: String?, salt: String?, signedModulus: String?, serverEphemeral: String?)
    func generateProofs(of length: Int) throws -> AnyObject
}

public protocol SrpProofsProtocol: class {
    var clientProof: Data? { get }
    var clientEphemeral: Data? { get }
    var expectedServerProof: Data? { get }
}

public enum PasswordMode: Int, Codable {
    case one = 1, two = 2
}

public class GenericAuthenticator<SRP: SrpAuthProtocol, PROOF: SrpProofsProtocol>: NSObject {
    public typealias Completion = (Result<Status, Error>) -> Void
    
    public enum Status {
        case ask2FA(TwoFactorContext)
        case newCredential(Credential, PasswordMode)
        case updatedCredential(Credential)
    }
    
    public enum Errors: Error {
        case emptyAuthInfoResponse
        case emptyAuthResponse
        case emptyServerSrpAuth
        case emptyClientSrpAuth
        case wrongServerProof
        case serverError(NSError)

        case notImplementedYet(String)
    }
    
    public struct Configuration {
        public init(trust: TrustChallenge?,
                    hostUrl: String,
                    clientVersion: String)
        {
            self.trust = trust
            self.hostUrl = hostUrl
            self.clientVersion = clientVersion
        }
        
        var trust: TrustChallenge?
        var hostUrl: String
        var clientVersion: String
    }
    
    private weak var trustInterceptor: SessionDelegate? // weak because URLSession holds a strong reference to delegate
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        let delegate = SessionDelegate()
        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        self.trustInterceptor = delegate
        return session
    }()
    
    public convenience init(configuration: Configuration) {
        self.init()
        self.update(configuration: configuration)
    }
    
    // we do not want this to be ever used
    override private init() { }
    
    deinit {
        self.session.finishTasksAndInvalidate()
    }
    
    public func update(configuration: Configuration) {
        AuthService.trust = configuration.trust
        AuthService.hostUrl = configuration.hostUrl
        AuthService.clientVersion = configuration.clientVersion
    }
    
    /// Clear login, when preiously unauthenticated
    public func authenticate(username: String,
                             password: String,
                             completion: @escaping Completion)
    {
        // 1. auth info request
        let authInfoEndpoint = AuthService.InfoEndpoint(username: username)
        
        self.session.dataTask(with: authInfoEndpoint.request) { responseData, response, networkingError in
            guard networkingError == nil else {
                return completion(.failure(networkingError!))
            }
            guard let responseData = responseData else {
                return completion(.failure(Errors.emptyAuthInfoResponse))
            }
            
            // 2. build SRP things
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .decapitaliseFirstLetter
                
                // server error code
                if let error = try? decoder.decode(ErrorResponse.self, from: responseData) {
                    throw Errors.serverError(NSError(error))
                }
                
                // server SRP
                let response = try decoder.decode(AuthService.InfoEndpoint.Response.self, from: responseData)
                guard let auth = SRP(response.version,
                                         username: username,
                                         password: password,
                                         salt: response.salt,
                                         signedModulus: response.modulus,
                                         serverEphemeral: response.serverEphemeral) else
                {
                    throw Errors.emptyServerSrpAuth
                }
                
                // client SRP
                let srpClient = try auth.generateProofs(of: 2048) as! PROOF
                guard let clientEphemeral = srpClient.clientEphemeral,
                    let clientProof = srpClient.clientProof,
                    let expectedServerProof = srpClient.expectedServerProof else
                {
                    throw Errors.emptyClientSrpAuth
                }
                
                // 3. auth request
                let authEndpoint = AuthService.AuthEndpoint(username: username,
                                                     ephemeral: clientEphemeral,
                                                     proof: clientProof,
                                                     session: response.SRPSession,
                                                     serverProof: expectedServerProof)
                self.session.dataTask(with: authEndpoint.request) { responseData, response, networkingError in
                    guard networkingError == nil else {
                        return completion(.failure(networkingError!))
                    }
                    guard let responseData = responseData else {
                        return completion(.failure(Errors.emptyAuthResponse))
                    }
                    
                    do {
                        // server error code
                        if let error = try? decoder.decode(ErrorResponse.self, from: responseData) {
                            throw Errors.serverError(NSError(error))
                        }
                        
                        // relevant response
                        let response = try decoder.decode(AuthService.AuthEndpoint.Response.self, from: responseData)
                        guard let serverProof = Data(base64Encoded: response.serverProof),
                            expectedServerProof == serverProof else
                        {
                            throw Errors.wrongServerProof
                        }
                        
                        // are we done yet or need 2FA?
                        switch response._2FA.enabled {
                        case .off:
                            let credential = Credential(res: response)
                            completion(.success(.newCredential(credential, response.passwordMode)))
                        case .on:
                            let context = (Credential(res: response), response.passwordMode)
                            completion(.success(.ask2FA(context)))
                        
                        case .u2f, .otp:
                            throw Errors.notImplementedYet("U2F not implemented yet")
                        }
                        
                    } catch let parsingError {
                        completion(.failure(parsingError))
                    }
                }.resume()
                
            } catch let parsingError {
                return completion(.failure(parsingError))
            }
            
        }.resume()
    }
    
    /// Continue clear login flow with 2FA code
    public func confirm2FA(_ twoFactorCode: Int,
                           context: TwoFactorContext,
                           completion: @escaping Completion)
    {
        let twoFAEndpoint = AuthService.TwoFAEndpoint(code: twoFactorCode, token: context.credential.accessToken, UID: context.credential.UID)
        self.session.dataTask(with: twoFAEndpoint.request) { responseData, response, networkingError in
            guard networkingError == nil else {
                return completion(.failure(networkingError!))
            }
            guard let responseData = responseData else {
                return completion(.failure(Errors.emptyAuthResponse))
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .decapitaliseFirstLetter
                
                // server error code
                if let error = try? decoder.decode(ErrorResponse.self, from: responseData) {
                    throw Errors.serverError(NSError(error))
                }
                
                let response = try decoder.decode(AuthService.TwoFAEndpoint.Response.self, from: responseData)

                var credential = context.credential
                credential.updateScope(response.scope)
                completion(.success(.newCredential(credential, context.passwordMode)))
                
            } catch let parsingError {
                completion(.failure(parsingError))
            }
        }.resume()
    }
    
    // Refresh expired access token using refresh token
    public func refreshCredential(_ oldCredential: Credential,
                                  completion: @escaping Completion)
    {
        let refreshEndpoint = AuthService.RefreshEndpoint(refreshToken: oldCredential.refreshToken, UID: oldCredential.UID)
        self.session.dataTask(with: refreshEndpoint.request) { responseData, response, networkingError in
            guard networkingError == nil else {
                return completion(.failure(networkingError!))
            }
            guard let responseData = responseData else {
                return completion(.failure(Errors.emptyAuthResponse))
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .decapitaliseFirstLetter
                
                // server error code
                if let error = try? decoder.decode(ErrorResponse.self, from: responseData) {
                    throw Errors.serverError(NSError(error))
                }
                
                let response = try decoder.decode(AuthService.RefreshEndpoint.Response.self, from: responseData)

                // refresh endpoint does not return UID in the response, so we have to inject old one manually
                let credential = Credential(res: response, UID: oldCredential.UID)
                completion(.success(.updatedCredential(credential)))
                
            } catch let parsingError {
                completion(.failure(parsingError))
            }
        }.resume()
    }
}

public typealias TrustChallenge = (URLSession, URLAuthenticationChallenge, @escaping URLSessionDelegateCompletion) -> Void
public typealias URLSessionDelegateCompletion = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void

// Point to inject TrustKit
class SessionDelegate: NSObject, URLSessionDelegate {
    public func urlSession(_ session: URLSession,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping URLSessionDelegateCompletion)
    {
        if let trust = AuthService.trust {
            trust(session, challenge, completionHandler)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
