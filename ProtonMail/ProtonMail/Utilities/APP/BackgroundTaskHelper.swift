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

import BackgroundTasks
import Foundation
import ProtonCoreDataModel
import UIKit

protocol BackgroundTaskHelperProtocol {
    func registerBackgroundTask(scheduler: BGTaskSchedulerProtocol, task: BackgroundTaskHelper.Task)
    func scheduleBackgroundRefreshIfNeeded(scheduler: BGTaskSchedulerProtocol, task: BackgroundTaskHelper.Task)
}

final class BackgroundTaskHelper: BackgroundTaskHelperProtocol {
    private let dependencies: Dependencies
    private var currentBackgroundTask: BGTask?

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func registerBackgroundTask(scheduler: BGTaskSchedulerProtocol = BGTaskScheduler.shared, task: Task) {
        switch task {
        case .eventLoop:
            _ = Self.register(
                scheduler: scheduler,
                task: .eventLoop,
                handler: { task in
                    guard self.dependencies.coreKeyMaker.isAppKeyEnabled == false,
                          self.dependencies.usersManager.hasUsers(),
                          let activeUser = self.dependencies.usersManager.firstUser else {
                        task.setTaskCompleted(success: true)
                        Self.log(message: "Background task can not continue: \(task.identifier)")
                        return
                    }
                    self.currentBackgroundTask = task
                    task.expirationHandler = {
                        // Stop fetch event loop
                        Self.log(message: "Background task expired: \(task.identifier)")
                        self.currentBackgroundTask = nil
                    }
                    self.fetchEvents(user: activeUser)
                }
            )
        }
    }

    func scheduleBackgroundRefreshIfNeeded(
        scheduler: BGTaskSchedulerProtocol = BGTaskScheduler.shared,
        task: Task
    ) {
        guard
            !dependencies.coreKeyMaker.isAppKeyEnabled,
            dependencies.usersManager.hasUsers(),
            dependencies.usersManager.firstUser != nil
        else { return }
        switch task {
        case .eventLoop:
            _ = Self.submit(scheduler: scheduler, task: .eventLoop)
        }
    }

    // MARK: - class functions
    class func register(
        scheduler: BGTaskSchedulerProtocol = BGTaskScheduler.shared,
        task: Task,
        handler: @escaping (BGTask) -> Void
    ) -> Bool {
        return scheduler.register(
            forTaskWithIdentifier: task.identifier,
            using: nil
        ) { task in
            Self.log(message: "Background task starts: \(task.identifier)")
            handler(task)
        }
    }

    class func submit(
        scheduler: BGTaskSchedulerProtocol = BGTaskScheduler.shared,
        task: Task
    ) -> Bool {
        let request = makeRequest(for: task)
        do {
            try scheduler.submit(request)
            Self.log(message: "Background task is scheduled: \(task.identifier)")
            return true
        } catch {
            Self.log(
                message: "Background task is failed to be scheduled: \(task.identifier), error: \(error)",
                isError: true
            )
            return false
        }
    }

    private class func makeRequest(for task: Task) -> BGTaskRequest {
        switch task {
        case .eventLoop:
            let request = BGAppRefreshTaskRequest(identifier: task.identifier)
            Self.log(message: "Make background refresh task: \(task.identifier)")
            return request
        }
    }

    class func cancel(
        scheduler: BGTaskSchedulerProtocol = BGTaskScheduler.shared,
        task: Task
    ) {
        scheduler.cancel(taskRequestWithIdentifier: task.identifier)
    }

    private class func log(message: String, isError: Bool = false) {
        SystemLogger.log(message: message, category: .backgroundTask, isError: isError)
    }
}

extension BackgroundTaskHelper {
    private func fetchEvents(user: UserManager) {
        user.eventsService.fetchEvents(labelID: LabelLocation.inbox.labelID)
    }
}

extension BackgroundTaskHelper {
    struct Dependencies {
        let coreKeyMaker: KeyMakerProtocol
        let usersManager: UsersManagerProtocol
    }

    enum Task: String {
        case eventLoop

        // Needs to register this identifier in Info.plist
        var identifier: String {
            switch self {
            case .eventLoop:
                if UIApplication.isEnterprise {
                    return "com.protonmail.protonmail.eventloop"
                } else {
                    return "ch.protonmail.protonmail.eventloop"
                }
            }
        }
    }
}

// sourcery: mock
protocol BGTaskSchedulerProtocol {
    func submit(_ taskRequest: BGTaskRequest) throws
    func register(
        forTaskWithIdentifier identifier: String,
        using queue: DispatchQueue?,
        launchHandler: @escaping (BGTask) -> Void
    ) -> Bool
    func cancel(taskRequestWithIdentifier identifier: String)
}

extension BGTaskScheduler: BGTaskSchedulerProtocol {}
