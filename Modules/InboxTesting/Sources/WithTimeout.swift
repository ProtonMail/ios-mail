//
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

public func withTimeout<T>(
    _ timeout: Duration = .seconds(10),
    timeoutableBlock: @escaping () async throws -> T
) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
        var continuationResumed = false

        let timeoutBlock: () async throws -> T = {
            try await Task.sleep(until: .now + timeout)
            throw TimeoutError.init()
        }

        for block in [timeoutableBlock, timeoutBlock] {
            Task {
                let result: Result<T, Error>

                do {
                    let output = try await block()
                    result = .success(output)
                } catch {
                    result = .failure(error)
                }

                if !continuationResumed {
                    continuationResumed = true
                    continuation.resume(with: result)
                }
            }
        }
    }
}

private struct TimeoutError: Error {}
