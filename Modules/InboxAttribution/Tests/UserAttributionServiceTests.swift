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
import Testing
import proton_app_uniffi
import InboxTesting

@testable import InboxAttribution

class UserAttributionServiceTests {
    var conversionTrackerSpy: ConversionTrackerSpy!

    func makeSut(telemetryEnabled: Bool) -> UserAttributionService {
        conversionTrackerSpy = ConversionTrackerSpy()
        return UserAttributionService(
            userSettingsProvider: { .settings(crashReports: false, telemetry: telemetryEnabled) },
            userDefaults: UserDefaults(suiteName: UUID().uuidString)!,
            conversionTracker: conversionTrackerSpy
        )
    }

    @Test
    func telemetryEnabled_EventIsForwardedToAdAttributionService() async {
        let sut = makeSut(telemetryEnabled: true)

        await sut.handle(event: .loggedIn)

        #expect(conversionTrackerSpy.capturedConversionValue.count == 1)
    }

    @Test
    func telemetryDisabled_EventIsNotForwarded() async throws {
        let sut = makeSut(telemetryEnabled: false)

        await sut.handle(event: .loggedIn)

        #expect(conversionTrackerSpy.capturedConversionValue.isEmpty)
    }
}
