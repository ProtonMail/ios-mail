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

import InboxTesting
import Testing
import proton_app_uniffi

@testable import ProtonMail

class UserAnalyticsConfiguratorTests {
    var sentryStartInvokeCount = 0
    var sentryStopInvokeCount = 0
    var stubbedSentryIsEnabledStatus = false

    lazy var mailUserSessionSpy = MailUserSessionSpy(id: .notUsed)

    lazy var sut = UserAnalyticsConfigurator(
        mailUserSession: mailUserSessionSpy,
        analytics: .init(
            sentryAnalytics: .init(
                start: { [unowned self] _ in sentryStartInvokeCount += 1 },
                stop: { [unowned self] in sentryStopInvokeCount += 1 }
            ))
    )

    @Test
    func SentryFollowsConfigurationChanges() async throws {
        mailUserSessionSpy.stubbedUserSettings = .settings(crashReports: true, telemetry: true)
        await sut.observeUserAnalyticsSettings()

        #expect(mailUserSessionSpy.watchUserSettingsCallback.count == 1)
        let callback = try #require(mailUserSessionSpy.watchUserSettingsCallback.first)
        #expect(sentryStopInvokeCount == 1)
        #expect(sentryStartInvokeCount == 1)

        await callback.onUpdate()

        #expect(sentryStopInvokeCount == 1)
        #expect(sentryStartInvokeCount == 1)

        mailUserSessionSpy.stubbedUserSettings = .settings(crashReports: true, telemetry: false)
        await callback.onUpdate()

        #expect(sentryStopInvokeCount == 2)
        #expect(sentryStartInvokeCount == 2)

        mailUserSessionSpy.stubbedUserSettings = .settings(crashReports: false, telemetry: true)
        await callback.onUpdate()

        #expect(sentryStopInvokeCount == 3)
        #expect(sentryStartInvokeCount == 3)

        mailUserSessionSpy.stubbedUserSettings = .settings(crashReports: false, telemetry: false)
        await callback.onUpdate()

        #expect(sentryStopInvokeCount == 4)
        #expect(sentryStartInvokeCount == 3)
    }
}
