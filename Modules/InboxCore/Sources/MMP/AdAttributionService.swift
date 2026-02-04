// Copyright (c) 2026 Proton Technologies AG
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

class AdAttributionService {
    private let conversionTracker: ConversionTracker
    private let userDefaults: UserDefaults

    init(
        conversionTracker: ConversionTracker = makeConversionTracker(),
        userDefaults: UserDefaults = .appGroup
    ) {
        self.conversionTracker = conversionTracker
        self.userDefaults = userDefaults
    }

    func handle(event: ConversionEvent) async {
        let currentConversionValue = loadConversionValue()

        let newFlags: ConversionValue =
            switch event {
            case .loggedIn:
                [.signedIn]
            case .firstActionPerformed:
                [.firstActionPerformed]
            case .subscribed(let plan, let duration):
                subscribedFlags(for: plan, duration: duration)
            }

        let mergedValue = currentConversionValue.union(newFlags)

        await updateConversionValue(with: mergedValue)
    }

    // MARK: - Private

    private func updateConversionValue(with conversionValue: ConversionValue) async {
        save(conversionValue: conversionValue)

        do {
            try await conversionTracker.updateConversionValue(
                Int(conversionValue.rawValue),
                coarseConversionValue: coarseValue(for: conversionValue),
                lockPostback: shouldLockPostback(for: conversionValue)
            )
        } catch {
            AppLogger.log(error: error)
        }
    }

    private func loadConversionValue() -> ConversionValue {
        let rawValue = userDefaults[.conversionValue]
        return ConversionValue(rawValue: rawValue)
    }

    private func save(conversionValue: ConversionValue) {
        userDefaults[.conversionValue] = conversionValue.rawValue
    }

    private func subscribedFlags(
        for plan: SubscriptionPlan,
        duration: SubscriptionDuration
    ) -> ConversionValue {
        var flags: ConversionValue = [.paidSubscription]

        switch duration {
        case .month:
            flags.insert(.monthlySubscription)
        case .year:
            flags.insert(.yearlySubscription)
        }

        switch plan {
        case .plus:
            flags.insert(.planPlus)
        case .unlimited:
            flags.insert(.planUnlimited)
        }

        return flags
    }

    private func coarseValue(for conversionValue: ConversionValue) -> CoarseValue {
        if conversionValue.contains(.paidSubscription) {
            return .high
        }

        if conversionValue.contains(.firstActionPerformed) {
            return .medium
        }

        return .low
    }

    private func shouldLockPostback(for conversionValue: ConversionValue) -> Bool {
        conversionValue.contains(.paidSubscription)
    }
}
