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

@testable import ProtonMail
import InboxCore
import Testing
import Sentry

@MainActor
class ProtonMailAppTests {

    var startInvokeCount = 0
    var stubbedOptions = Options()
    lazy var start: ((Options) -> Void) -> Void = { [unowned self] optionsConfiguration in
        startInvokeCount += 1

        optionsConfiguration(stubbedOptions)
    }
    lazy var analytics = Analytics(sentryAnalytics: .init(start: start))

    @Test(.analyticsEnabled(true))
    func appIsRunAndAnalyticsAreEnabled_ItConfiguresAnalytics() {
        let sut = ProtonMailApp()
        sut.configureAnalyticsIfNeeded(analytics: analytics)

        #expect(startInvokeCount == 1)
        #expect(stubbedOptions.dsn != nil)
    }

    @Test(.analyticsEnabled(false))
    func appIsRunAndAnalyticsAreDisabled_ItDoesNotConfigureAnalytics() {
        let sut = ProtonMailApp()
        sut.configureAnalyticsIfNeeded(analytics: analytics)

        #expect(startInvokeCount == 0)
        #expect(stubbedOptions.dsn == nil)
    }

}

private struct AnalyticsEnabledTrait: TestTrait, TestScoping {
    let enabled: Bool

    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: () async throws -> Void
    ) async throws {
        try await AnalyticsState.$shouldConfigureAnalytics.withValue(enabled, operation: function)
    }
}

private extension Trait where Self == AnalyticsEnabledTrait {
    static func analyticsEnabled(_ enabled: Bool) -> Self {
        .init(enabled: enabled)
    }
}
