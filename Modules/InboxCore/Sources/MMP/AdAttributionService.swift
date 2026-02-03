// Copyright (c) 2025 Proton Technologies AG
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

class AdAttributionService {
    private let conversionTracker: ConversionTracker

    init(conversionTracker: ConversionTracker = makeConversionTracker()) {
        self.conversionTracker = conversionTracker
    }

    func handle(event: ConversionEvent) async {
        let conversionValue: ConversionValue =
            switch event {
            case .appInstall:
                [.appInstalled]
            case .loggedIn:
                [.appInstalled, .signedIn]
            case .firstActionPerformed:
                [.appInstalled, .signedIn, .firstActionPerformed]
            case .subscribed(let plan, let duration):
                subscribedConversionValue(for: plan, duration: duration)
            }

        await updateConversionValue(with: conversionValue)
    }

    // MARK: - Private

    private func updateConversionValue(with conversionValue: ConversionValue) async {
        do {
            try await conversionTracker.updateConversionValue(
                Int(conversionValue.rawValue),
                coarseConversionValue: coarseValue(for: conversionValue),
                lockPostback: shouldLockPostback(for: conversionValue)
            )
        } catch {
            // FIXME: - Add logging
        }
    }

    private func subscribedConversionValue(
        for plan: SubscriptionPlan,
        duration: SubscriptionDuration
    ) -> ConversionValue {
        var flags: ConversionValue = [.appInstalled, .signedIn, .firstActionPerformed, .paidSubscription]

        switch duration {
        case .month:
            flags.insert(.monthlySubscription)  // Explicit for clarity (rawValue = 0)
        case .year:
            flags.insert(.yearlySubscription)
        }

        switch plan {
        case .plus:
            flags.insert(.planPlus)  // Explicit for clarity (rawValue = 0)
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
