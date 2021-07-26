//
//  CompleteViewModel.swift
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

import Foundation

class CompleteViewModel {
    var signupService: Signup
    var loginService: Login
    let deviceToken: String

    init(signupService: Signup, loginService: Login, deviceToken: String) {
        self.signupService = signupService
        self.loginService = loginService
        self.deviceToken = deviceToken
    }

    func createNewUser(userName: String, password: String, email: String?, phoneNumber: String?, completion: @escaping (Result<(LoginData), Error>) -> Void) throws {
            loginService.checkAvailability(username: userName) { result in
                switch result {
                case .success:
                    try? self.signupService.createNewUser(userName: userName, password: password, deviceToken: self.deviceToken, email: email, phoneNumber: phoneNumber) { result in
                        switch result {
                        case .success:
                            self.login(name: userName, password: password, completion: completion)
                        case .failure(let error):
                            DispatchQueue.main.async {
                                completion(.failure(error))
                            }
                        }
                    }
                case .failure(let error):
                    switch error {
                    case .notAvailable:
                        self.login(name: userName, password: password, completion: completion)
                    case .generic:
                        completion(.failure(error))
                    }
                }
            }
    }

    func createNewExternalUser(email: String, password: String, verifyToken: String, completion: @escaping (Result<(LoginData), Error>) -> Void) throws {
        DispatchQueue.main.async {
            try? self.signupService.createNewExternalUser(email: email, password: password, deviceToken: self.deviceToken, verifyToken: verifyToken) { result in
                switch result {
                case .success:
                    self.login(name: email, password: password, completion: completion)
                case .failure(let error):
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    private func login(name: String, password: String, completion: @escaping (Result<(LoginData), Error>) -> Void) {
        loginService.login(username: name, password: password) { result in
            switch result {
            case .success(let loginStatus):
                switch loginStatus {
                case .finished(let loginData):
                    completion(.success(loginData))
                case .ask2FA, .askSecondPassword, .chooseInternalUsernameAndCreateInternalAddress:
                    completion(.failure(LoginError.invalidState))
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
