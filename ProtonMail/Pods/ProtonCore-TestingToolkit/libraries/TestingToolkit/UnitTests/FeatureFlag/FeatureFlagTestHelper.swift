//
//  FeatureFlagTestHelper.swift
//  ProtonCore-TestingToolkit - Created on 06.10.2023.
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
//

import XCTest
import ProtonCoreUtilities
@testable import ProtonCoreFeatureFlags

/// Performs the included closure in a separate environment in which only the specified flags are enabled
extension XCTestCase {
    public func withFeatureFlags<T>(_ flags: [ProtonCoreFeatureFlags.FeatureFlag], perform block: () throws -> T) rethrows -> T {
        let currentLocalDataSource = FeatureFlagsRepository.shared.localDataSource
        let currentUserId = FeatureFlagsRepository.shared.userId

        defer {
            FeatureFlagsRepository.shared.updateLocalDataSource(currentLocalDataSource)
            FeatureFlagsRepository.shared.setUserId(currentUserId)
        }

        let testUserId = "testUserId"
        let userDefaults = UserDefaults(suiteName: "withFeatureFlags")!
        userDefaults.setEncodableValue([testUserId: FeatureFlags(flags: flags)], forKey: DefaultLocalFeatureFlagsDatasource.featureFlagsKey)

        FeatureFlagsRepository.shared.setUserId(testUserId)
        FeatureFlagsRepository.shared.updateLocalDataSource(
            Atomic<LocalFeatureFlagsDataSourceProtocol>(
                DefaultLocalFeatureFlagsDatasource(userDefaults: userDefaults)
            )
        )

        return try block()
    }

    @available(macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public func withFeatureFlags<T>(_ flags: [ProtonCoreFeatureFlags.FeatureFlag], perform block: () async throws -> T) async rethrows -> T {
        let currentLocalDataSource = FeatureFlagsRepository.shared.localDataSource
        let currentUserId = FeatureFlagsRepository.shared.userId

        let testUserId = "testUserId"
        let userDefaults = UserDefaults(suiteName: "withFeatureFlagsAsync")!
        userDefaults.setEncodableValue([testUserId: FeatureFlags(flags: flags)], forKey: DefaultLocalFeatureFlagsDatasource.featureFlagsKey)

        FeatureFlagsRepository.shared.setUserId(testUserId)
        FeatureFlagsRepository.shared.updateLocalDataSource(
            Atomic<LocalFeatureFlagsDataSourceProtocol>(
                DefaultLocalFeatureFlagsDatasource(userDefaults: userDefaults)
            )
        )
        let returnValue = try! await block()

        FeatureFlagsRepository.shared.updateLocalDataSource(currentLocalDataSource)
        FeatureFlagsRepository.shared.setUserId(currentUserId)

        return  returnValue
    }
}

public extension ProtonCoreFeatureFlags.FeatureFlag {
    static var accountRecovery: Self {
        .init(name: "SignedInAccountRecovery", enabled: true, variant: nil)
    }

    static var dynamicPlans: Self {
        .init(name: "DynamicPlan", enabled: true, variant: nil)
    }

    static var externalSSO: Self {
        .init(name: "ExternalSSO", enabled: true, variant: nil)
    }

    static var pushNotifications: Self {
        .init(name: "PushNotifications", enabled: true, variant: nil)
    }

    static var splitStorage: Self {
        .init(name: "SplitStorage", enabled: true, variant: nil)
    }

    static var telemetrySignUpMetrics: Self {
        .init(name: "IOSTelemetrySignUpMetrics", enabled: true, variant: nil)
    }
}
