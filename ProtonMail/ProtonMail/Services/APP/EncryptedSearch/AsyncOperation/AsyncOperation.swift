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

class AsyncOperation: Operation {
    enum State: String {
        case ready
        case executing
        case finished

        var keyPath: String { return "is\(rawValue.capitalized)" }
    }

    private var stateStore: State = .ready
    private let stateQueue = DispatchQueue(label: "Async State Queue")
    var state: State {
        get {
            stateQueue.sync {
                return stateStore
            }
        }
        set {
            let oldValue = state
            willChangeValue(forKey: oldValue.keyPath)
            willChangeValue(forKey: newValue.keyPath)
            stateQueue.sync {
                stateStore = newValue
            }
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: newValue.keyPath)
        }
    }

    override var isAsynchronous: Bool { true }
    override var isReady: Bool { state == .ready }
    override var isExecuting: Bool { state == .executing }
    override var isFinished: Bool { state == .finished }

    override func start() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .ready
            main()
        }
    }

    override func main() {
        if isCancelled {
            state = .finished
            return
        } else {
            state = .executing
        }
    }

    func finish() {
        state = .finished
    }

    override func cancel() {
        super.cancel()
        if state == .executing {
            finish()
        }
    }

    func log(message: String, isError: Bool = false) {
        SystemLogger.log(message: message, category: .encryptedSearch, isError: isError)
    }
}
