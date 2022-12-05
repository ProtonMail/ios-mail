// Copyright (c) 2022 Proton AG
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

/// The intention of this protocol is to provide objects and helper methods for use cases.
protocol UseCase {
    typealias UseCaseResult<T> = (Result<T, Error>) -> Void
}

extension UseCase {

    /// Use this function to execute the return callback on the Main thread
    func runOnMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
}

/// Parent class that allows use cases to implement the same multithreading approach.
class NewUseCase<T, Params> {
    typealias Callback = (Result<T, Error>) -> Void

    private(set) var executionQueue: DispatchQueue = .global(qos: .userInitiated)
    private(set) var callbackQueue: DispatchQueue = .global(qos: .userInitiated)

    func executeOn(_ queue: DispatchQueue) -> Self {
        executionQueue = queue
        return self
    }

    func callbackOn(_ queue: DispatchQueue) -> Self {
        callbackQueue = queue
        return self
    }

    func executionBlock(params: Params, callback: @escaping Callback) {
        fatalError("this function needs to be overriden providing the use case logic")
    }

    func execute(params: Params, callback: @escaping Callback) {
        executionQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.executionBlock(params: params) { result in
                self?.callbackQueue.async {
                    callback(result)
                }
            }
        }
    }
}
