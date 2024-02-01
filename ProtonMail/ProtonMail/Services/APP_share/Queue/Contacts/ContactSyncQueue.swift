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

import Combine

final class ContactsSyncQueue {
    typealias Dependencies = AnyObject & HasInternetConnectionStatusProviderProtocol & HasContactDataService

    /// Subscribe to this publisher to get progress updates from the queue
    let progressPublisher: CurrentValueSubject<Progress, Never>

    private let taskQueueURL: URL
    private var hasQueueStarted: Bool = false
    private var taskQueue: [ContactTask] {
        didSet {
            do {
                let data = try JSONEncoder().encode(taskQueue)
                try data.write(to: taskQueueURL)
            } catch {
                SystemLogger.log(error: error, category: .contacts)
            }
        }
    }
    private let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .background
        // using a low number to leave room for other network operations
        queue.maxConcurrentOperationCount = 3
        return queue
    }()
    private let operationErrorHandler: AsyncOperationErrorHandler
    private let serial = DispatchQueue(label: "ch.protonmail.protonmail.ContactsSyncRequests")
    private unowned let dependencies: Dependencies

    init(userID: UserID, dependencies: Dependencies) {
        let path = "contactsQueue.\(userID.rawValue)"
        var queueFileUrl = FileManager.default.applicationSupportDirectoryURL.appendingPathComponent(path)
        SystemLogger.logTemporarily(message: "taskQueueUrl = \(queueFileUrl)", category: .contacts)
        if FileManager.default.fileExists(atPath: queueFileUrl.absoluteString) {
            BackupExcluder().excludeFromBackup(url: &queueFileUrl)
        }
        self.taskQueueURL = queueFileUrl

        self.taskQueue = []
        self.progressPublisher = .init(Progress())
        self.operationErrorHandler = .init(dependencies: dependencies)
        self.dependencies = dependencies
    }

    /// Call before adding tasks. This function will load the persisted queue from disk and start the queue execution
    func start() {
        guard !hasQueueStarted else { return }
        hasQueueStarted = true
        SystemLogger.log(message: "queue started", category: .contacts)
        if FileManager.default.fileExists(atPath: taskQueueURL.absoluteString) {
            do {
                let data = try Data(contentsOf: taskQueueURL)
                self.taskQueue = try JSONDecoder().decode([ContactTask].self, from: data)
            } catch {
                SystemLogger.log(error: error, category: .contacts)
                self.taskQueue = []
            }
            SystemLogger.log(message: "queue disk read count \(taskQueue.count)", category: .contacts)
        } else {
            self.taskQueue = []
        }
        updateProgressTotal(numAdded: taskQueue.reduce(0, { $0 + $1.numContacts }))
        enqueueOperations(taskQueue)

        dependencies.internetConnectionStatusProvider.register(receiver: self, fireWhenRegister: false)
    }

    func pause() {
        guard hasQueueStarted else { return }
        operationQueue.isSuspended = true
        SystemLogger.log(message: "queue paused", category: .contacts)
    }

    func resume() {
        guard operationQueue.isSuspended else { return }
        operationQueue.isSuspended = false
        SystemLogger.log(message: "queue resumed", category: .contacts)
    }

    func addTask(_ task: ContactTask) {
        guard hasQueueStarted else {
            SystemLogger.log(message: "queue start() not called", category: .contacts, isError: true)
            return
        }
        SystemLogger.log(message: "enqueue \(task.action) with \(task.numContacts) contacts", category: .contacts)
        serial.sync {
            taskQueue.append(task)
            updateProgressTotal(numAdded: task.numContacts)
            enqueueOperations([task])
        }
    }

    /// Stops the queue, deallocates all information from memory and deletes the persisted
    /// queue in the file system.
    func deleteQueue() {
        serial.sync {
            operationQueue.isSuspended = true
            operationQueue.cancelAllOperations()
            taskQueue.removeAll()
            resetProgress()
            do {
                try FileManager.default.removeItem(at: taskQueueURL)
            } catch {
                SystemLogger.log(error: error, category: .contacts)
            }
        }
    }
}

// MARK: Private

extension ContactsSyncQueue {

    private func enqueueOperations(_ tasks: [ContactTask]) {
        let operations = tasks.map { task -> AsyncOperation in
            let taskID = task.taskID.uuidString
            var asyncOp: AsyncOperation
            switch task.command {
            case .create(let contacts):
                asyncOp = ContactCreateOperation(id: taskID, contacts: contacts, dependencies: dependencies)
            case let .update(id, vCards):
                asyncOp = ContactUpdateOperation(id: taskID, contactID: id, vCards: vCards, dependencies: dependencies)
            }
            asyncOp.delegate = self
            return asyncOp
        }
        operationQueue.addOperations(operations, waitUntilFinished: false)
    }

    private func updateProgressTotal(numAdded: Int) {
        var progress = progressPublisher.value
        progress.total += numAdded
        progressPublisher.send(progress)
    }

    private func incrementProgress(_ increment: Int) {
        var progress = progressPublisher.value
        progress.finished += increment
        progressPublisher.send(progress)
    }

    private func resetProgress() {
        progressPublisher.send(Progress())
    }
}

// MARK: AsyncOperationDelegate

extension ContactsSyncQueue: AsyncOperationDelegate {

    func taskFinished(operation: AsyncOperation, error: Error?) {
        serial.sync {
            guard !operation.isCancelled else { return }
            guard let taskID = UUID(uuidString: operation.operationID) else { return }

            if let error = error as? NSError {
                let resolution = operationErrorHandler.onOperationError(error)
                let message = "operation resolution \(resolution) for \(taskID)"
                SystemLogger.log(message: message, category: .contacts, isError: true)

                switch resolution {
                case .abort:
                    removeFromTasksQueue(taskID: taskID)
                case .pause:
                    pause()
                    enqueueOperationAgain(taskID: taskID)
                }
            } else {
                removeFromTasksQueue(taskID: taskID)
            }
        }
    }

    private func enqueueOperationAgain(taskID: UUID) {
        guard let task = taskQueue.first(where: { $0.taskID == taskID }) else { return }
        enqueueOperations([task])
        SystemLogger.log(message: "operation enqueued again for task \(taskID)", category: .contacts)
    }

    private func removeFromTasksQueue(taskID: UUID) {
        guard let index = taskQueue.firstIndex(where: { $0.taskID == taskID }) else { return }
        let finishedIncrement = taskQueue[index].numContacts
        taskQueue.remove(at: index)
        incrementProgress(finishedIncrement)
        if taskQueue.isEmpty {
            resetProgress()
        }
    }
}

// MARK: ConnectionStatusReceiver

extension ContactsSyncQueue: ConnectionStatusReceiver {

    /// The queue will resume if network connection is back. We resume after a small delay to
    /// give priority to other requests.
    /// We disregard when te network status is disconnected because the queue will pause
    /// when any of the requests fails because of a network problem.
    func connectionStatusHasChanged(newStatus: ConnectionStatus) {
        guard newStatus.isConnected else { return }
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self else { return }
            resume()
        }
    }
}

extension ContactsSyncQueue {

    struct Progress {
        var finished: Int = 0
        var total: Int = 0
    }
}

// MARK: Model

enum ContactTaskAction: String, Codable {
    case create
    case update
}

struct ContactTask: Codable {
    let taskID: UUID
    let command: ContactTaskCommand
    var action: ContactTaskAction {
        command.action
    }
    var numContacts: Int {
        command.numContacts
    }
}

enum ContactTaskCommand: Codable {
    case create(contacts: [ContactObjectVCards])
    case update(contactID: ContactID, vCards: [CardData])

    var action: ContactTaskAction {
        switch self {
        case .create:
            return .create
        case .update:
            return .update
        }
    }

    var numContacts: Int {
        switch self {
        case .create(let contacts):
            return contacts.count
        case .update:
            return 1
        }
    }
}

struct ContactObjectVCards: Codable {
    let vCards: [CardData]
}
