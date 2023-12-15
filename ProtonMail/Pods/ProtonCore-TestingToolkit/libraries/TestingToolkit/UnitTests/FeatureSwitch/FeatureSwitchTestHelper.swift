//
//  FeatureSwitchTestHelper.swift
//  ProtonCore-TestingToolkit - Created on 28.11.2021.
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
import ProtonCoreFeatureSwitch

/// Performs the included closure in a separate environment in which only the specified switches are enabled
extension XCTestCase {
    public func withFeatureSwitches<T>(_ switches: [Feature], perform block: () throws -> T) rethrows -> T {
        let currentValues = FeatureFactory.shared.getCurrentFeatures()

        defer { FeatureFactory.shared.setCurrentFeatures(features: currentValues) }

        FeatureFactory.shared.clear()
        FeatureFactory.shared.setCurrentFeatures(features: switches)
        return try block()
    }

    @available(macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public func withFeatureSwitches<T>(_ switches: [Feature], perform block: () async throws -> T) async rethrows -> T {
        let currentValues = FeatureFactory.shared.getCurrentFeatures()

        defer { FeatureFactory.shared.setCurrentFeatures(features: currentValues) }

        FeatureFactory.shared.clear()
        FeatureFactory.shared.setCurrentFeatures(features: switches)
        return try await block()
    }
}
