// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation

// sourcery: mock
protocol FeatureFlagCache {
    func storeFeatureFlags(_ flags: SupportedFeatureFlags, for userID: UserID)
    func featureFlags(for userID: UserID) -> SupportedFeatureFlags
}

extension FeatureFlagCache {
    func isFeatureFlag(_ featureFlag: FeatureFlag<Bool>, enabledForUserWithID userID: UserID) -> Bool {
        featureFlags(for: userID)[featureFlag]
    }

    func valueOfFeatureFlag<T>(_ featureFlag: FeatureFlag<T>, for userID: UserID) -> T {
        featureFlags(for: userID)[featureFlag]
    }
}

extension UserCachedStatus: FeatureFlagCache {
    private var featureFlagsPerUserKey: String {
        "featureFlagsPerUser"
    }

    func storeFeatureFlags(_ flags: SupportedFeatureFlags, for userID: UserID) {
        // sometimes the flags dictionary contains NSNull that would crash UserDefaults
        let sanitizedFlags = flags.rawValues.filter { !($1 is NSNull) }

        var featureFlagsPerUser = loadFeatureFlagsPerUser()
        featureFlagsPerUser[userID.rawValue] = sanitizedFlags
        userDefaults.setValue(featureFlagsPerUser, forKey: featureFlagsPerUserKey)
    }

    func featureFlags(for userID: UserID) -> SupportedFeatureFlags {
        let featureFlagsForGivenUser = loadFeatureFlagsPerUser()[userID.rawValue]
        return SupportedFeatureFlags(rawValues: featureFlagsForGivenUser ?? [:])
    }

    private func loadFeatureFlagsPerUser() -> [String: [String: Any]] {
        userDefaults.dictionary(forKey: featureFlagsPerUserKey)?.compactMapValues { $0 as? [String: Any] } ?? [:]
    }
}
