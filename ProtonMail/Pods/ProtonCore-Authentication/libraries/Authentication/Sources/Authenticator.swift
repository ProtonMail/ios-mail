//
//  Authenticator.swift
//  ProtonCore-Authentication - Created on 19/02/2020.
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

#if canImport(Crypto_VPN)
import Crypto_VPN
#elseif canImport(Crypto)
import Crypto
#endif
import Foundation
import ProtonCore_APIClient
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_Services

#if canImport(OpenPGP)
import ThisModuleMustNotHaveOpenPGPLinked
#endif

public class Authenticator: NSObject, AuthenticatorInterface {
    public typealias Errors = AuthErrors
    public typealias Completion = (Result<Status, AuthErrors>) -> Void
    
    public enum Status {
        case ask2FA(TwoFactorContext)
        case newCredential(Credential, PasswordMode)
        case updatedCredential(Credential)
    }
    
    public var apiService: APIService!
    public init(api: APIService) {
        self.apiService = api
        super.init()
    }
    
    // we do not want this to be ever used
    override private init() { }

    /// Clear login, when preiously unauthenticated
    public func authenticate(username: String, password PASSWORD: String, completion: @escaping Completion) {
        // 1. auth info request
        let authClient = AuthService(api: self.apiService)
        authClient.info(username: username) { (response) in
            if let responseError = response.error {
                completion(.failure(.networkingError(responseError)))
                return
            }
            
            // guard let response
            guard let salt = response.salt,
                  let signedModulus = response.modulus,
                  let serverEphemeral = response.serverEphemeral,
                  let srpSession = response.srpSession
            else {
                return completion(.failure(Errors.emptyAuthInfoResponse))
            }

            // 2. build SRP things
            do {
                let passSlic = PASSWORD.data(using: .utf8)
                guard let auth = SrpAuth.init(response.version,
                                              username: username,
                                              password: passSlic,
                                              b64salt: salt,
                                              signedModulus: signedModulus,
                                              serverEphemeral: serverEphemeral) else
                {
                    return completion(.failure(Errors.emptyServerSrpAuth))
                }
                
                // client SRP
                let srpClient = try auth.generateProofs(2048)
                guard let clientEphemeral = srpClient.clientEphemeral,
                      let clientProof = srpClient.clientProof,
                      let expectedServerProof = srpClient.expectedServerProof else
                {
                    return completion(.failure(Errors.emptyClientSrpAuth))
                }
                
                // 3. auth request
                authClient.auth(username: username, ephemeral: clientEphemeral, proof: clientProof, session: srpSession) { (result) in
                    switch result {
                    case .failure(let responseError):
                        completion(.failure(Errors.networkingError(responseError)))
                    case .success(let authResponse):
                        
                        guard expectedServerProof == Data(base64Encoded: authResponse.serverProof) else {
                            return completion(.failure(Errors.wrongServerProof))
                        }
                        // are we done yet or need 2FA?
                        switch authResponse._2FA.enabled {
                        case .off:
                            let credential = Credential(res: authResponse, userName: username, userID: authResponse.userID)
                            self.apiService.setSessionUID(uid: credential.UID)
                            completion(.success(.newCredential(credential, authResponse.passwordMode)))
                        case .on:
                            let credential = Credential(res: authResponse, userName: username, userID: authResponse.userID)
                            self.apiService.setSessionUID(uid: credential.UID)
                            let context = (credential, authResponse.passwordMode)
                            completion(.success(.ask2FA(context)))
                        case .u2f, .otp:
                            completion(.failure(Errors.notImplementedYet("U2F not implemented yet")))
                        }
                    }
                }
            } catch let parsingError {
                return completion(.failure(.parsingError(parsingError)))
            }
        }
    }
    
    /// Continue clear login flow with 2FA code
    public func confirm2FA(_ twoFactorCode: String,
                           context: TwoFactorContext, completion: @escaping Completion)  {
        var route = AuthService.TwoFAEndpoint(code: twoFactorCode)
        route.auth = AuthCredential(context.credential)
        self.apiService.exec(route: route) { (result: Result<AuthService.TwoFAResponse, ResponseError>) in
            switch result {
            case .failure(let responseError):
                completion(.failure(Errors.networkingError(responseError)))
            case .success(let response):
                var credential = context.credential
                credential.updateScope(response.scope)
                completion(.success(.newCredential(credential, context.passwordMode)))
            }
        }
    }
    
    // Refresh expired access token using refresh token
    public func refreshCredential(_ oldCredential: Credential, completion: @escaping Completion) {
        refreshCredential(oldCredential) { (result: Result<Credential, ResponseError>) in
            switch result {
            case .failure(let responseError):
                completion(.failure(.networkingError(responseError)))
            case .success(let credential):
                completion(.success(.updatedCredential(credential)))
            }
        }
    }

    // Refresh expired access token using refresh token
    fileprivate func refreshCredential(_ oldCredential: Credential, completion: @escaping (Result<Credential, ResponseError>) -> Void) {
        let route = AuthService.RefreshEndpoint(authCredential: AuthCredential( oldCredential))
        self.apiService.exec(route: route) { (result: Result<AuthService.RefreshResponse, ResponseError>) in
            switch result {
            case .failure(let responseError):
                completion(.failure(responseError))
            case .success(let response):
                let credential = Credential(res: response, UID: oldCredential.UID, userName: oldCredential.userName, userID: oldCredential.userID)
                completion(.success(credential))
            }
        }
    }

    public func checkAvailable(_ username: String, completion: @escaping (Result<(), AuthErrors>) -> Void) {
        let route = AuthService.UserAvailableEndpoint(username: username)
        
        self.apiService.exec(route: route) { (result: Result<AuthService.UserAvailableResponse, ResponseError>) in
            switch result {
            case .failure(let responseError):
                completion(.failure(.networkingError(responseError)))
            case .success:
                completion(.success(()))
            }
        }
    }

    public func setUsername(_ credential: Credential? = nil, username: String, completion: @escaping (Result<(), AuthErrors>) -> Void) {
        var route = AuthService.SetUsernameEndpoint(username: username)
        if let auth = credential {
            route.auth = AuthCredential(auth)
        }
        self.apiService.exec(route: route) { (result: Result<AuthService.SetUsernameResponse, ResponseError>) in
            switch result {
            case .failure(let responseError):
                completion(.failure(.networkingError(responseError)))
            case .success:
                completion(.success(()))
            }
        }
    }

    public func createAddress(_ credential: Credential? = nil,
                              domain: String,
                              displayName: String? = nil,
                              siganture: String? = nil,
                              completion: @escaping (Result<Address, AuthErrors>) -> Void) {
        var route = AuthService.CreateAddressEndpoint(domain: domain, displayName: displayName, signature: siganture)
        if let auth = credential {
            route.auth = AuthCredential(auth)
        }
        self.apiService.exec(route: route) { (result: Result<AuthService.CreateAddressEndpointResponse, ResponseError>) in
            switch result {
            case .failure(let responseError):
                completion(.failure(.networkingError(responseError)))
            case let .success(data):
                completion(.success(data.address))
            }
        }
    }
    
    public func createUser(userParameters: UserParameters, completion: @escaping (Result<(), AuthErrors>) -> Void) {
        let route = AuthService.CreateUserEndpoint(userParameters: userParameters)
        self.apiService.exec(route: route) { (_, response) in
            if let responseError = response.error {
                completion(.failure(.networkingError(responseError)))
            } else {
                completion(.success(()))
            }
        }
    }

    public func createExternalUser(externalUserParameters: ExternalUserParameters, completion: @escaping (Result<(), AuthErrors>) -> Void) {
        let route = AuthService.CreateExternalUserEndpoint(externalUserParameters: externalUserParameters)
        self.apiService.exec(route: route) { (_, response) in
            if let responseError = response.error {
                completion(.failure(.networkingError(responseError)))
            } else {
                completion(.success(()))
            }
        }
    }

    public func getUserInfo(_ credential: Credential? = nil, completion: @escaping (Result<User, AuthErrors>) -> Void) {
        var route = AuthService.UserInfoEndpoint()
        if let auth = credential {
            route.auth = AuthCredential(auth)
        }
        self.apiService.exec(route: route) { (result: Result<AuthService.UserResponse, ResponseError>) in
            switch result {
            case .failure(let responseError):
                completion(.failure(.networkingError(responseError)))
            case .success(let response):
                completion(.success(response.user))
            }
        }
    }
    
    public func getAddresses(_ credential: Credential? = nil, completion: @escaping (Result<[Address], AuthErrors>) -> Void) {
        var route = AuthService.AddressEndpoint()
        if let auth = credential {
            route.auth = AuthCredential(auth)
        }
        self.apiService.exec(route: route) { (result: Result<AuthService.AddressesResponse, ResponseError>) in
            switch result {
            case .failure(let responseError):
                completion(.failure(.networkingError(responseError)))
            case .success(let response):
                completion(.success(response.addresses))
            }
        }
    }
    
    public func getKeySalts(_ credential: Credential? = nil, completion: @escaping (Result<[KeySalt], AuthErrors>) -> Void) {
        var route = AuthService.KeySaltsEndpoint()
        if let auth = credential {
            route.auth = AuthCredential(auth)
        }
        self.apiService.exec(route: route) { (result: Result<AuthService.KeySaltsResponse, ResponseError>) in
            switch result {
            case .failure(let responseError):
                completion(.failure(.networkingError(responseError)))
            case .success(let response):
                completion(.success(response.keySalts))
            }
        }
    }
    
    public func closeSession(_ credential: Credential, completion: @escaping (Result<AuthService.EndSessionResponse, AuthErrors>) -> Void) {
        let route = AuthService.EndSessionEndpoint(auth: AuthCredential(credential))
        self.apiService.exec(route: route) { (result: Result<AuthService.EndSessionResponse, ResponseError>) in
            switch result {
            case .failure(let responseError):
                completion(.failure(.networkingError(responseError)))
            case .success(let response):
                completion(.success(response))
            }
        }
    }

    public func getRandomSRPModulus(completion: @escaping (Result<AuthService.ModulusEndpointResponse, AuthErrors>) -> Void) {
        let route = AuthService.ModulusEndpoint()
        self.apiService.exec(route: route) { (result: Result<AuthService.ModulusEndpointResponse, ResponseError>) in
            switch result {
            case .failure(let responseError):
                completion(.failure(.networkingError(responseError)))
            case .success(let response):
                completion(.success(response))
            }
        }
    }
}

public enum RefreshAccessToken {

    public static func callAsFunction(
        credential: Credential, using api: APIService, completion: @escaping (Result<Credential, ResponseError>) -> Void
    ) {
        refresh(credential: credential, using: Authenticator(api: api), completion: completion)
    }

    public static func callAsFunction(
        credential: Credential, using authenticator: Authenticator, completion: @escaping (Result<Credential, ResponseError>) -> Void
    ) {
        refresh(credential: credential, using: authenticator, completion: completion)
    }

    private static func refresh(
        credential: Credential, using authenticator: Authenticator, completion: @escaping (Result<Credential, ResponseError>) -> Void
    ) {
        authenticator.refreshCredential(credential, completion: completion)
    }

}
