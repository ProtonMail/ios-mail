//
//  QueueManager.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

protocol QueueHandler {
    var userID: String { get }
    func handleTask(_ task: QueueManager.Task, completion: @escaping (QueueManager.Task, QueueManager.TaskResult) -> Void)
}

/// This manager is to handle the queue opeartions of all users.
final class QueueManager: Service {
    typealias ReadBlock = (() -> Void)
    typealias TaskID = UUID
    typealias UserID = String

    private let queue = DispatchQueue(label: "Protonmail.QueueManager.Queue")

    /// Handle send message related things
    private let messageQueue: PMPersistentQueueProtocol
    /// Handle actions exclude sending message related things
    private let miscQueue: PMPersistentQueueProtocol
    private let reachability: Reachability
    /// Handle the fetching data related things
    private var readQueue: [ReadBlock] = []
    private var handlers: [UserID: QueueHandler] = [:]

    var isRequiredHumanCheck = false

    //These two variables are used to prevent concurrent call of dequeue=
    private var isMessageRunning: Bool = false
    private var isMiscRunning: Bool = false
    // The last allowed background executing timing
    private var allowedTime: TimeInterval? = nil

    // A block will be called when exceed allowed background execute time
    private var exceedNotify: (() -> Void)?

    init(messageQueue: PMPersistentQueueProtocol,
         miscQueue: PMPersistentQueueProtocol,
         reachability: Reachability = Reachability.forInternetConnection()) {
        self.messageQueue = messageQueue
        self.miscQueue = miscQueue
        self.reachability = reachability
    }

    // MARK: Add task
    static func newTask() -> Task {
        let uuid = UUID()
        return Task(uuid: uuid,
                        messageID: "",
                        actionString: "",
                        userID: "",
                        dependencyIDs: [],
                        data1: "",
                        data2: "",
                        isConversation: false)
    }

    func addTask(_ task: Task, autoExecute: Bool = true) -> Bool {
        self.queue.sync {
            guard !task.actionString.isEmpty, !task.userID.isEmpty else {
                return false
            }
            let action = MessageAction(rawValue: task.actionString)
            switch action {
            case .saveDraft,
                 .uploadAtt, .uploadPubkey, .deleteAtt,
                 .send:
                let dependencies = self.getMessageTasks(of: task.userID)
                    .filter { $0.messageID == task.messageID }
                    .map(\.uuid)
                task.dependencyIDs = dependencies
                _ = self.messageQueue.add(task.uuid, object: task)
            case .read, .unread,
                 .delete,
                 .emptyTrash, .emptySpam, .empty,
                 .label, .unlabel, .folder,
                 .updateLabel, .createLabel, .deleteLabel:
                _ = self.miscQueue.add(task.uuid, object: task)
            case .signout:
                self.handleSignout(signoutTask: task)
            case .signin:
                self.handleSignin(userID: task.userID)
            default:
                PMLog.D("Add task for unknow action: \(task.actionString)")
                return false
            }
            if autoExecute {
                self.dequeueIfNeeded()
            }
            return true
        }
    }

    func queue(_ readBlock: @escaping ReadBlock) {
        self.queue.async {
            self.readQueue.append(readBlock)
            self.dequeueIfNeeded()
        }
    }

    // MARK: Queue handler
    func registerHandler(_ handler: QueueHandler) {
        self.queue.async {
            self.handlers[handler.userID] = handler
        }
    }

    func unregisterHandler(_ handler: QueueHandler) {
        self.queue.async {
            _ = self.handlers.removeValue(forKey: handler.userID)
        }
    }

    // MARK: Background

    /// Claim the app enter the background
    /// - Parameters:
    ///   - allowedTime: The time that the last time the tasks can be executed
    ///   - notify: Execute when all of tasks finish or the time is running out
    func backgroundFetch(allowedTime: TimeInterval, notify: @escaping (() -> Void)) {
        self.queue.async {
            self.allowedTime = allowedTime
            self.exceedNotify = notify
            self.dequeueIfNeeded()
        }
    }

    func enterForeground() {
        self.queue.async {
            self.allowedTime = nil
            self.dequeueIfNeeded()
        }
    }

    // MARK: Queue operations
    func removeAllTasks(of msgID: String, actions: [MessageAction], completeHandler: (()->())?) {
        self.queue.async {
            let targetTasks = self.getMessageTasks(of: nil).filter { (task) -> Bool in
                if let action = MessageAction(rawValue: task.actionString) {
                    return task.messageID == msgID && actions.contains(action)
                }
                return false
            }
            targetTasks.forEach { (task) in
                _ = self.messageQueue.remove(task.uuid)
            }
            completeHandler?()
        }
    }

    func isAnyQueuedMessage(of userID: UserID) -> Bool {
        self.queue.sync {
            let messageTasks = self.getMessageTasks(of: userID)
            let miscTasks = self.getMiscTasks(of: userID)
            let allTasks = messageTasks + miscTasks
            return allTasks.count > 0
        }
    }

    func deleteAllQueuedMessage(of userID: UserID, completeHander: (()->())?) {
        self.queue.async {
            self.getMessageTasks(of: userID)
                .forEach { _ = self.messageQueue.remove($0.uuid)}

            self.getMiscTasks(of: userID)
                .forEach { _ = self.miscQueue.remove($0.uuid)}
            
            completeHander?()
        }
    }

    func queuedMessageIds() -> Set<String> {
        self.queue.sync {
            let allTasks = self.getMessageTasks(of: nil)
            return Set(allTasks.map(\.messageID))
        }
    }

    func queuedMiscTaskIDs() -> Set<String> {
        self.queue.sync {
            let allTasks = self.getMiscTasks(of: nil)
            return Set(allTasks.map(\.messageID))
        }
    }

    func clearAll(completeHandler: (()->())?) {
        self.queue.async {
            self.messageQueue.clearAll()
            self.miscQueue.clearAll()
            completeHandler?()
        }
    }
}

// MARK: Private functions
extension QueueManager {
    private func getTasks(from queue: PMPersistentQueueProtocol, userID: UserID?) -> [Task] {
        let allTasks = queue.queueArray().tasks
        if let id = userID {
            return allTasks.filter { $0.userID == id }
        } else {
            return allTasks
        }
    }

    private func getMessageTasks(of userID: UserID?) -> [Task] {
        return self.getTasks(from: self.messageQueue, userID: userID)
    }

    private func getMiscTasks(of userID: UserID?) -> [Task] {
        return self.getTasks(from: self.miscQueue, userID: userID)
    }

    private func handleSignout(signoutTask: Task) {
        /*
         1. Remove all of tasks that triggered by the user
         2. Insert the task to the begining of the queue

         What if the first task is from the user?
         There are two condition
         1. Online: Even the task removed from the queue, it still doing HTTP request
         2. Offline: The first task won't be executed, safely remove.

         Why insert to 0?
         1. Online: The previous keep running, insert to 0 will be the next task to execute.
         2. Offline: The first task is not running, safely insert.
         */

        self.getMessageTasks(of: signoutTask.userID)
            .forEach { _ = self.messageQueue.remove($0.uuid) }
        _ = self.messageQueue.insert(uuid: signoutTask.uuid, object: signoutTask, index: 0)

        self.getMiscTasks(of: signoutTask.userID)
            .forEach { _ = self.miscQueue.remove($0.uuid) }
        _ = self.miscQueue.insert(uuid: signoutTask.uuid, object: signoutTask, index: 0)
    }

    private func handleSignin(userID: String) {
        if let task = self.getMessageTasks(of: userID)
            .first(where: { $0.actionString == MessageAction.signout.rawValue &&
                    $0.userID == userID }) {
            _ = self.messageQueue.remove(task.uuid)
        }

        if let task = self.getMiscTasks(of: userID)
            .first(where: { $0.actionString == MessageAction.signout.rawValue &&
                    $0.userID == userID }) {
            _ = self.miscQueue.remove(task.uuid)
        }
    }

    /// Do notify if all of queues are empty
    /// - Returns: Any tasks in the queue?
    private func checkQueueStatus() -> Bool {
        if self.messageQueue.count <= 0 &&
            self.miscQueue.count <= 0 &&
            self.readQueue.count <= 0 {
            NotificationCenter.default.post(name: .queueIsEmpty, object: nil)

            // Use when the app is in the background
            // To end the background task
            self.exceedNotify?()
            self.exceedNotify = nil
            return false
        }
        return true
    }

    /// Check the execute time limitation
    private func allowedToDequeue() -> Bool {
        guard let limitation = self.allowedTime else {
            // App in the foreground
            return true
        }

        // App in the background
        let now = Date().timeIntervalSinceNow
        let isAllowed = limitation > now
        if !isAllowed {
            if !self.isMiscRunning && !self.isMessageRunning {
                self.exceedNotify?()
                self.exceedNotify = nil
            }
        }
        return isAllowed
    }

    private func nextTask(from queue: PMPersistentQueueProtocol) -> Task? {
        if isRequiredHumanCheck {
            return nil
        }

        //TODO: check dependency id, to skip or continue
        guard let next = queue.next() else {
            return nil
        }

        if let task = next.object as? Task {
            return task
        }

        if let legacyTask = next.object as? [String: Any] {
            let task = Task(uuid: next.elementID,
                            messageID: legacyTask[LegacyTaskKey.id] as? String ?? "",
                            actionString: legacyTask[LegacyTaskKey.action] as? String ?? "",
                            userID: legacyTask[LegacyTaskKey.userId] as? String ?? "",
                            dependencyIDs: [],
                            data1: legacyTask[LegacyTaskKey.data1] as? String ?? "",
                            data2: legacyTask[LegacyTaskKey.data2] as? String ?? "",
                            isConversation: false)
            return task
        }

        return nil
    }

    private func dequeueIfNeeded() {
        guard self.reachability.currentReachabilityStatus() != .NotReachable,
              self.checkQueueStatus(),
              self.allowedToDequeue() else {return}
        self.dequeueMessageQueue()
        self.dequeueMiscQueue()
    }

    private func dequeueMessageQueue() {
        guard !isMessageRunning && allowedToDequeue() else { return }

        guard let task = self.nextTask(from: self.messageQueue) else {
            self.dequeueReadQueue()
            return
        }

        guard task.dependencyIDs.count == 0 else {
            PMLog.D("The dependency should be empty, some previous task failed, current action is \(task.actionString)")
            let actions: [MessageAction] = [.saveDraft, .uploadAtt,
                                            .uploadPubkey, .deleteAtt, .send]
            self.removeAllTasks(of: task.messageID, actions: actions) {
                self.dequeueReadQueue()
            }
            return
        }

        guard let action = MessageAction(rawValue: task.actionString),
              let handler = self.handlers[task.userID] else {
            PMLog.D(" Unsupported action: \(task.actionString) or handler is nil: \(self.handlers[task.userID] == nil). removing from message queue.")
            _ = self.messageQueue.remove(task.uuid)
            self.dequeueMessageQueue()
            return
        }

        if action == .signout,
           let _ = self.getMiscTasks(of: task.userID)
            .first(where: { $0.actionString == task.actionString }) {
            // The misc queue has running task
            // skip this task, let misc queue to handle signout task
            _ = self.messageQueue.remove(task.uuid)
            self.dequeueMessageQueue()
            return
        }

        self.isMessageRunning = true
        self.queue.async {
            //call handler to tell queue to continue
            handler.handleTask(task) { (task, result) in
                self.queue.async {
                    self.isMessageRunning = false
                    self.handle(result, of: task, on: self.messageQueue) { (isOnline) in
                        if isOnline {
                            self.dequeueMessageQueue()
                        }
                    }
                }
            }
        }
    }

    private func dequeueMiscQueue() {
        guard !self.isMiscRunning && self.allowedToDequeue() else {return}

        guard let task = self.nextTask(from: self.miscQueue) else {
            self.dequeueReadQueue()
            return
        }

        guard let action = MessageAction(rawValue: task.actionString),
              let handler = self.handlers[task.userID] else {
            PMLog.D(" Unsupported action \(task.actionString) or handler is nil: \(self.handlers[task.userID] == nil), removing from misc queue.")
            _ = self.miscQueue.remove(task.uuid)
            return
        }

        if action == .signout,
           let _ = self.getMessageTasks(of: task.userID)
            .first(where: { $0.actionString == task.actionString }) {
            // The message queue has running task
            // skip this task, let message queue to handle signout task
            _ = self.miscQueue.remove(task.uuid)
            self.dequeueMessageQueue()
            return
        }

        self.isMiscRunning = true
        self.queue.async {
            //call handler to tell queue to continue
            handler.handleTask(task) { (task, result) in
                self.queue.async {
                    self.isMiscRunning = false
                    self.handle(result, of: task, on: self.miscQueue) { (isOnline) in
                        if isOnline {
                            self.dequeueMiscQueue()
                        }
                    }
                }
            }
        }
    }

    /// - Returns: isOnline
    private func handle(_ result: TaskResult, of task: Task, on queue: PMPersistentQueueProtocol, completeHander: @escaping ((Bool)->())) {

        if task.actionString == MessageAction.signout.rawValue,
           let handler = self.handlers[task.userID] {
            _ = self.handlers.removeValue(forKey: handler.userID)
        }

        switch result.action {
        case .checkReadQueue:
            let removed = queue.queueArray().tasks
                .filter { $0.dependencyIDs.contains(task.uuid) }
            removed.forEach { _ = queue.remove($0.uuid) }
            self.remove(task: task, on: queue)
            self.dequeueReadQueue()
            completeHander(true)
        case .removeDoubleSent(let tuple):
            self.remove(task: task, on: queue)
            self.removeAllTasks(of: tuple.messageID, actions: tuple.actions) {
                completeHander(true)
            }
        case .none:
            self.remove(task: task, on: queue)
            completeHander(true)
        case .connectionIssue:
            // Forgot the signout task in offline mode
            if task.actionString == MessageAction.signout.rawValue {
                _ = queue.remove(task.uuid)
            }
            completeHander(false)
        case .removeRelated:
            let removed = queue.queueArray().tasks
                .filter { $0.dependencyIDs.contains(task.uuid) }
            removed.forEach { _ = queue.remove($0.uuid) }
            self.remove(task: task, on: queue)
            completeHander(true)
        case .retry:
            completeHander(true)
            break
        }
    }

    private func remove(task: Task, on queue: PMPersistentQueueProtocol) {
        // Remove the dependency of the following tasks
        queue.queueArray().tasks
            .filter { $0.messageID == task.messageID }
            .forEach { peddingTask in
                if let idx = peddingTask.dependencyIDs.firstIndex(of: task.uuid) {
                    peddingTask.dependencyIDs.remove(at: idx)
                    queue.update(uuid: peddingTask.uuid, object: peddingTask)
                }
            }
        // Remove the task
        _ = queue.remove(task.uuid)
    }

    private func dequeueReadQueue() {
        guard self.allowedToDequeue(),
              !self.readQueue.isEmpty else {
            _ = self.checkQueueStatus()
            return
        }
        let clourse = self.readQueue.remove(at: 0)
        //Execute the first closure in readQueue
        self.queue.async {
            clourse()
        }

        self.dequeueIfNeeded()
    }
}

extension QueueManager {
    enum TaskError: Error {
        case unSupportAction
    }

    enum TaskAction {
        case none
        /// Remove related task due to the message has been sent
        case removeDoubleSent((messageID: String, actions: [MessageAction]))
        /// Queue is not block and readqueue > 0
        case checkReadQueue
        /// Stop dequeu
        case connectionIssue
        /// The task failed, remove related tasks
        case removeRelated
        /// Retry task
        case retry
    }

    struct TaskResult {
        var error: TaskError?
        var response: [[String: Any]]?
        var action: TaskAction
        /// The update won't be written into disk
        var retry: Int = 0

        init(error: TaskError? = nil, response: [[String: Any]]? = nil, action: TaskAction = .none) {
            self.error = error
            self.response = response
            self.action = action
        }
    }

    @objc(_TtCC5Share12QueueManager4Task) final class Task: NSObject, NSCoding {
        var uuid: TaskID
        var messageID: String
        var actionString: String
        var userID: String
        /// The taskID in this array should be done to execute this task
        var dependencyIDs: [TaskID]
        var data1: String
        var data2: String
        var otherData: Any?
        var isConversation: Bool

        init(uuid: TaskID,
             messageID: String,
             actionString: String,
             userID: String,
             dependencyIDs: [TaskID],
             data1: String,
             data2: String,
             isConversation: Bool,
             otherData: Any? = nil) {
            self.uuid = uuid
            self.messageID = messageID
            self.actionString = actionString
            self.userID = userID
            self.dependencyIDs = dependencyIDs
            self.data1 = data1
            self.data2 = data2
            self.isConversation = isConversation
            self.otherData = otherData
        }

        func encode(with coder: NSCoder) {
            coder.encode(uuid, forKey: "uuid")
            coder.encode(messageID, forKey: "messageID")
            coder.encode(userID, forKey: "userID")
            coder.encode(actionString, forKey: "actionString")
            coder.encode(dependencyIDs, forKey: "dependencyIDs")
            coder.encode(data1, forKey: "data1")
            coder.encode(data2, forKey: "data2")
            coder.encode(otherData, forKey: "otherData")
            coder.encode(isConversation, forKey: "isConversation")
        }

        required convenience init?(coder: NSCoder) {
            guard let uuid = coder.decodeObject(forKey: "uuid") as? UUID,
                  let messageID = coder.decodeObject(forKey: "messageID") as? String,
                  let userID = coder.decodeObject(forKey: "userID") as? String,
                  let actionString = coder.decodeObject(forKey: "actionString") as? String,
                  let dependencyIDs = coder.decodeObject(forKey: "dependencyIDs") as? [UUID],
                  let data1 = coder.decodeObject(forKey: "data1") as? String,
                  let data2 = coder.decodeObject(forKey: "data2") as? String,
                  let otherData = coder.decodeObject(forKey: "otherData"),
                  coder.containsValue(forKey: "isConversation")
            else { return nil }

            let isConversation = coder.decodeBool(forKey: "isConversation")

            self.init(uuid: uuid,
                      messageID: messageID,
                      actionString: actionString,
                      userID: userID,
                      dependencyIDs: dependencyIDs,
                      data1: data1,
                      data2: data2,
                      isConversation: isConversation,
                      otherData: otherData)
        }
    }

    struct LegacyTaskKey {
        static let id = "id"
        static let action = "action"
        static let time = "time"
        static let count = "count"
        static let data1 = "data1"
        static let data2 = "data2"
        static let userId = "userId"
    }
}

private extension Collection where Element == Any {

    var tasks: [QueueManager.Task] {
        compactMap { $0 as? [String: Any] }
        .compactMap { $0["object"] as? QueueManager.Task }
    }

}
