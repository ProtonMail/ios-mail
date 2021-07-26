//
//  SignupService.swift
//  ProtonCore-Login - Created on 11/03/2021.
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

// swiftlint:disable function_parameter_count

import Foundation
import ProtonCore_APIClient
import ProtonCore_Authentication
import ProtonCore_Authentication_KeyGeneration
import ProtonCore_Challenge
import ProtonCore_Log
import ProtonCore_Services
import ProtonCore_Utilities

protocol Signup {

    func requestValidationToken(email: String, completion: @escaping (Result<Void, SignupError>) -> Void)
    func checkValidationToken(email: String, token: String, completion: @escaping (Result<Void, SignupError>) -> Void)
    func createNewUser(userName: String, password: String, deviceToken: String, email: String?, phoneNumber: String?, completion: @escaping (Result<(), SignupError>) -> Void) throws
    func createNewExternalUser(email: String, password: String, deviceToken: String, verifyToken: String, completion: @escaping (Result<(), SignupError>) -> Void) throws
}

class SignupService: Signup {

    private let apiService: APIService
    private let authenticator: Authenticator
    private let challenge: PMChallenge

    // MARK: Public interface

    init(api: APIService, challenge: PMChallenge) {
        self.apiService = api
        self.authenticator = Authenticator(api: apiService)
        self.challenge = challenge
    }

    func requestValidationToken(email: String, completion: @escaping (Result<Void, SignupError>) -> Void) {
        let route = UserAPI.Router.code(type: .email, receiver: email)
        apiService.exec(route: route) { (_, response) in
            DispatchQueue.main.async {
                if response.responseCode != APIErrorCode.responseOK {
                    if let error = response.error {
                        completion(.failure(SignupError.generic(message: error.localizedDescription)))
                    } else {
                        completion(.failure(SignupError.validationTokenRequest))
                    }
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    func checkValidationToken(email: String, token: String, completion: @escaping (Result<Void, SignupError>) -> Void) {
        let token = HumanVerificationToken(type: .email, token: token, input: email)
        let route = UserAPI.Router.check(token: token)
        apiService.exec(route: route) { (_, response) in
            DispatchQueue.main.async {
                if response.responseCode != APIErrorCode.responseOK {
                    if response.responseCode == 2500 {
                        completion(.failure(SignupError.emailAddressAlreadyUsed))
                    // TODO: are we checking the right error here?
                    } else if let error = response.error, error.responseCode == 12087 {
                        completion(.failure(SignupError.invalidVerificationCode(message: error.localizedDescription)))
                    } else {
                        if let error = response.error {
                            completion(.failure(SignupError.generic(message: error.localizedDescription)))
                        } else {
                            completion(.failure(SignupError.validationToken))
                        }
                    }
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    func createNewUser(userName: String, password: String, deviceToken: String, email: String? = nil, phoneNumber: String? = nil, completion: @escaping (Result<(), SignupError>) -> Void) throws {

        getRandomSRPModulus { result in
            switch result {
            case .success(let modulus):
                try? self.createUser(userName: userName, password: password, deviceToken: deviceToken, email: email, phoneNumber: phoneNumber, modulus: modulus, completion: completion)
            case .failure(let error):
                return completion(.failure(error))
            }
        }
    }

    func createNewExternalUser(email: String, password: String, deviceToken: String, verifyToken: String, completion: @escaping (Result<(), SignupError>) -> Void) throws {

        getRandomSRPModulus { result in
            switch result {
            case .success(let modulus):
                try? self.createExternalUser(email: email, password: password, deviceToken: deviceToken, modulus: modulus, verifyToken: verifyToken, completion: completion)
            case .failure(let error):
                return completion(.failure(error))
            }
        }
    }

    // MARK: Private interface

    private func getRandomSRPModulus(completion: @escaping (Result<AuthService.ModulusEndpointResponse, SignupError>) -> Void) {
        PMLog.debug("Getting random modulus")
        authenticator.getRandomSRPModulus { result in
            switch result {
            case .success(let res):
                completion(.success(res))
            case .failure(let error):
                completion(.failure(SignupError.generic(message: error.localizedDescription)))
            }
        }
    }

    private struct AuthParateters {
        let salt: Data
        let verifier: Data
        let challenge: [String: Any]
    }

    private func gererateAuthParameters(password: String, modulus: String) throws -> AuthParateters {
        guard let salt = try SrpRandomBits(80) else {
            throw SignupError.randomBits
        }
        guard let auth = try SrpAuthForVerifier(password, modulus, salt) else {
            throw SignupError.cantHashPassword
        }
        let verifier = try auth.generateVerifier(2048)
        let challenge = self.challenge.export().toDictionary()
        return AuthParateters(salt: salt, verifier: verifier, challenge: challenge)
    }

    private func createUser(userName: String, password: String, deviceToken: String, email: String?, phoneNumber: String?, modulus: AuthService.ModulusEndpointResponse, completion: @escaping (Result<(), SignupError>) -> Void) throws {

        let authParameters = try gererateAuthParameters(password: password, modulus: modulus.modulus)

        let userParameters = UserParameters(userName: userName, email: email, phone: phoneNumber, modulusID: modulus.modulusID, salt: authParameters.salt.encodeBase64(), verifer: authParameters.verifier.encodeBase64(), deviceToken: deviceToken, challenge: authParameters.challenge)

        PMLog.debug("Creating user with username: \(userParameters.userName)")
        authenticator.createUser(userParameters: userParameters) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(SignupError.generic(message: error.localizedDescription)))
            }
        }
    }

    private func createExternalUser(email: String, password: String, deviceToken: String, modulus: AuthService.ModulusEndpointResponse, verifyToken: String, completion: @escaping (Result<(), SignupError>) -> Void) throws {

        let authParameters = try gererateAuthParameters(password: password, modulus: modulus.modulus)

        let externalUserParameters = ExternalUserParameters(email: email, modulusID: modulus.modulusID, salt: authParameters.salt.encodeBase64(), verifer: authParameters.verifier.encodeBase64(), deviceToken: deviceToken, challenge: authParameters.challenge, verifyToken: verifyToken)

        PMLog.debug("Creating external user with email: \(externalUserParameters.email)")
        authenticator.createExternalUser(externalUserParameters: externalUserParameters) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(SignupError.generic(message: error.localizedDescription)))
            }
        }
    }
}
