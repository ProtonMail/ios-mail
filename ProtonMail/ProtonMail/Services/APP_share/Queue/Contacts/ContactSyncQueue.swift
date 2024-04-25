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

protocol ContactsSyncQueueProtocol {
    var progressPublisher: AnyPublisher<ContactsSyncQueue.Progress, Never> { get }
    var protonStorageQuotaExceeded: AnyPublisher<Void, Never> { get }

    func setup()
    func start()
    func pause()
    func resume()
    func addTask(_ task: ContactTask)
    func saveQueueToDisk()
    func deleteQueue()
}

final class ContactsSyncQueue: ContactsSyncQueueProtocol {
    typealias Dependencies = AnyObject
    & HasInternetConnectionStatusProviderProtocol
    & HasContactDataService // not used here but forwarded to the operations that will be enqueued

    static let queueFilePrefix = "contactsQueue"

    private let fileManager: FileManager

    /// Subscribe to this publisher to get progress updates from the queue
    var progressPublisher: AnyPublisher<ContactsSyncQueue.Progress, Never> {
        _progressPublisher.eraseToAnyPublisher()
    }
    private let _progressPublisher: CurrentValueSubject<ContactsSyncQueue.Progress, Never>

    /// Subscribe to know when the backend responds with storage exceeded
    var protonStorageQuotaExceeded: AnyPublisher<Void, Never> {
        _protonStorageQuotaExceeded.eraseToAnyPublisher()
    }
    private let _protonStorageQuotaExceeded: PassthroughSubject<Void, Never>

    let taskQueueURL: URL
    /// for testing purposes
    var isPaused: Bool {
        operationQueue.isSuspended
    }

    private var hasBeenSetup: Bool = false
    private var taskQueue: [ContactTask]
    private let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.isSuspended = true
        queue.qualityOfService = .background
        // using a low number to leave room for other network operations
        queue.maxConcurrentOperationCount = 3
        return queue
    }()
    private let operationErrorHandler: AsyncOperationErrorHandler
    private let serial = DispatchQueue(label: "ch.protonmail.protonmail.ContactsSyncRequests")
    private unowned let dependencies: Dependencies

    init(userID: UserID, fileManager: FileManager = .default, dependencies: Dependencies) {
        self.fileManager = fileManager
        let path = "\(Self.queueFilePrefix).\(userID.rawValue)"
        var queueFileUrl = fileManager.applicationSupportDirectoryURL.appendingPathComponent(path)
        if fileManager.fileExists(atPath: queueFileUrl.path) {
            BackupExcluder().excludeFromBackup(url: &queueFileUrl)
        }
        self.taskQueueURL = queueFileUrl

        self.taskQueue = []
        self._progressPublisher = .init(Progress())
        self._protonStorageQuotaExceeded = .init()
        self.operationErrorHandler = .init(dependencies: dependencies)
        self.dependencies = dependencies
    }

    /// Call before adding tasks. This function will load the persisted queue from disk
    func setup() {
        guard !hasBeenSetup else { return }
        hasBeenSetup = true
        SystemLogger.log(message: "queue setup", category: .contacts)
        if fileManager.fileExists(atPath: taskQueueURL.path) {
            do {
                let data = try Data(contentsOf: taskQueueURL)
                self.taskQueue = try JSONDecoder().decode([ContactTask].self, from: data)
            } catch {
                SystemLogger.log(error: error, category: .contacts)
                self.taskQueue = []
            }
            SystemLogger.log(message: "queue disk read count: \(taskQueue.count) batches", category: .contacts)
        } else {
            SystemLogger.log(message: "queue file does not exist", category: .contacts)
            self.taskQueue = []
        }
        updateProgressTotal(numAdded: taskQueue.reduce(0, { $0 + $1.numContacts }))
        enqueueOperations(taskQueue)

        dependencies.internetConnectionStatusProvider.register(receiver: self, fireWhenRegister: false)
    }

    func start() {
        resume()
    }

    func pause() {
        guard hasBeenSetup else { return }
        operationQueue.isSuspended = true
        SystemLogger.log(message: "queue paused", category: .contacts)
    }

    func resume() {
        guard operationQueue.isSuspended else { return }
        operationQueue.isSuspended = false
        SystemLogger.log(message: "queue resumed", category: .contacts)
    }

    func addTask(_ task: ContactTask) {
        guard hasBeenSetup else {
            SystemLogger.log(message: "queue setup() not called", category: .contacts, isError: true)
            return
        }
        serial.async { [weak self] in
            guard let self else {
                SystemLogger.log(message: "ContactsSyncQueue deallocated", category: .contacts, isError: true)
                return
            }
            taskQueue.append(task)
            updateProgressTotal(numAdded: task.numContacts)
            enqueueOperations([task])
        }
    }

    func saveQueueToDisk() {
        serial.sync {
            SystemLogger.log(message: "save contact sync queue to disk", category: .contacts)
            saveQueueWithoutThreadSafety()
        }
    }

    /// Stops the queue, deallocates all information from memory and deletes the persisted
    /// queue in the file system.
    func deleteQueue() {
        serial.sync {
            operationQueue.cancelAllOperations()
            taskQueue.removeAll()
            resetProgress()
            do {
                try fileManager.removeItem(at: taskQueueURL)
                SystemLogger.log(message: "queue file deleted", category: .contacts)
            } catch {
                SystemLogger.log(error: error, category: .contacts)
            }
        }
    }
}

// MARK: Private

extension ContactsSyncQueue {

    /// This functions serialises the queue to disk. The thread safety is not the responsability of this function, but
    /// it is of the functions calling it.
    private func saveQueueWithoutThreadSafety() {
        do {
            let data = try JSONEncoder().encode(taskQueue)
            try data.write(to: taskQueueURL)
        } catch {
            SystemLogger.log(error: error, category: .contacts)
        }
    }

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
        var progress = _progressPublisher.value
        if progress.total == 0 {
            SystemLogger.log(message: "tasks added to empty queue", category: .contacts)
        }
        progress.total += numAdded
        _progressPublisher.send(progress)
    }

    private func incrementProgress(_ increment: Int) {
        var progress = _progressPublisher.value
        progress.finished += increment
        if progress.finished >= progress.total {
            SystemLogger.log(message: "enqueued tasks finished", category: .contacts)
        }
        _progressPublisher.send(progress)
    }

    private func resetProgress() {
        _progressPublisher.send(Progress())
    }
}

// MARK: AsyncOperationDelegate

extension ContactsSyncQueue: AsyncOperationDelegate {

    func taskFinished(operation: AsyncOperation, error: Error?) {
        var hasReceivedAbort: Bool = false
        serial.sync {
            guard !operation.isCancelled else { return }
            guard let taskID = UUID(uuidString: operation.operationID) else { return }

            if let error = error as? NSError {
                let resolution = operationErrorHandler.onOperationError(error)
                logResolutionError(message: "Operation resolution \(resolution) for \(taskID)", error: error)

                switch resolution {
                case .skipTask:
                    removeFromTasksQueue(taskID: taskID)
                case .pauseQueue:
                    pause()
                    enqueueOperationAgain(taskID: taskID)
                case .abort:
                    hasReceivedAbort = true
                }
            } else {
                removeFromTasksQueue(taskID: taskID)
            }
        }

        if hasReceivedAbort {
            // we publish to obervers outside the serial queue to avoid potential deadlocks
            _protonStorageQuotaExceeded.send()
        }
    }

    private func logResolutionError(message: String, error: Error) {
        let message = """
        \(message).
        Internet status= \(dependencies.internetConnectionStatusProvider.status).
        Error = \(error).
        """
        SystemLogger.log(message: message, category: .contacts, isError: true)
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
        saveQueueWithoutThreadSafety()
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
