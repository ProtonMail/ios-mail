// Copyright (c) 2023 Proton Technologies AG
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

// swiftlint:disable large_tuple
enum ConcurrencyUtils {
    static func runWithCompletion<ReturnType: Sendable>(
        block: @escaping () async throws -> ReturnType,
        callCompletionOn completionQueue: DispatchQueue = .main,
        completion: (@Sendable (Result<ReturnType, Error>) -> Void)?
    ) {
        Task {
            let result: Result<ReturnType, Error>

            do {
                let output = try await block()
                result = .success(output)
            } catch {
                result = .failure(error)
            }

            completionQueue.async {
                completion?(result)
            }
        }
    }

    static func runWithCompletion<A, ReturnType>(
        block: @escaping (A) async throws -> ReturnType,
        argument: A,
        callCompletionOn completionQueue: DispatchQueue = .main,
        completion: (@Sendable (Result<ReturnType, Error>) -> Void)?
    ) {
        runWithCompletion(
            block: { try await block(argument) },
            callCompletionOn: completionQueue,
            completion: completion
        )
    }

    static func runWithCompletion<A, B, ReturnType>(
        block: @escaping (A, B) async throws -> ReturnType,
        arguments: (A, B),
        callCompletionOn completionQueue: DispatchQueue = .main,
        completion: (@Sendable (Result<ReturnType, Error>) -> Void)?
    ) {
        runWithCompletion(
            block: { try await block(arguments.0, arguments.1) },
            callCompletionOn: completionQueue,
            completion: completion
        )
    }

    static func runWithCompletion<A, B, C, ReturnType>(
        block: @escaping (A, B, C) async throws -> ReturnType,
        arguments: (A, B, C),
        callCompletionOn completionQueue: DispatchQueue = .main,
        completion: (@Sendable (Result<ReturnType, Error>) -> Void)?
    ) {
        runWithCompletion(
            block: { try await block(arguments.0, arguments.1, arguments.2) },
            callCompletionOn: completionQueue,
            completion: completion
        )
    }

    static func runWithCompletion<A, B, C, D, ReturnType>(
        block: @escaping (A, B, C, D) async throws -> ReturnType,
        arguments: (A, B, C, D),
        callCompletionOn completionQueue: DispatchQueue = .main,
        completion: (@Sendable (Result<ReturnType, Error>) -> Void)?
    ) {
        runWithCompletion(
            block: { try await block(arguments.0, arguments.1, arguments.2, arguments.3) },
            callCompletionOn: completionQueue,
            completion: completion
        )
    }
}
// swiftlint:enable large_tuple
