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

public struct SentryAnalytics {
    public let start: (@escaping (Options) -> Void) -> Void
    public let stop: () -> Void
    public let isSentryEnabled: () -> Bool

    public init(
        start: @escaping (@escaping (Options) -> Void) -> Void,
        stop: @escaping () -> Void,
        isSentryEnabled: @escaping () -> Bool
    ) {
        self.start = start
        self.stop = stop
        self.isSentryEnabled = isSentryEnabled
    }
}

extension SentryAnalytics {

    public static var production: SentryAnalytics {
        .init(
            start: SentrySDK.start,
            stop: SentrySDK.close,
            isSentryEnabled: { SentrySDK.isEnabled }
        )
    }

}
