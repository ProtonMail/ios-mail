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

open class DownloadPageAsyncOperation: Operation {
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

    public let userID: String
    public let page: Int?

    init(userID: String, page: Int?) {
        self.userID = userID
        self.page = page
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

        EncryptedSearchService.shared.fetchMessages(userID: self.userID,
                                                    byLabel: Message.Location.allmail.rawValue,
                                                    time: userCachedStatus.encryptedSearchLastMessageTimeIndexed,
                                                    lastMessageID: userCachedStatus.encryptedSearchLastMessageIDIndexed,
                                                    page: self.page) { error, messages in
            if error == nil {
                if let messages = messages {
                    let sortedMessages = messages.sorted {
                        $0.time > $1.time
                    }
                    guard sortedMessages.isEmpty == false else {
                        self.finish()
                        return
                    }
                    EncryptedSearchService.shared.processPageOneByOne(forBatch: sortedMessages,
                                                                      userID: self.userID) {
                        let timeOfLastMessageInBatch: Int = Int(sortedMessages.last?.time ?? Double(EncryptedSearchIndexService.shared.getOldestMessageInSearchIndex(for: self.userID).asInt))
                        if userCachedStatus.encryptedSearchLastMessageTimeIndexed > 0 &&
                           (timeOfLastMessageInBatch > userCachedStatus.encryptedSearchLastMessageTimeIndexed) {
                            print("Error: Time out of sync. Messages will be downloaded twice.")
                        }
                        userCachedStatus.encryptedSearchLastMessageTimeIndexed = timeOfLastMessageInBatch
                        userCachedStatus.encryptedSearchLastMessageIDIndexed = sortedMessages.last?.id
                        self.finish()   // Set operation to be finished
                    }
                } else {
                    print("Error while fetching messages: \(String(describing: error))")
                    self.finish()   // Set operation to be finished
                }
            } else {
                print("Error while fetching messages: \(String(describing: error))")
                self.finish()   // Set operation to be finished
            }
        }
    }

    public func finish() {
        state = .finished
    }

    public override func cancel() {
        super.cancel()
        if self.state == .executing {
            self.finish()
        }
    }
}
