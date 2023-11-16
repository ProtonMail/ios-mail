//
//  DefaultLocalFeatureFlagsDatasource.swift
//  ProtonCore-FeatureFlags - Created on 29.09.23.
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation
import ProtonCoreUtilities

public class DefaultLocalFeatureFlagsDatasource: LocalFeatureFlagsProtocol {
    private let serialAccessQueue = DispatchQueue(label: "ch.proton.featureflags_queue")

    static let featureFlagsKey = "protoncore.featureflag"

    private let userDefaults: UserDefaults
    private var flagsForSession: [String: FeatureFlags]?

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func getFeatureFlags(userId: String) -> FeatureFlags? {
        getLocalFeatureFlags(userId: userId)
    }

    public func getFeatureFlags(userId: String) async throws -> FeatureFlags? {
        getLocalFeatureFlags(userId: userId)
    }

    private func getLocalFeatureFlags(userId: String) -> FeatureFlags? {
        serialAccessQueue.sync {
            if let flagsForSession = flagsForSession {
                return flagsForSession[userId]
            }
            flagsForSession = userDefaults.decodableValue(forKey: DefaultLocalFeatureFlagsDatasource.featureFlagsKey) ?? [:]
            return flagsForSession?[userId]
        }
    }

    public func upsertFlags(_ flags: FeatureFlags, userId: String) {
        serialAccessQueue.sync {
            var flagsToUpdate: [String: FeatureFlags] = userDefaults.decodableValue(forKey: DefaultLocalFeatureFlagsDatasource.featureFlagsKey) ?? [:]
            flagsToUpdate[userId] = flags
            userDefaults.setEncodableValue(flagsToUpdate, forKey: DefaultLocalFeatureFlagsDatasource.featureFlagsKey)
        }
    }

    public func cleanAllFlags() {
        serialAccessQueue.sync {
            userDefaults.removeObject(forKey: DefaultLocalFeatureFlagsDatasource.featureFlagsKey)
        }
    }

    public func cleanFlags(for userId: String) {
        serialAccessQueue.sync {
            var flagsToClean: [String: FeatureFlags]? = userDefaults.decodableValue(forKey: DefaultLocalFeatureFlagsDatasource.featureFlagsKey)
            flagsToClean?[userId] = nil
            userDefaults.setEncodableValue(flagsToClean, forKey: DefaultLocalFeatureFlagsDatasource.featureFlagsKey)
        }
    }
}
