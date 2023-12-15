//
//  FeatureFlagsRepositoryMock.swift
//  ProtonCore-TestingToolkit - Created on 06.12.2023.
//
//  Copyright (c) 2023 Proton Technologies AG
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

#if canImport(ProtonCoreTestingToolkitUnitTestsCore)
import ProtonCoreTestingToolkitUnitTestsCore
#endif
import ProtonCoreFeatureFlags
import ProtonCoreServices
import ProtonCoreUtilities

public final class FeatureFlagsRepositoryMock: FeatureFlagsRepositoryProtocol {

    public init() {}

    public var setUserIdWasCalled = false
    public var userId: String = ""
    public var setApiServiceWasCalled = false
    public var fetchFlagsWasCalled = false

    public func updateLocalDataSource(_ localDatasource: ProtonCoreUtilities.Atomic<ProtonCoreFeatureFlags.LocalFeatureFlagsProtocol>) {

    }

    public func setUserId(_ userId: String) {
        self.setUserIdWasCalled = true
        self.userId = userId
    }

    public func setApiService(_ apiService: ProtonCoreServices.APIService) {
        self.setApiServiceWasCalled = true
    }

    public func fetchFlags(for userId: String?, using apiService: ProtonCoreServices.APIService?) async throws {
        self.fetchFlagsWasCalled = true
    }

    public func resetFlags() {

    }

    public func resetFlags(for userId: String) {

    }

    public func clearUserId(_ userId: String) {

    }
}

