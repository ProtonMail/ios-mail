//
//  TwoFactorViewModel.swift
//  ProtonCore-Login - Created on 30.11.2020.
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
import ProtonCore_Log

final class TwoFactorViewModel {
    enum Mode {
        case twoFactorCode
        case recoveryCode
    }

    enum TwoFactorResult {
        case done(LoginData)
        case mailboxPasswordNeeded
        case createAddressNeeded(CreateAddressData)
    }

    // MARK: - Properties

    let finished = Publisher<TwoFactorResult>()
    let error = Publisher<LoginError>()
    let isLoading = Observable<Bool>(false)
    let mode = Observable<Mode>(.twoFactorCode)

    private let login: Login

    init(login: Login) {
        self.login = login
    }

    // MARK: - Actions

    func toggleMode() {
        mode.value = mode.value == .twoFactorCode ? .recoveryCode : .twoFactorCode
    }

    func authenticate(code: String) {
        isLoading.value = true

        login.provide2FACode(code) { [weak self] result in
            switch result {
            case let .failure(error):
                self?.error.publish(error)
                self?.isLoading.value = false
            case let .success(status):
                switch status {
                case let .finished(data):
                    self?.finished.publish(.done(data))
                case let .chooseInternalUsernameAndCreateInternalAddress(data):
                    self?.finished.publish(.createAddressNeeded(data))
                    self?.isLoading.value = false
                case .ask2FA:
                    PMLog.error("Asking for 2FA code password after successful 2FA code is an invalid state")
                    self?.error.publish(.invalidState)
                    self?.isLoading.value = false
                case .askSecondPassword:
                    self?.finished.publish(.mailboxPasswordNeeded)
                    self?.isLoading.value = false
                }
            }
        }
    }
}
