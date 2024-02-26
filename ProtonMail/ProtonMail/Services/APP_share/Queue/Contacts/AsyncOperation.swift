// Copyright (c) 2024 Proton Technologies AG
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

protocol AsyncOperationDelegate: AnyObject {
    func taskFinished(operation: AsyncOperation, error: Error?)
}

class AsyncOperation: Operation {
    let operationID: String
    weak var delegate: AsyncOperationDelegate?

    private let serialQueue = DispatchQueue(label: "ch.protonmail.protonmail.AsyncOperation")

    init(operationID: String) {
        self.operationID = operationID
    }

    override var isAsynchronous: Bool { true }

    private var _isExecuting: Bool = false
    override private(set) var isExecuting: Bool {
        get {
            serialQueue.sync { _isExecuting }
        }
        set {
            willChangeValue(forKey: "isExecuting")
            serialQueue.sync { _isExecuting = newValue }
            didChangeValue(forKey: "isExecuting")
        }
    }

    private var _isFinished: Bool = false
    override private(set) var isFinished: Bool {
        get {
            serialQueue.sync { _isFinished }
        }
        set {
            willChangeValue(forKey: "isFinished")
            serialQueue.sync { _isFinished = newValue }
            didChangeValue(forKey: "isFinished")
        }
    }

    override func start() {
        guard !isCancelled else {
            finish(error: nil)
            return
        }
        isFinished = false
        isExecuting = true
        main()
    }

    override func main() {
        fatalError("override main in a subclass")
    }

    func finish(error: Error?) {
        delegate?.taskFinished(operation: self, error: error)
        isExecuting = false
        isFinished = true
    }
}
