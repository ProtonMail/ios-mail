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
import ProtonCore_CoreTranslation

enum DisplayProgressStep {
    case create
    case login
    case payment
    case custom(String, String)
}

enum DisplayProgressState {
    case initial
    case waiting
    case done
}

class DisplayProgress {
    let step: DisplayProgressStep
    var state: DisplayProgressState
    
    init (step: DisplayProgressStep, state: DisplayProgressState) {
        self.step = step
        self.state = state
    }
}

class CompleteViewModel {
    var signupService: Signup
    var loginService: Login
    let deviceToken: String
    
    var displayProgress: [DisplayProgress] = []

    init(signupService: Signup, loginService: Login, deviceToken: String, initDisplaySteps: [DisplayProgressStep]) {
        self.signupService = signupService
        self.loginService = loginService
        self.deviceToken = deviceToken
        initProgress(initDisplaySteps: initDisplaySteps)
    }
    
    var progressCompletion: (() -> Void)?

    func createNewUser(userName: String, password: String, email: String?, phoneNumber: String?, completion: @escaping (Result<(LoginData), Error>) -> Void) throws {
        self.updateProgress(progress: DisplayProgress(step: .create, state: .waiting))
        loginService.checkAvailability(username: userName) { result in
            switch result {
            case .success:
                try? self.signupService.createNewUser(userName: userName, password: password, deviceToken: self.deviceToken, email: email, phoneNumber: phoneNumber) { result in
                    switch result {
                    case .success:
                        self.updateProgress(progress: DisplayProgress(step: .create, state: .done))
                        self.updateProgress(progress: DisplayProgress(step: .login, state: .waiting))
                        self.login(name: userName, password: password) { result in
                            self.updateProgress(progress: DisplayProgress(step: .login, state: .done))
                            completion(result)
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            case .failure(let error):
                switch error {
                case .notAvailable:
                    self.updateProgress(progress: DisplayProgress(step: .create, state: .done))
                    self.updateProgress(progress: DisplayProgress(step: .login, state: .waiting))
                    self.login(name: userName, password: password) { result in
                        self.updateProgress(progress: DisplayProgress(step: .login, state: .done))
                        completion(result)
                    }
                case .generic:
                    completion(.failure(error))
                }
            }
        }
    }

    func createNewExternalUser(email: String, password: String, verifyToken: String, completion: @escaping (Result<(LoginData), Error>) -> Void) throws {
        DispatchQueue.main.async {
            self.updateProgress(progress: DisplayProgress(step: .create, state: .waiting))
            try? self.signupService.createNewExternalUser(email: email, password: password, deviceToken: self.deviceToken, verifyToken: verifyToken) { result in
                switch result {
                case .success:
                    self.updateProgress(progress: DisplayProgress(step: .create, state: .done))
                    self.updateProgress(progress: DisplayProgress(step: .login, state: .waiting))
                    self.login(name: email, password: password) { result in
                        self.updateProgress(progress: DisplayProgress(step: .login, state: .done))
                        completion(result)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    func processStepWaiting(step: DisplayProgressStep) {
        updateProgress(progress: DisplayProgress(step: step, state: .waiting))
        progressCompletion?()
    }

    func processStepDone(step: DisplayProgressStep) {
        updateProgress(progress: DisplayProgress(step: step, state: .done))
        progressCompletion?()
    }

    // MARK: Private methods

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
    
    private func initProgress(initDisplaySteps: [DisplayProgressStep]) {
        initDisplaySteps.forEach {
            displayProgress.append(DisplayProgress(step: $0, state: .initial))
        }
        progressCompletion?()
    }
    
    private func updateProgress(progress: DisplayProgress) {
        displayProgress.forEach {
            if progress.step == $0.step {
                $0.state = progress.state
            }
        }
        progressCompletion?()
    }
}

extension DisplayProgressStep {
    func localizedString(state: DisplayProgressState?) -> String {
        switch self {
        case .create:
            switch state {
            case .initial, .waiting, .none: return CoreString._su_complete_step_creation
            case .done: return CoreString._su_complete_step_created
            }
        case .login:
            switch state {
            case .initial, .waiting, .none: return CoreString._su_complete_step_keys_generation
            case .done: return CoreString._su_complete_step_keys_generated
            }
        case .payment:
            switch state {
            case .initial, .waiting, .none: return CoreString._su_complete_step_payment_validation
            case .done: return CoreString._su_complete_step_payment_validated
            }
        case .custom(let waitingString, let doneString):
            switch state {
            case .initial, .waiting, .none: return waitingString
            case .done: return doneString
            }
        }
    }

    static func == (lhs: DisplayProgressStep?, rhs: DisplayProgressStep) -> Bool {
        guard let lhs = lhs else { return false }
        switch (lhs, rhs) {
        case (.create, .create), (.login, .login), (.payment, .payment):
            return true
        case (let .custom(lhs1, lhs2), let .custom(rhs1, rhs2)):
            return lhs1 == rhs1 && lhs2 == rhs2
        default:
            return false
        }
    }
}

extension DisplayProgressState {
    var image: UIImage? {
        switch self {
        case .initial: return nil
        case .waiting: return UIImage(named: "ic-arrows", in: LoginAndSignup.bundle, compatibleWith: nil)
        case .done: return UIImage(named: "ic-check", in: LoginAndSignup.bundle, compatibleWith: nil)
        }
    }
}
