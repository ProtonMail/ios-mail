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
import ProtonCore_DataModel
import ProtonCore_Log
import ProtonCore_Networking
import ProtonCore_Services
import ProtonCore_Utilities

public protocol Signup {

    func requestValidationToken(email: String, completion: @escaping (Result<Void, SignupError>) -> Void)
    func checkValidationToken(email: String, token: String, completion: @escaping (Result<Void, SignupError>) -> Void)
    
    func createNewUser(userName: String, password: String, email: String?, phoneNumber: String?, completion: @escaping (Result<(), SignupError>) -> Void)
    func createNewExternalUser(email: String, password: String, verifyToken: String, tokenType: String, completion: @escaping (Result<(), SignupError>) -> Void)
    
    @available(*, deprecated, message: "Use variant without device token createNewUser(userName:password:email:phoneNumber:completion:)")
    func createNewUser(userName: String, password: String, deviceToken: String, email: String?, phoneNumber: String?, completion: @escaping (Result<(), SignupError>) -> Void)
    @available(*, deprecated, message: "Use variant without device token createNewExternalUser(email:password:verifyToken:completion:)")
    func createNewExternalUser(email: String, password: String, deviceToken: String, verifyToken: String, tokenType: String, completion: @escaping (Result<(), SignupError>) -> Void)
}

public protocol ChallangeParametersProvider {
    func provideParameters() -> [[String: Any]]
}

public class SignupService: Signup {
    private let apiService: APIService
    private let authenticator: Authenticator
    private let challangeParametersProvider: ChallangeParametersProvider
    private let clientApp: ClientApp

    // MARK: Public interface

    public init(api: APIService, challangeParametersProvider: ChallangeParametersProvider, clientApp: ClientApp) {
        self.apiService = api
        self.authenticator = Authenticator(api: apiService)
        self.challangeParametersProvider = challangeParametersProvider
        self.clientApp = clientApp
    }

    public func requestValidationToken(email: String, completion: @escaping (Result<Void, SignupError>) -> Void) {
        let route = UserAPI.Router.code(type: .email, receiver: email)
        apiService.exec(route: route, responseObject: Response()) { (_, response) in
            DispatchQueue.main.async {
                if response.responseCode != APIErrorCode.responseOK {
                    if let error = response.error {
                        completion(.failure(SignupError.generic(
                            message: error.networkResponseMessageForTheUser,
                            code: error.bestShotAtReasonableErrorCode,
                            originalError: error
                        )))
                    } else {
                        completion(.failure(SignupError.validationTokenRequest))
                    }
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    public func checkValidationToken(email: String, token: String, completion: @escaping (Result<Void, SignupError>) -> Void) {
        let token = HumanVerificationToken(type: .email, token: token, input: email)
        let route = UserAPI.Router.check(token: token)
        apiService.exec(route: route, responseObject: Response()) { (_, response) in
            DispatchQueue.main.async {
                if response.responseCode != APIErrorCode.responseOK {
                    if response.responseCode == 2500 {
                        completion(.failure(SignupError.emailAddressAlreadyUsed))
                    // TODO: are we checking the right error here?
                    } else if let error = response.error, error.responseCode == 12087 {
                        completion(.failure(SignupError.invalidVerificationCode(message: error.localizedDescription)))
                    } else {
                        if let error = response.error {
                            completion(.failure(SignupError.generic(
                                message: error.networkResponseMessageForTheUser,
                                code: error.bestShotAtReasonableErrorCode,
                                originalError: error
                            )))
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

    public func createNewUser(userName: String, password: String, email: String? = nil, phoneNumber: String? = nil, completion: @escaping (Result<(), SignupError>) -> Void) {

        getRandomSRPModulus { result in
            switch result {
            case .success(let modulus):
                self.createUser(userName: userName, password: password, email: email, phoneNumber: phoneNumber, modulus: modulus, completion: completion)
            case .failure(let error):
                return completion(.failure(error))
            }
        }
    }

    public func createNewExternalUser(email: String, password: String, verifyToken: String, tokenType: String, completion: @escaping (Result<(), SignupError>) -> Void) {

        getRandomSRPModulus { result in
            switch result {
            case .success(let modulus):
                self.createExternalUser(email: email, password: password, modulus: modulus, verifyToken: verifyToken, tokenType: tokenType, completion: completion)
            case .failure(let error):
                return completion(.failure(error))
            }
        }
    }
    
    @available(*, deprecated, message: "Use variant without device token createNewUser(userName:password:email:phoneNumber:completion:)")
    public func createNewUser(userName: String, password: String, deviceToken: String, email: String?, phoneNumber: String?, completion: @escaping (Result<(), SignupError>) -> Void) {
        createNewUser(userName: userName, password: password, email: email, phoneNumber: phoneNumber, completion: completion)
    }
    
    @available(*, deprecated, message: "Use variant without device token createNewExternalUser(email:password:verifyToken:tokenType:completion:)")
    public func createNewExternalUser(email: String, password: String, deviceToken: String, verifyToken: String, tokenType: String, completion: @escaping (Result<(), SignupError>) -> Void) {
        createNewExternalUser(email: email, password: password, verifyToken: verifyToken, tokenType: tokenType, completion: completion)
    }

    // MARK: Private interface

    private func getRandomSRPModulus(completion: @escaping (Result<AuthService.ModulusEndpointResponse, SignupError>) -> Void) {
        PMLog.debug("Getting random modulus")
        authenticator.getRandomSRPModulus { result in
            switch result {
            case .success(let res):
                completion(.success(res))
            case .failure(let error):
                completion(.failure(SignupError.generic(
                    message: error.userFacingMessageInNetworking,
                    code: error.codeInNetworking,
                    originalError: error
                )))
            }
        }
    }

    private struct AuthParameters {
        let salt: Data
        let verifier: Data
        let challenge: [[String: Any]]
        let productPrefix: String
    }

    private func gererateAuthParameters(password: String, modulus: String) throws -> AuthParameters {
        guard let salt = try SrpRandomBits(80) else {
            throw SignupError.randomBits
        }
        guard let auth = try SrpAuthForVerifier(password, modulus, salt) else {
            throw SignupError.cantHashPassword
        }
        let verifier = try auth.generateVerifier(2048)
        let challenge = challangeParametersProvider.provideParameters()
        return AuthParameters(salt: salt, verifier: verifier, challenge: challenge, productPrefix: clientApp.name)
    }

    private func createUser(userName: String, password: String, email: String?, phoneNumber: String?, modulus: AuthService.ModulusEndpointResponse, completion: @escaping (Result<(), SignupError>) -> Void) {
        do {
            let authParameters = try gererateAuthParameters(password: password, modulus: modulus.modulus)
            let userParameters = UserParameters(userName: userName, email: email, phone: phoneNumber, modulusID: modulus.modulusID, salt: authParameters.salt.encodeBase64(), verifer: authParameters.verifier.encodeBase64(), challenge: authParameters.challenge, productPrefix: authParameters.productPrefix)

            PMLog.debug("Creating user with username: \(userParameters.userName)")
            authenticator.createUser(userParameters: userParameters) { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(SignupError.generic(
                        message: error.userFacingMessageInNetworking,
                        code: error.codeInNetworking,
                        originalError: error
                    )))
                }
            }
        } catch {
            if let signupError = error as? SignupError {
                completion(.failure(signupError))
            } else {
                completion(.failure(.generateVerifier(underlyingErrorDescription: error.messageForTheUser)))
            }
        }
    }

    private func createExternalUser(email: String, password: String, modulus: AuthService.ModulusEndpointResponse, verifyToken: String, tokenType: String, completion: @escaping (Result<(), SignupError>) -> Void) {

        do {
            let authParameters = try gererateAuthParameters(password: password, modulus: modulus.modulus)

            let externalUserParameters = ExternalUserParameters(email: email, modulusID: modulus.modulusID, salt: authParameters.salt.encodeBase64(), verifer: authParameters.verifier.encodeBase64(), challenge: authParameters.challenge, verifyToken: verifyToken, tokenType: tokenType, productPrefix: authParameters.productPrefix)

            PMLog.debug("Creating external user with email: \(externalUserParameters.email)")
            authenticator.createExternalUser(externalUserParameters: externalUserParameters) { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(SignupError.generic(
                        message: error.userFacingMessageInNetworking,
                        code: error.codeInNetworking,
                        originalError: error
                    )))
                }
            }
        } catch {
            if let signupError = error as? SignupError {
                completion(.failure(signupError))
            } else {
                completion(.failure(.generateVerifier(underlyingErrorDescription: error.messageForTheUser)))
            }
        }
    }
}
