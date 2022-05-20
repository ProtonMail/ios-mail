// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation

open class IndexSingleMessageAsyncOperation: Operation {
    public enum State: String {
        case ready = "Ready"
        case executing = "Executing"
        case finished = "Finished"
        fileprivate var keyPath: String { return "is" + self.rawValue }
    }
    private var stateStore: State = .ready
    private let stateQueue = DispatchQueue(label: "Async State Queue", attributes: .concurrent)
    public var state: State {
        get {
            stateQueue.sync {
                return stateStore
            }
        }
        set {
            let oldValue = state
            willChangeValue(forKey: state.keyPath)
            willChangeValue(forKey: newValue.keyPath)
            stateQueue.sync(flags: .barrier) {
                stateStore = newValue
            }
            didChangeValue(forKey: state.keyPath)
            didChangeValue(forKey: oldValue.keyPath)
        }
    }
    public weak var message: ESMessage? = nil
    public let userID: String

    init(_ message: ESMessage, _ userID: String) {
        self.message = message
        self.userID = userID
    }

    public override var isAsynchronous: Bool {
        return true
    }

    public override var isExecuting: Bool {
        return state == .executing
    }

    public override var isFinished: Bool {
        return state == .finished
    }

    public override func start() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .ready
            main()
        }
    }

    public override func main() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .executing
        }

        EncryptedSearchService.shared.getMessageDetailsForSingleMessage(for: self.message, userID: self.userID) { messageWithDetails in
            EncryptedSearchService.shared.decryptAndExtractDataSingleMessage(for: messageWithDetails!, userID: self.userID, isUpdate: false) { [weak self] in
                userCachedStatus.encryptedSearchProcessedMessages += 1
                EncryptedSearchService.shared.updateProgressedMessagesUI()
                self?.state = .finished
            }
        }
    }

    public func finish() {
        state = .finished
        self.message = nil
    }

    public override func cancel() {
        super.cancel()
        if self.state == .executing {
            self.finish()
        }
    }
}

