//
//  CreateAddressViewModel.swift
//  ProtonCore-Login - Created on 27.11.2020.
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

    var address: String {
        return "\(username)@\(login.currentlyChosenSignUpDomain)"
    }
    let recoveryEmail: String
    let isLoading = Observable<Bool>(false)
    let error = Publisher<(String, Int, Error)>()
    let finished = Publisher<LoginData>()

    private let login: Login
    private let username: String
    private let mailboxPassword: String
    private(set) var user: User
    private let updateUser: (User) -> Void

    init(username: String, login: Login, data: CreateAddressData, updateUser: @escaping (User) -> Void) {
        self.login = login
        self.username = username
        recoveryEmail = data.email
        mailboxPassword = data.mailboxPassword
        user = data.user
        self.updateUser = updateUser
    }

    // MARK: - Actions

    func finish() {
        isLoading.value = true
        setUsername()
    }

    // MARK: - Internal

    private func setUsername() {
        PMLog.debug("Setting username")
        let username = self.username
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
                case .generic:
                    self?.isLoading.value = false
                    self?.error.publish((error.userFacingMessageInLogin, error.codeInLogin, error))
                }
            }
        }
    }

    private func createAddress() {
        PMLog.debug("Creating address")

        login.createAddress { [weak self] result in
            switch result {
            case let .success(address):
                self?.createAccountKeys(address: address)
            case let .failure(error):
                switch error {
                case let .alreadyHaveInternalOrCustomDomainAddress(address):
                    PMLog.debug("Address already created, moving on")
                    self?.createAccountKeys(address: address)
                case let .cannotCreateInternalAddress(address):
                    PMLog.debug("Address cannot be created. Already existing address: \(String(describing: address))")
                    self?.isLoading.value = false
                    self?.error.publish((error.userFacingMessageInLogin, error.codeInLogin, error))
                case .generic:
                    self?.isLoading.value = false
                    self?.error.publish((error.userFacingMessageInLogin, error.codeInLogin, error))
                }
            }
        }
    }
    
    private func createAccountKeys(address: Address) {
        login.createAccountKeysIfNeeded(user: user, addresses: nil, mailboxPassword: mailboxPassword) { [weak self] result in
            switch result {
            case .failure(let error):
                PMLog.debug("User account doesn't have keys and we cannot create one")
                self?.isLoading.value = false
                self?.error.publish((error.userFacingMessageInLogin, error.codeInLogin, error))
            case .success(let user):
                // we update the user so that we know about the newly created keys
                self?.user = user
                self?.updateUser(user)
                self?.generateKeys(address: address)
            }
        }
    }

    private func generateKeys(address: Address) {
        PMLog.debug("Generating keys")

        login.createAddressKeys(user: user, address: address, mailboxPassword: mailboxPassword) { [weak self] result in
            switch result {
            case .success:
                self?.finishFlow()
            case let .failure(error):
                switch error {
                case .alreadySet:
                    PMLog.debug("Address keys already created, moving on")
                    self?.finishFlow()
                case .generic:
                    self?.isLoading.value = false
                    self?.error.publish((error.userFacingMessageInLogin, error.codeInLogin, error))
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
                self?.error.publish((error.userFacingMessageInLogin, error.codeInLogin, error))
                self?.isLoading.value = false
            }
        }
    }
}
