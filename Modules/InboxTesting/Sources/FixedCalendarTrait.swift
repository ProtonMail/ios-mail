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
    public let calendar: Calendar

    init(calendar: Calendar) {
        self.calendar = calendar
    }

    public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: () async throws -> Void
    ) async throws {
        try await DateEnvironment.$calendar.withValue(calendar, operation: function)
    }
}

extension Trait where Self == FixedCalendarTrait {
    public static var calendarZurichEnUS: Self {
        .init(calendar: .zurichEnUS)
    }
}

/// Executes a closure with the calendar environment temporarily fixed to Zurich (`en_US`).
///
/// This is useful for deterministic unit/snapshot tests by ensuring consistent date formatting. It serves
/// as a manual equivalent to a `FixedCalendarTrait` for use in standard XCTest cases.
///
/// - Parameter function: An async, throwing closure to execute on the main actor.
/// - Returns: The result of the `function` parameter.
/// - Throws: Any error thrown by the `function`.
@MainActor
public func withCalendarZurichEnUS<Result>(
    perform function: @MainActor () async throws -> Result
) async throws -> Result {
    try await DateEnvironment.$calendar.withValue(.zurichEnUS, operation: function)
}

private extension Calendar {
    static var zurichEnUS: Self {
        var calendar = DateEnvironment.calendar
        calendar.locale = Locale(identifier: "en_US")
        calendar.timeZone = TimeZone(identifier: "Europe/Zurich").unsafelyUnwrapped
        return calendar
    }
}
