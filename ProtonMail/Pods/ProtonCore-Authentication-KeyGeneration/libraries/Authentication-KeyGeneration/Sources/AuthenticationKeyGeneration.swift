//
//  AuthenticationKeyGeneration.swift
//  ProtonCore-TestingToolkit - Created on 10.06.2021.
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
import ProtonCore_Authentication
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_FeatureSwitch

// swiftlint:disable function_parameter_count

public protocol AuthenticatorKeyGenerationInterface {

  func createAddressKey(_ credential: Credential?,
                        user: User,
                        address: Address,
                        password: String,
                        salt: Data,
                        isPrimary: Bool,
                        completion: @escaping (Result<Key, AuthErrors>) -> Void)

  func setupAccountKeys(_ credential: Credential?,
                        addresses: [Address],
                        password: String,
                        completion: @escaping (Result<(), AuthErrors>) -> Void)
}

public extension AuthenticatorKeyGenerationInterface {

  func createAddressKey(user: User, address: Address, password: String, salt: Data, isPrimary: Bool,
                        completion: @escaping (Result<Key, AuthErrors>) -> Void) {
      createAddressKey(nil, user: user, address: address, password: password, salt: salt, isPrimary: isPrimary, completion: completion)
  }

  func setupAccountKeys(addresses: [Address], password: String, completion: @escaping (Result<(), AuthErrors>) -> Void) {
      setupAccountKeys(nil, addresses: addresses, password: password, completion: completion)
  }
}

extension Authenticator: AuthenticatorKeyGenerationInterface {

    public func createAddressKey(_ credential: Credential? = nil,
                                 user: User,
                                 address: Address,
                                 password: String,
                                 salt: Data,
                                 isPrimary: Bool,
                                 completion: @escaping (Result<Key, AuthErrors>) -> Void) {
        getRandomSRPModulus { result in
            switch result {
            case let .success(data):
                // TODO:: clean up after v2 tested
                if FeatureFactory.shared.isEnabled(.useKeymigrationPhaseV2) {
                    let keySetup = AddressKeySetup()
                    guard let userKey = user.keys.first?.privateKey else {
                        completion(.failure(.addressKeySetupError(KeySetupError.invalidKey)))
                        return
                    }
                    do {
                        let key = try keySetup.generateAddressKey(keyName: address.email, email: address.email,
                                                                  armoredUserKey: userKey, password: password, salt: salt,
                                                                  addrType: address.type)
                        var route = try keySetup.setupCreateAddressKeyRoute(key: key, addressId: address.addressID, isPrimary: isPrimary)
                        if let auth = credential {
                            route.auth = AuthCredential(auth)
                        }
                        self.apiService.perform(request: route) { (_, result: Result<AuthService.CreateAddressKeysEndpointResponse, ResponseError>) in
                            switch result {
                            case .failure(let responseError):
                                completion(.failure(.from(responseError)))
                            case let .success(data):
                                completion(.success(data.key))
                            }
                        }
                    } catch {
                        completion(.failure(.addressKeySetupError(error)))
                    }
                } else {
                    let keySetup = AddressKeySetupV1()
                    do {
                        let key = try keySetup.generateAddressKey(keyName: address.email, email: address.email, password: password, salt: salt)
                        var route = try keySetup.setupCreateAddressKeyRoute(key: key, modulus: data.modulus, modulusId: data.modulusID, addressId: address.addressID, isPrimary: isPrimary)
                        if let auth = credential {
                            route.auth = AuthCredential(auth)
                        }
                        self.apiService.exec(route: route) { (result: Result<AuthService.CreateAddressKeysEndpointResponseV1, ResponseError>) in
                            switch result {
                            case .failure(let responseError):
                                completion(.failure(.from(responseError)))
                            case let .success(data):
                                completion(.success(data.key))
                            }
                        }
                    } catch {
                        completion(.failure(.addressKeySetupError(error)))
                    }
                    
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func setupAccountKeys(_ credential: Credential? = nil,
                                 addresses: [Address],
                                 password: String,
                                 completion: @escaping (Result<(), AuthErrors>) -> Void) {
        getRandomSRPModulus { result in
            switch result {
            case let .success(data):
                // key generation is really slow for account keys, do not block the main thread
                DispatchQueue.global(qos: .background).async {
                    // TODO:: clean up after v2 tested
                    if FeatureFactory.shared.isEnabled(.useKeymigrationPhaseV2) {
                        let keySetup = AccountKeySetup()
                        do {
                            let key = try keySetup.generateAccountKey(addresses: addresses, password: password)
                            var route = try keySetup.setupSetupKeysRoute(password: password,
                                                                         accountKey: key, modulus: data.modulus, modulusId: data.modulusID)
                            if let auth = credential {
                                route.auth = AuthCredential(auth)
                            }
                            self.apiService.perform(request: route) { (_, result: Result<AuthService.SetupKeysEndpointResponse, ResponseError>) in
                                switch result {
                                case .failure(let responseError):
                                    completion(.failure(.from(responseError)))
                                case .success:
                                    completion(.success(()))
                                }
                            }
                        } catch {
                            completion(.failure(.addressKeySetupError(error)))
                        }
                    } else {
                        let keySetup = AccountKeySetupV1()
                        do {
                            let key = try keySetup.generateAccountKey(addresses: addresses, password: password)
                            var route = try keySetup.setupSetupKeysRoute(password: password,
                                                                         key: key, modulus: data.modulus, modulusId: data.modulusID)
                            if let auth = credential {
                                route.auth = AuthCredential(auth)
                            }
                            self.apiService.exec(route: route) { (result: Result<AuthService.SetupKeysEndpointResponse, ResponseError>) in
                                switch result {
                                case .failure(let responseError):
                                    completion(.failure(.from(responseError)))
                                case .success:
                                    completion(.success(()))
                                }
                            }
                        } catch {
                            completion(.failure(.addressKeySetupError(error)))
                        }
                    }
                    
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
