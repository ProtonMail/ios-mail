//
//  AccountRecoveryDatasource.swift
//  Pods - Created on 6/7/23.
//
//  Copyright (c) 2023 Proton AG
//
//  This file is part of ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation

import ProtonCoreServices
import ProtonCoreAuthentication
import ProtonCoreDataModel

public protocol AccountRecoveryDatasourceProtocol {
    var apiService: APIService { get }

    func fetchAccountRecoveryInfo() async throws -> RecoveryInfo

    func accountRecoveryStatus() async -> AccountRecovery?
}

/// username, email and account recovery details
public typealias RecoveryInfo = (username: String?, email: String?, recovery: AccountRecovery?)

class AccountRecoveryDatasource: AccountRecoveryDatasourceProtocol {

    let apiService: APIService
    let authenticator: Authenticator

    init(apiService: APIService) {
        self.apiService = apiService
        self.authenticator = Authenticator(api: apiService)
    }

    func fetchAccountRecoveryInfo() async throws -> RecoveryInfo {
        try await withCheckedThrowingContinuation { continuation in
            authenticator.getUserInfo { result in
                switch result {
                case .success(let user):
                    let email = user.email
                    let username = user.name ?? user.email
                    let recovery = user.accountRecovery
                    continuation.resume(returning: RecoveryInfo(username, email, recovery))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func accountRecoveryStatus() async -> AccountRecovery? {
            return try? await fetchAccountRecoveryInfo().recovery
    }
}
