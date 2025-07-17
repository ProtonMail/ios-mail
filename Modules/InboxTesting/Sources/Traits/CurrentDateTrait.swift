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

public struct CurrentDateTrait: SuiteTrait, TestTrait, TestScoping {
    public let date: Date

    public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: () async throws -> Void
    ) async throws {
        try await DateEnvironment.$currentDate
            .withValue({ date }, operation: function)
    }
}

extension Trait where Self == CurrentDateTrait {
    /// A testing trait that fixes the current date to a specific moment in time.
    ///
    /// Use this trait in a suite or test to ensure that any code relying on the current
    /// date (i.e., `Date()`) is deterministic. This is essential for reliable unit and
    /// snapshot testing, as it prevents failures caused by running tests at different times.
    ///
    /// - Parameter date: The specific date to use as the "current" date during the test.
    public static func currentDate(_ date: Date) -> Self {
        .init(date: date)
    }
}
