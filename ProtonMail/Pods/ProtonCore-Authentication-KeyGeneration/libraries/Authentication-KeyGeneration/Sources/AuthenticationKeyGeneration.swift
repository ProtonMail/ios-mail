//
//  AuthenticationKeyGeneration.swift
//  ProtonCore-Authentication-KeyGeneration
//
//  Created by Krzysztof Siejkowski on 10/06/2021.
//

import Foundation
import ProtonCore_Authentication
import ProtonCore_DataModel
import ProtonCore_Networking

public protocol AuthenticatorKeyGenerationInterface {

  func createAddressKey(_ credential: Credential?,
                        address: Address,
                        password: String,
                        salt: Data,
                        primary: Bool,
                        completion: @escaping (Result<Key, AuthErrors>) -> Void)

  func setupAccountKeys(_ credential: Credential?,
                        addresses: [Address],
                        password: String,
                        completion: @escaping (Result<(), AuthErrors>) -> Void)
}

public extension AuthenticatorKeyGenerationInterface {

  func createAddressKey(address: Address, password: String, salt: Data, primary: Bool,
                        completion: @escaping (Result<Key, AuthErrors>) -> Void) {
      createAddressKey(nil, address: address, password: password, salt: salt, primary: primary, completion: completion)
  }

  func setupAccountKeys(addresses: [Address], password: String, completion: @escaping (Result<(), AuthErrors>) -> Void) {
      setupAccountKeys(nil, addresses: addresses, password: password, completion: completion)
  }
}

extension Authenticator: AuthenticatorKeyGenerationInterface {

    public func createAddressKey(_ credential: Credential? = nil,
                                 address: Address,
                                 password: String,
                                 salt: Data,
                                 primary: Bool,
                                 completion: @escaping (Result<Key, AuthErrors>) -> Void) {
        getRandomSRPModulus { result in
            switch result {
            case let .success(data):
                let keySetup = AddressKeySetup()
                do {
                    let key = try keySetup.generateAddressKey(keyName: address.email, email: address.email, password: password, salt: salt)
                    var route = try keySetup.setupCreateAddressKeyRoute(key: key, modulus: data.modulus, modulusId: data.modulusID, addressId: address.addressID, primary: primary)
                    if let auth = credential {
                        route.auth = AuthCredential(auth)
                    }
                    self.apiService.exec(route: route) { (result: Result<AuthService.CreateAddressKeysEndpointResponse, ResponseError>) in
                        switch result {
                        case .failure(let responseError):
                            completion(.failure(.networkingError(responseError)))
                        case let .success(data):
                            completion(.success(data.key))
                        }
                    }
                } catch {
                    completion(.failure(.addressKeySetupError(error)))
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
                    let keySetup = AccountKeySetup()
                    do {
                        let key = try keySetup.generateAccountKey(addresses: addresses, password: password)
                        var route = try keySetup.setupSetupKeysRoute(password: password, key: key, modulus: data.modulus, modulusId: data.modulusID)
                        if let auth = credential {
                            route.auth = AuthCredential(auth)
                        }
                        self.apiService.exec(route: route) { (result: Result<AuthService.SetupKeysEndpointResponse, ResponseError>) in
                            switch result {
                            case .failure(let responseError):
                                completion(.failure(.networkingError(responseError)))
                            case .success:
                                completion(.success(()))
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
}
