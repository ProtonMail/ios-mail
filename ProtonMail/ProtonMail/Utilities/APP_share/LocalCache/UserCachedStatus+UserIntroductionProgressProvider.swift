// Copyright (c) 2022 Proton Technologies AG
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

private extension UserCachedStatus.Key {
    static let spotlightsShownPerUser = "spotlightsShownPerUser"
}

extension UserCachedStatus: UserIntroductionProgressProvider {
    func shouldShowSpotlight(for feature: SpotlightableFeatureKey, toUserWith userID: UserID) -> Bool {
        guard let featuresSeenSoFarByGivenUser = spotlightsShownPerUser[userID] else {
            return true
        }

        return !featuresSeenSoFarByGivenUser.contains(feature.rawValue)
    }

    func markSpotlight(for feature: SpotlightableFeatureKey, asSeen seen: Bool, byUserWith userID: UserID) {
        var featuresSeenSoFarByAllUsers = spotlightsShownPerUser
        var featuresSeenSoFarByGivenUser = featuresSeenSoFarByAllUsers[userID] ?? []

        if seen {
            featuresSeenSoFarByGivenUser.insert(feature.rawValue)
        } else {
            featuresSeenSoFarByGivenUser.remove(feature.rawValue)
        }

        featuresSeenSoFarByAllUsers[userID] = featuresSeenSoFarByGivenUser
        spotlightsShownPerUser = featuresSeenSoFarByAllUsers
    }

    private var spotlightsShownPerUser: [UserID: Set<String>] {
        get {
            getShared().decodableValue(forKey: Key.spotlightsShownPerUser) ?? [:]
        }
        set {
            getShared().setEncodableValue(newValue, forKey: Key.spotlightsShownPerUser)
        }
    }
}
