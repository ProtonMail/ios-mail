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

public struct CalendarTrait: SuiteTrait, TestTrait, TestScoping {
    public let calendar: Calendar

    public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: () async throws -> Void
    ) async throws {
        try await DateEnvironment.$calendar.withValue(calendar, operation: function)
    }
}

public struct CalendarGMTTrait: SuiteTrait, TestTrait, TestScoping {
    public let calendar: Calendar

    public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: () async throws -> Void
    ) async throws {
        try await DateEnvironment.$calendarGMT.withValue(calendar, operation: function)
    }
}

extension Trait where Self == CalendarTrait {
    /// A testing trait that fixes the calendar to Zurich (`en_US`).
    ///
    /// Use this trait in suite or tests to ensure date and time formatting is deterministic,
    /// which is essential for reliable unit/snapshot testing.
    public static var calendarZurichEnUS: Self {
        .init(calendar: .zurichEnUS)
    }
}

extension Trait where Self == CalendarGMTTrait {
    /// A testing trait that fixes the calendar to GMT (`en_US`).
    ///
    /// Use this trait in suite or tests to ensure date and time formatting is deterministic,
    /// which is essential for reliable unit/snapshot testing.
    public static var calendarGMTEnUS: Self {
        .init(calendar: .gmtEnUS)
    }
}

private extension Calendar {
    static var zurichEnUS: Self {
        var calendar = DateEnvironment.calendar
        calendar.locale = Locale(identifier: "en_US")
        calendar.timeZone = TimeZone(identifier: "Europe/Zurich").unsafelyUnwrapped
        return calendar
    }

    static var gmtEnUS: Self {
        var calendar = DateEnvironment.calendar
        calendar.locale = Locale(identifier: "en_US")
        calendar.timeZone = .gmt
        return calendar
    }
}
