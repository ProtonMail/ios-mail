//
//  Authenticator.swift
//  PMAuthentication - Created on 19/02/2020.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Crypto
import Foundation
import PMCommon

public class Authenticator: NSObject {
    public typealias Errors = AuthErrors
    public typealias Completion = (Result<Status, Error>) -> Void
    
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
            guard  response.error == nil else {
                return completion(.failure(response.error!))
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
                guard let auth = SrpAuth(response.version,
                                         username: username,
                                         password: PASSWORD,
                                         salt: salt,
                                         signedModulus: signedModulus,
                                         serverEphemeral: serverEphemeral) else
                {
                    return completion(.failure( Errors.emptyServerSrpAuth))
                }
                
                // client SRP
                let srpClient = try auth.generateProofs(2048)
                guard let clientEphemeral = srpClient.clientEphemeral,
                      let clientProof = srpClient.clientProof,
                      let expectedServerProof = srpClient.expectedServerProof else
                {
                    return completion(.failure( Errors.emptyClientSrpAuth))
                }
                
                // 3. auth request
                authClient.auth(username: username, ephemeral: clientEphemeral, proof: clientProof, session: srpSession) { (result) in
                    switch result {
                    case .failure(let error):
                        completion(.failure(Errors.serverError(error as NSError) ))
                    case .success(let authResponse):
                        
                        guard expectedServerProof == Data(base64Encoded: authResponse.serverProof) else {
                            return completion(.failure(Errors.wrongServerProof))
                        }
                        // are we done yet or need 2FA?
                        switch authResponse._2FA.enabled {
                        case .off:
                            let credential = Credential(res: authResponse)
                            self.apiService.setSessionUID(uid: credential.UID)
                            completion(.success(.newCredential(credential, authResponse.passwordMode)))
                        case .on:
                            let credential = Credential(res: authResponse)
                            self.apiService.setSessionUID(uid: credential.UID)
                            let context = (credential, authResponse.passwordMode)
                            completion(.success(.ask2FA(context)))
                        case .u2f, .otp:
                            completion(.failure(Errors.notImplementedYet("U2F not implemented yet")))
                        }
                    }
                }
            } catch let parsingError {
                return completion(.failure(parsingError))
            }
        }
    }
    
    /// Continue clear login flow with 2FA code
    public func confirm2FA(_ twoFactorCode: String,
                           context: TwoFactorContext, completion: @escaping Completion)  {
        var route = AuthService.TwoFAEndpoint(code: twoFactorCode)
        route.auth = AuthCredential(context.credential) //TODO:: fix me. this is temp
        self.apiService.exec(route: route) { (result: Result<AuthService.TwoFAResponse, Error>) in
            switch result {
            case .failure(let error):
                completion(.failure(Errors.serverError(error as NSError)))
            case .success(let response):
                var credential = context.credential
                credential.updateScope(response.scope)
                completion(.success(.newCredential(credential, context.passwordMode)))
            }
        }
    }
    
    // Refresh expired access token using refresh token
    public func refreshCredential(_ oldCredential: Credential, completion: @escaping Completion) {
        let route = AuthService.RefreshEndpoint(authCredential: AuthCredential( oldCredential))
        self.apiService.exec(route: route) { (result: Result<AuthService.RefreshResponse, Error>) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                let credential = Credential(res: response, UID: oldCredential.UID)
                completion(.success(.updatedCredential(credential)))
            }
        }
    }

    public func checkAvailable(_ username: String, completion: @escaping (Result<(), Error>) -> Void) {
        let route = AuthService.UserAvailableEndpoint(username: username)
        
        self.apiService.exec(route: route) { (result: Result<AuthService.UserAvailableResponse, Error>) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                completion(.success(()))
            }
        }
    }

    public func setUsername(_ credential: Credential? = nil, username: String, completion: @escaping (Result<(), Error>) -> Void) {
        var route = AuthService.SetUsernameEndpoint(username: username)
        if let auth = credential {
            route.auth = AuthCredential(auth)
        }
        self.apiService.exec(route: route) { (result: Result<AuthService.SetUsernameResponse, Error>) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                completion(.success(()))
            }
        }
    }

    public func createAddress(_ credential: Credential? = nil, domain: String, displayName: String? = nil, siganture: String? = nil, completion: @escaping (Result<Address, Error>) -> Void) {
        var route = AuthService.CreateAddressEndpoint(domain: domain, displayName: displayName, signature: siganture)
        if let auth = credential {
            route.auth = AuthCredential(auth)
        }
        self.apiService.exec(route: route) { (result: Result<AuthService.CreateAddressEndpointResponse, Error>) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case let .success(data):
                completion(.success(data.address))
            }
        }
    }
    
    public func getUserInfo(_ credential: Credential? = nil, completion: @escaping (Result<User, Error>) -> Void) {
        var route = AuthService.UserInfoEndpoint()
        if let auth = credential {
            route.auth = AuthCredential(auth)
        }
        self.apiService.exec(route: route) { (result: Result<AuthService.UserResponse, Error>) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let salts):
                completion(.success(salts.user))
            }
        }
    }
    
    public func getAddresses(_ credential: Credential? = nil, completion: @escaping (Result<[Address], Error>) -> Void) {
        var route = AuthService.AddressEndpoint()
        if let auth = credential {
            route.auth = AuthCredential(auth)
        }
        self.apiService.exec(route: route) { (result: Result<AuthService.AddressesResponse, Error>) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                completion(.success(response.addresses))
            }
        }
    }
    
    public func getKeySalts(_ credential: Credential? = nil, completion: @escaping (Result<[AddressKeySalt], Error>) -> Void) {
        var route = AuthService.KeySaltsEndpoint()
        if let auth = credential {
            route.auth = AuthCredential(auth)
        }
        self.apiService.exec(route: route) { (result: Result<AuthService.KeySaltsResponse, Error>) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                completion(.success(response.keySalts))
            }
        }
    }
    
    public func closeSession(_ credential: Credential, completion: @escaping (Result<AuthService.EndSessionResponse, Error>) -> Void) {
        let route = AuthService.EndSessionEndpoint(auth: AuthCredential(credential))
        self.apiService.exec(route: route, complete: completion)
    }

    public func getRandomSRPModulus(completion: @escaping (Result<AuthService.ModulusEndpointResponse, Error>) -> Void) {
        let route = AuthService.ModulusEndpoint()
        self.apiService.exec(route: route, complete: completion)
    }

    public func createAddressKey(_ credential: Credential? = nil, address: Address, password: String, salt: Data, primary: Bool, completion: @escaping (Result<AddressKey, Error>) -> Void) {
        getRandomSRPModulus { result in
            switch result {
            case let .success(data):
                let keySetup = AddressKeySetup()
                do {
                    let key = try keySetup.generateAddressKey(keyName: address.email, email: address.email, password: password, salt: salt)
                    var route = try keySetup.setupCreateAddressKeyRoute(key: key, modulus: data.modulus, modulusId: data.modulusID, addressId: address.ID, primary: primary)
                    if let auth = credential {
                        route.auth = AuthCredential(auth)
                    }
                    self.apiService.exec(route: route) { (result: Result<AuthService.CreateAddressKeysEndpointResponse, Error>) in
                        switch result {
                        case .failure(let error):
                            completion(.failure(error))
                        case let .success(data):
                            completion(.success(data.key))
                        }
                    }
                } catch {
                    completion(.failure(error))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func setupAccountKeys(_ credential: Credential? = nil, addresses: [Address], password: String, completion: @escaping (Result<(), Error>) -> Void) {
        getRandomSRPModulus { result in
            switch result {
            case let .success(data):
                // key generation is really slow for account keys, do not block the main thread
                DispatchQueue.global(qos: .background).async {
                    let keySetup = AccountKeySetup()
                    do {
                        let key = try keySetup.generateAccountKey(addresses: addresses, password: password)
                        var route = try keySetup.setupSetupKeysRoute(password: password, key: key, modulus: data.modulus, modulusId: data.modulusID)
                        if let auth = credential {
                            route.auth = AuthCredential(auth)
                        }
                        self.apiService.exec(route: route) { (result: Result<AuthService.SetupKeysEndpointResponse, Error>) in
                            switch result {
                            case .failure(let error):
                                completion(.failure(error))
                            case .success:
                                completion(.success(()))
                            }
                        }
                    } catch {
                        completion(.failure(error))
                    }
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
