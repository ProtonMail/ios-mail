//
//  CreateAddressViewModel.swift
//  ProtonCore-Login - Created on 26.11.2020.
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
import ProtonCore_DataModel
import ProtonCore_Log
import ProtonCore_Login

final class CreateAddressViewModel {

    // MARK: - Properties

    enum PossibleErrors {
        case availabilityError(AvailabilityError)
        case setUsernameError(SetUsernameError)
        case createAddressError(CreateAddressError)
        case loginError(LoginError)
        case createAddressKeysError(CreateAddressKeysError)
        
        var originalError: Error {
            switch self {
            case .availabilityError(let availabilityError): return availabilityError
            case .setUsernameError(let setUsernameError): return setUsernameError
            case .createAddressError(let createAddressError): return createAddressError
            case .loginError(let loginError): return loginError
            case .createAddressKeysError(let createAddressKeysError): return createAddressKeysError
            }
        }
    }
    
    let isLoading = Observable<Bool>(false)
    let error = Publisher<(String, Int, PossibleErrors)>()
    let finished = Publisher<LoginData>()
    var externalEmail: String { data.email }
    let defaultUsername: String?
    var signUpDomain: String { login.currentlyChosenSignUpDomain }
    
    var currentlyChosenSignUpDomain: String {
        get { login.currentlyChosenSignUpDomain }
        set { login.currentlyChosenSignUpDomain = newValue }
    }
    var allSignUpDomains: [String] { login.allSignUpDomains }
    
    private let data: CreateAddressData
    private var login: Login
    private let mailboxPassword: String
    private(set) var user: User
    
    init(data: CreateAddressData, login: Login, defaultUsername: String?) {
        self.data = data
        self.login = login
        self.mailboxPassword = data.mailboxPassword
        self.user = data.user
        self.defaultUsername = defaultUsername
    }

    // MARK: - Actions
    
    func validate(username: String) -> Result<(), UsernameValidationError> {
        !username.isEmpty ? .success : .failure(.emptyUsername)
    }
    
    func finish(username: String) {
        isLoading.value = true
        checkAvailability(username: username) { [weak self] in
            self?.setUsername(username: username)
        }
    }
    
    func logout() {
        login.logout(credential: data.credential) { _ in
        }
    }

    // MARK: - Private interface
    
    private func checkAvailability(username: String, success: @escaping () -> Void) {
        login.checkAvailabilityForInternalAccount(username: username) { [weak self] result in
            switch result {
            case .success:
                success()
            case let .failure(error):
                self?.isLoading.value = false
                self?.error.publish((error.userFacingMessageInLogin, error.codeInLogin, .availabilityError(error)))
            }
        }
    }

    // MARK: - Internal

    private func setUsername(username: String) {
        PMLog.debug("Setting username")
        // we do not have any info about addresses so we let the login service fetch it
        login.setUsername(username: username) { [weak self] result in
            switch result {
            case .success:
                self?.createAddress()
            case let .failure(error):
                switch error {
                case .alreadySet:
                    PMLog.debug("Username already set, moving on")
                    self?.createAddress()
                case .generic, .apiMightBeBlocked:
                    self?.isLoading.value = false
                    self?.error.publish((error.userFacingMessageInLogin, error.codeInLogin, .setUsernameError(error)))
                }
            }
        }
    }

    private func createAddress() {
        PMLog.debug("Creating address")

        login.createAddress { [weak self] result in
            switch result {
            case .success:
                self?.finishFlow()
            case let .failure(error):
                switch error {
                case .alreadyHaveInternalOrCustomDomainAddress:
                    PMLog.debug("Address already created, moving on")
                    self?.finishFlow()
                case let .cannotCreateInternalAddress(address):
                    PMLog.debug("Address cannot be created. Already existing address: \(String(describing: address))")
                    self?.isLoading.value = false
                    self?.error.publish((error.userFacingMessageInLogin, error.codeInLogin, .createAddressError(error)))
                case .generic, .apiMightBeBlocked:
                    self?.isLoading.value = false
                    self?.error.publish((error.userFacingMessageInLogin, error.codeInLogin, .createAddressError(error)))
                }
            }
        }
    }
    
    private func finishFlow() {
        PMLog.debug("Finishing the flow")

        login.finishLoginFlow(mailboxPassword: mailboxPassword) { [weak self] result in
            switch result {
            case let .success(status):
                switch status {
                case .ask2FA, .askSecondPassword, .chooseInternalUsernameAndCreateInternalAddress:
                    self?.isLoading.value = false
                case let .finished(data):
                    self?.finished.publish(data)
                }
            case let .failure(error):
                self?.error.publish((error.userFacingMessageInLogin, error.codeInLogin, .loginError(error)))
                self?.isLoading.value = false
            }
        }
    }
}
