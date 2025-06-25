// Copyright (c) 2024 Proton Technologies AG
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

import Sentry

public final class Analytics: Sendable {
    private let sentryAnalytics: SentryAnalytics

    public init(sentryAnalytics: SentryAnalytics = .production) {
        self.sentryAnalytics = sentryAnalytics
    }

    public func configure() {
        sentryAnalytics.start { options in
            options.dsn = SentryConfiguration.dsn
            options.enableAutoPerformanceTracing = false
            options.enableAppHangTracking = false
            options.enableCaptureFailedRequests = false
        }
    }

    private enum SentryConfiguration {
        static let dsn = "https://a3be1429a241459790c784466f194565@api.protonmail.ch/core/v4/reports/sentry/83"
    }
}
