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
import ProtonCore_Login

enum DisplayProgressStep: Hashable {
    case createAccount
    case generatingAddress
    case generatingKeys
    case payment
    case custom(String)
}

enum DisplayProgressState {
    case initial
    case waiting
    case done
}

class DisplayProgress {
    let step: DisplayProgressStep
    var state: DisplayProgressState
    
    init(step: DisplayProgressStep, state: DisplayProgressState) {
        self.step = step
        self.state = state
    }
}

class CompleteViewModel {
    var signupService: Signup
    var loginService: Login
    
    var displayProgress: [DisplayProgress] = []
    var displayProgressWidth: [CGFloat?] = []
    
    init(signupService: Signup, loginService: Login, initDisplaySteps: [DisplayProgressStep]) {
        self.signupService = signupService
        self.loginService = loginService
        initProgressSteps(initDisplaySteps: initDisplaySteps)
        
        self.loginService.startGeneratingAddress = {
            self.progressStepWait(progressStep: .generatingAddress)
        }
        self.loginService.startGeneratingKeys = {
            self.progressStepWait(progressStep: .generatingKeys)
        }
    }
    
    var progressCompletion: (() -> Void)?

    func createNewUser(userName: String, password: String, email: String?, phoneNumber: String?, completion: @escaping (Result<(LoginData), Error>) -> Void) throws {
        self.progressStepWait(progressStep: .createAccount)
        loginService.checkAvailability(username: userName) { result in
            switch result {
            case .success:
                self.signupService.createNewUser(userName: userName, password: password, email: email, phoneNumber: phoneNumber) { result in
                    switch result {
                    case .success:
                        self.login(name: userName, password: password) { result in
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
                    self.login(name: userName, password: password) { result in
                        completion(result)
                    }
                case .generic:
                    completion(.failure(error))
                }
            }
        }
    }

    func createNewExternalUser(email: String, password: String, verifyToken: String, tokenType: String, completion: @escaping (Result<(LoginData), Error>) -> Void) throws {
        DispatchQueue.main.async {
            self.progressStepWait(progressStep: .createAccount)
            self.signupService.createNewExternalUser(email: email, password: password, verifyToken: verifyToken, tokenType: tokenType) { result in
                switch result {
                case .success:
                    self.login(name: email, password: password) { result in
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
    
    func progressStepWait(progressStep: DisplayProgressStep) {
        // mark found item as waiting
        // mark all items before as done
        for step in displayProgress {
            if progressStep == step.step {
                step.state = .waiting
                break
            } else {
                step.state = .done
            }
        }
        progressCompletion?()
    }
    
    func progressStepAllDone() {
        // mark all items as done
        displayProgress.forEach {
            if $0.state != .done {
                $0.state = .done
            }
        }
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
    
    private func initProgressSteps(initDisplaySteps: [DisplayProgressStep]) {
        // initial array
        initDisplaySteps.uniqued().forEach {
            displayProgress.append(DisplayProgress(step: $0, state: .initial))
        }
        progressCompletion?()
    }
}

extension CompleteViewModel {
    func initProgressWidth() {
        displayProgress.forEach { _ in
            displayProgressWidth.append(nil)
        }
    }
    
    func updateProgressWidth(index: Int, width: CGFloat) {
        displayProgressWidth[index] = width
    }
    
    var getMaxProgressWidth: CGFloat? {
        let widthArray = displayProgressWidth.compactMap { $0 }
        if widthArray.count == displayProgressWidth.count {
            return widthArray.max()
        }
        return nil
    }
}

extension DisplayProgressStep {
    var localizedString: String {
        switch self {
        case .createAccount:
            return CoreString._su_complete_step_creation
        case .generatingAddress:
            return CoreString._su_complete_step_address_generation
        case .generatingKeys:
            return CoreString._su_complete_step_keys_generation
        case .payment:
            return CoreString._su_complete_step_payment_verification
        case .custom(let text):
            return text
        }
    }

    static func == (lhs: DisplayProgressStep?, rhs: DisplayProgressStep) -> Bool {
        guard let lhs = lhs else { return false }
        switch (lhs, rhs) {
        case (.createAccount, .createAccount), (.generatingAddress, .generatingAddress), (.generatingKeys, .generatingKeys), (.payment, .payment):
            return true
        case (let .custom(lStr), let .custom(rStr)):
            return lStr == rStr
        default:
            return false
        }
    }
}

extension DisplayProgressState {
    var image: UIImage? {
        switch self {
        case .initial, .waiting: return nil
        case .done: return UIImage(named: "ic-check", in: LoginAndSignup.bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        }
    }
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
