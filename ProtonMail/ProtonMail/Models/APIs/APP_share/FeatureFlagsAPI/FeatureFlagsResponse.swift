// Copyright (c) 2021 Proton AG
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

import ProtonCoreNetworking

class FeatureFlagsResponse: Response {
    private(set) var result: [String: Any] = [:]

    override func ParseResponse(_ response: [String: Any]) -> Bool {
        guard let features = response["Features"] as? [[String: Any]] else {
            return false
        }

        for code in FeatureFlagKey.allCases {
            guard let feature = features.first(where: { $0["Code"] as? String == code.rawValue }) else {
                PMAssertionFailureIfBackendIsProduction("Feature flag \(code.rawValue) is missing!")
                continue
            }

            result[code.rawValue] = feature["Value"]
        }

        return true
    }
}

struct SupportedFeatureFlags {
    let rawValues: [String: Any]

    init(response: FeatureFlagsResponse) {
        self.init(rawValues: response.result)
    }

    init(rawValues: [String: Any]) {
        self.rawValues = rawValues
    }

    init() {
        self.init(rawValues: [:])
    }

    subscript<T>(_ featureFlag: FeatureFlag<T>) -> T {
        guard let requestedFlag = rawValues[featureFlag.code.rawValue] else {
            return featureFlag.defaultValue
        }

        guard let matchingValue = requestedFlag as? T else {
            PMAssertionFailure("Feature flag \(featureFlag.code.rawValue) has an unexpected value \(requestedFlag)")
            return featureFlag.defaultValue
        }

        return matchingValue
    }
}

class FeatureFlag<T>: FeatureFlags {
    let code: FeatureFlagKey
    let defaultValue: T

    init(code: FeatureFlagKey, defaultValue: T) {
        self.code = code
        self.defaultValue = defaultValue
    }
}

class FeatureFlags {
    static let appRating = FeatureFlag<Bool>(code: .appRating, defaultValue: false)
    static let attachmentsPreview = FeatureFlag<Bool>(code: .attachmentsPreview, defaultValue: false)
    static let mailboxPrefetchSize = FeatureFlag<Int>(code: .mailboxPrefetchSize, defaultValue: 0)
    static let mailboxSelectionLimitation = FeatureFlag<Int>(code: .mailboxSelectionLimitation, defaultValue: 100)
    static let protonUnreachableBanner = FeatureFlag<Bool>(code: .protonUnreachableBanner, defaultValue: false)
    static let referralPrompt = FeatureFlag<Bool>(code: .referralPrompt, defaultValue: false)
    static let refetchEventsByTime = FeatureFlag<Bool>(code: .refetchEventsByTime, defaultValue: true)
    static let refetchEventsHourThreshold = FeatureFlag<Int>(code: .refetchEventsHourThreshold, defaultValue: 24)
    static let scheduleSend = FeatureFlag<Bool>(code: .scheduleSend, defaultValue: false)
    static let senderImage = FeatureFlag<Bool>(code: .senderImage, defaultValue: false)
    static let autoDowngradeReminder = FeatureFlag<Any>(code: .autoDowngradeReminder, defaultValue: [:])
}
