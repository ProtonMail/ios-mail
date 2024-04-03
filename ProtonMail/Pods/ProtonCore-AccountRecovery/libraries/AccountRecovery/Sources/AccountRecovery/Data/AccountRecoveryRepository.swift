//
//  AccountRecoveryRepository.swift
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
import ProtonCoreDataModel
import ProtonCoreAuthentication
import ProtonCoreNetworking

/// Any class conforming to `AccountRecoveryRepositoryProtocol` can act as the central hub from where **Account Recovery** views obtain ther information and post their actions.
public protocol AccountRecoveryRepositoryProtocol {
    /// the data source masking the Backend
    var accountRecoveryDatasource: AccountRecoveryDatasourceProtocol { get }
    /// an `AuthService` used for handling all authentication needs
    var authService: AuthService { get }

    /// Fetches asynchronously the current **Account Recovery** state
    /// - Returns: Tuple consisting of the current username, email and Account Recovery state.
    func fetchRecoveryState() async throws -> RecoveryInfo

    func accountRecoveryStatus() async -> AccountRecovery?
}

public extension AccountRecoveryRepositoryProtocol {

    func fetchRecoveryState() async throws -> RecoveryInfo {
        try await accountRecoveryDatasource.fetchAccountRecoveryInfo()
    }

}

/// An actual implementation of the ``AccountRecoveryRepositoryProtocol`
public struct AccountRecoveryRepository: AccountRecoveryRepositoryProtocol {
    public var authService: AuthService

    public let accountRecoveryDatasource: AccountRecoveryDatasourceProtocol

    public init(accountRecoveryDatasource: AccountRecoveryDatasourceProtocol,
                authService: AuthService) {
        self.accountRecoveryDatasource = accountRecoveryDatasource
        self.authService = authService
    }

    public init(apiService: APIService) {
        self.init(accountRecoveryDatasource: AccountRecoveryDatasource(apiService: apiService),
             authService: AuthService(api: apiService))
    }

    public func accountRecoveryStatus() async -> AccountRecovery? {
        return await accountRecoveryDatasource.accountRecoveryStatus()
    }
}
