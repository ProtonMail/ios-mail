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

public class DefaultLocalFeatureFlagsDatasource: LocalFeatureFlagsDataSourceProtocol {
    private let serialAccessQueue = DispatchQueue(label: "ch.proton.featureflags_queue")

    static let featureFlagsKey = "protoncore.featureflag"
    static let userIdKey = "protoncore.featureflag.userId"

    private let userDefaults: UserDefaults
    private var flagsForSession: [String: FeatureFlags]?
    private var userIdForSession: String?

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Get flags

    public func getFeatureFlags(userId: String, reloadFromLocalDataSource: Bool) -> FeatureFlags? {
        serialAccessQueue.sync {
            if reloadFromLocalDataSource {
                let dynamicFlags: [String: FeatureFlags]? = userDefaults.decodableValue(forKey: Self.featureFlagsKey)
                return dynamicFlags?[userId]
            } else if let flagsForSession, let userIdForSession {
                return flagsForSession[userIdForSession]
            }

            userIdForSession = userId
            flagsForSession = userDefaults.decodableValue(forKey: Self.featureFlagsKey) ?? [:]
            return flagsForSession?[userId]
        }
    }

    public func upsertFlags(_ flags: FeatureFlags, userId: String) {
        serialAccessQueue.sync {
            var flagsToUpdate: [String: FeatureFlags] =
                userDefaults.decodableValue(forKey: Self.featureFlagsKey) ?? [:]
            flagsToUpdate[userId] = flags
            userDefaults.setEncodableValue(flagsToUpdate, forKey: Self.featureFlagsKey)
        }
    }

    public func cleanAllFlags() {
        serialAccessQueue.sync {
            userDefaults.removeObject(forKey: Self.featureFlagsKey)
        }
    }

    public func cleanFlags(for userId: String) {
        serialAccessQueue.sync {
            var flagsToClean: [String: FeatureFlags]? =
                userDefaults.decodableValue(forKey: Self.featureFlagsKey)
            flagsToClean?[userId] = nil
            userDefaults.setEncodableValue(flagsToClean, forKey: Self.featureFlagsKey)
        }
    }

    // MARK: - User ID

    public var userIdForActiveSession: String? {
        serialAccessQueue.sync {
            userDefaults.object(forKey: Self.userIdKey) as? String
        }
    }

    public func setUserIdForActiveSession(_ userId: String) {
        serialAccessQueue.sync {
            userDefaults.set(userId, forKey: Self.userIdKey)
        }
    }

    public func clearUserId() {
        serialAccessQueue.sync {
            userDefaults.removeObject(forKey: Self.userIdKey)
        }
    }
}
