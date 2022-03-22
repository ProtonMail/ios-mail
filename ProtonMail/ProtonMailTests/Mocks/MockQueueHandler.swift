//
//  MockQueueHandler.swift
//  ProtonMailTests
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

@testable import ProtonMail

final class MockQueueHandler: QueueHandler {
    
    private(set) var userID: String
    private(set) var handleCount = 0
    private(set) var handledTasks: [QueueManager.Task] = []
    private var result: QueueManager.TaskAction = .none
    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.maxConcurrentOperationCount = 1
        return q
    }()
    
    init(userID: String) {
        self.userID = userID
    }
    
    func setResult(to result: QueueManager.TaskAction) {
        self.result = result
    }
    
    func handleTask(_ task: QueueManager.Task, completion: @escaping (QueueManager.Task, QueueManager.TaskResult) -> Void) {
        // To simulate async operation of http request
        self.queue.addOperation {
            let result = QueueManager.TaskResult(response: nil, action: self.result)
            self.handleCount = self.handleCount + 1
            self.handledTasks.append(task)
            completion(task, result)
        }
    }
}
