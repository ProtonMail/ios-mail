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

import ProtonCoreFeatureFlags

// sourcery: mock
protocol FeatureFlagProvider {
    func isEnabled(_ featureFlag: MailFeatureFlag, reloadValue: Bool) -> Bool
}

struct FeatureFlagProviderImpl: FeatureFlagProvider {
    private let featureFlagsRepository: FeatureFlagsRepository
    private let userID: UserID

    init(featureFlagsRepository: FeatureFlagsRepository, userID: UserID) {
        self.featureFlagsRepository = featureFlagsRepository
        self.userID = userID
    }

    func isEnabled(_ featureFlag: MailFeatureFlag, reloadValue: Bool) -> Bool {
        if let override = localOverride(for: featureFlag) {
            return override
        }

        return featureFlagsRepository.isEnabled(featureFlag, for: userID.rawValue, reloadValue: reloadValue)
    }

    private func localOverride(for featureFlag: MailFeatureFlag) -> Bool? {
        switch featureFlag {
        case .autoImportContacts:
            return nil
        case .rsvpWidget where Application.isDebugOrEnterprise:
            return true
        case .nextMessageAfterMove:
            return Application.isDebugOrEnterprise
        case .snooze:
            return ProcessInfo.isRunningUnitTests
        default:
            return nil
        }
    }
}
