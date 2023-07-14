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
import ProtonCore_DataModel
import UIKit

final class BackgroundTaskHelper: Service {
    private let dependencies: Dependencies
    private var currentBackgroundTask: BGTask?

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func registerBackgroundTask(
        scheduler: BGTaskSchedulerProtocol = BGTaskScheduler.shared
    ) {
        _ = Self.register(
            scheduler: scheduler,
            task: .encryptedSearchIndexing,
            handler: { [weak self] task in
                guard let self = self,
                      !self.dependencies.coreKeyMaker.isAppKeyEnabled,
                      !self.dependencies.usersManager.hasUsers(),
                      let activeUserID = self.dependencies.usersManager.firstUser?.userID else {
                    task.setTaskCompleted(success: true)
                    SystemLogger.log(message: "Background task can not continue: \(task.identifier)")
                    return
                }
                self.currentBackgroundTask = task
                task.expirationHandler = {
                    // Stop the index
                    self.dependencies.esService.pauseBuildingIndexInBackground(for: activeUserID)
                    SystemLogger.log(message: "Background task expired: \(task.identifier)")
                    self.currentBackgroundTask = nil
                }
                self.dependencies.esService.setBuildSearchIndexDelegate(for: activeUserID, delegate: self)
                self.dependencies.esService.startBuildingIndex(for: activeUserID)
            }
        )
    }

    func scheduleBackgroundProcessingIfNeeded(
        scheduler: BGTaskSchedulerProtocol = BGTaskScheduler.shared
    ) {
        guard
            UserInfo.isEncryptedSearchEnabled,
            !dependencies.coreKeyMaker.isAppKeyEnabled,
            dependencies.usersManager.hasUsers(),
            let activeUserID = dependencies.usersManager.firstUser?.userID,
            dependencies.esService.indexBuildingState(for: activeUserID) != .complete,
            dependencies.esService.indexBuildingState(for: activeUserID) != .disabled
        else {
            return
        }
        _ = Self.submit(scheduler: scheduler, task: .encryptedSearchIndexing)
    }

    // MARK: - class functions

    private class func makeRequest(for task: Task) -> BGTaskRequest {
        switch task {
        case .encryptedSearchIndexing:
            let request = BGProcessingTaskRequest(identifier: task.identifier)
            request.requiresNetworkConnectivity = true
            request.requiresExternalPower = true
            SystemLogger.log(message: "Make background processing task: \(task.identifier)", category: .backgroundTask)
            return request
        }
    }

    class func register(
        scheduler: BGTaskSchedulerProtocol = BGTaskScheduler.shared,
        task: Task,
        handler: @escaping (BGTask) -> Void
    ) -> Bool {
        return scheduler.register(
            forTaskWithIdentifier: task.identifier,
            using: nil
        ) { task in
            SystemLogger.log(message: "Background task starts: \(task.identifier)")
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
            SystemLogger.log(message: "Background task is scheduled: \(task.identifier)", category: .backgroundTask)
            return true
        } catch {
            SystemLogger.log(
                message: "Background task is failed to be scheduled: \(task.identifier), error: \(error)",
                category: .backgroundTask,
                isError: true
            )
            return false
        }
    }

    class func cancel(
        scheduler: BGTaskSchedulerProtocol = BGTaskScheduler.shared,
        task: Task
    ) {
        scheduler.cancel(taskRequestWithIdentifier: task.identifier)
    }
}

extension BackgroundTaskHelper: BuildSearchIndexDelegate {
    func indexBuildingStateDidChange(state: EncryptedSearchIndexState) {
        if state == .complete || state == .partial {
            currentBackgroundTask?.setTaskCompleted(success: true)
        }
    }

    func indexBuildingProgressUpdate(progress: BuildSearchIndexEstimatedProgress) {}
}

extension BackgroundTaskHelper {
    struct Dependencies {
        let coreKeyMaker: KeyMakerProtocol
        let esService: EncryptedSearchServiceProtocol
        let usersManager: UsersManagerProtocol
    }

    enum Task {
        case encryptedSearchIndexing

        var identifier: String {
            switch self {
            case .encryptedSearchIndexing:
                if UIApplication.isEnterprise {
                    return "com.protonmail.protonmail.encryptedsearch_indexbuilding"
                } else {
                    return "ch.protonmail.protonmail.encryptedsearch_indexbuilding"
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
