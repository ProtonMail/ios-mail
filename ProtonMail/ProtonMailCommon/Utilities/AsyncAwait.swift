// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import PromiseKit
import CoreData

func async<T>(_ body: @escaping () throws -> T) -> Promise<T> {
    Promise { seal in
        DispatchQueue.global().async {
            do {
                let value = try body()
                seal.fulfill(value)
            } catch {
                seal.reject(error)
            }
        }
    }
}

func async(_ body: @escaping () -> Void) {
    DispatchQueue.global().async {
        body()
    }
}

func await<T>(_ promise: Promise<T>) throws -> T {
    try AwaitKit.await(promise)
}

enum AwaitKit {
    static func await<T>(_ promise: Promise<T>) throws -> T {
        if Thread.isMainThread {
            assertionFailure("Should not call this method on main thread.")
        }

        return try promise.wait()
    }
}

extension NSManagedObjectContext {
    func performAsPromise<T>(body: @escaping () throws -> T) -> Promise<T> {
        Promise { seal in
            perform {
                do {
                    let output = try body()
                    seal.fulfill(output)
                } catch {
                    seal.reject(error)
                }
            }
        }
    }

    func performAsPromise<T>(body: @escaping () -> T) -> Guarantee<T> {
        Guarantee { completion in
            perform {
                let output = body()
                completion(output)
            }
        }
    }
}
