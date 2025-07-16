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

import Foundation
import InboxCore
import Testing

public struct FixedCalendarTrait: TestTrait, TestScoping {
    public let locale: Locale
    public let timeZone: TimeZone

    init(locale: Locale, timeZone: TimeZone) {
        self.locale = locale
        self.timeZone = timeZone
    }

    public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: () async throws -> Void
    ) async throws {
        var calendar = DateEnvironment.calendar
        calendar.locale = locale
        calendar.timeZone = timeZone

        try await DateEnvironment.$calendar.withValue(calendar, operation: function)
    }
}

extension Trait where Self == FixedCalendarTrait {
    public static var calendarZurichEnCH: Self {
        let locale = Locale(identifier: "en_CH")
        let timeZone = TimeZone(identifier: "Europe/Zurich").unsafelyUnwrapped

        return .init(locale: locale, timeZone: timeZone)
    }
}
