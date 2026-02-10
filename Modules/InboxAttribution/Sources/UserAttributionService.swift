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
import InboxCore
import proton_app_uniffi

public final class UserAttributionService: ObservableObject, Sendable {
    private let userSettingsProvider: @Sendable () async throws -> UserSettings
    private let adAttributionService: AdAttributionService

    public init(
        userSettingsProvider: @Sendable @escaping () async throws -> UserSettings,
        userDefaults: UserDefaults,
        conversionTracker: ConversionTracker = ConversionTrackerFactory.make()
    ) {
        self.userSettingsProvider = userSettingsProvider
        self.adAttributionService = .init(conversionTracker: conversionTracker, userDefaults: userDefaults)
    }

    public func handle(event: ConversionEvent) async {
        guard await isTelemetryEnabled() else { return }
        await adAttributionService.handle(event: event)
    }

    // MARK: - Private

    private func isTelemetryEnabled() async -> Bool {
        do {
            return try await userSettingsProvider().telemetry
        } catch {
            AppLogger.log(error: error)
            return false
        }
    }
}
