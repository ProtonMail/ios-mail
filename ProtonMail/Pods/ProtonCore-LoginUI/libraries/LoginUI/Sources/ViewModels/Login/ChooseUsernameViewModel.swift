//
//  CreateAddressViewModel.swift
//  ProtonCore-Login - Created on 26.11.2020.
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
import ProtonCore_Login

final class ChooseUsernameViewModel {

    // MARK: - Properties

    let isLoading = Observable<Bool>(false)
    let error = Publisher<AvailabilityError>()
    let finished = Publisher<String>()
    var externalEmail: String {
        return data.email
    }
    let appName: String
    var signUpDomain: String {
        return login.signUpDomain
    }

    private let data: CreateAddressData
    private let login: Login

    init(data: CreateAddressData, login: Login, appName: String) {
        self.data = data
        self.login = login
        self.appName = appName
    }

    // MARK: - Actions

    func checkAvailability(username: String) {
        isLoading.value = true

        login.checkAvailability(username: username) { [weak self] result in
            self?.isLoading.value = false

            switch result {
            case .success:
                self?.finished.publish(username)
            case let .failure(error):
                self?.error.publish(error)
            }
        }
    }

    // MARK: - Validation

    func validate(username: String) -> Result<(), UsernameValidationError> {
        return !username.isEmpty ? Result.success : Result.failure(UsernameValidationError.emptyUsername)
    }
}
