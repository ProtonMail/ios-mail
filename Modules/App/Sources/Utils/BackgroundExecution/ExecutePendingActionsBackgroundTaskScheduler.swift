// Copyright (c) 2025 Proton Technologies AG
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
import InboxCore
import proton_app_uniffi

class MailUserSessionSpy: MailUserSessionProtocol {

    var pendingActionsExecutionResultStub = VoidSessionResult.ok
    var pollEventsResultStub = VoidEventResult.ok

    private(set) var pollEventInvokeCount = 0
    private(set) var executePendingActionsInvokeCount = 0

    // MARK: - MailUserSessionProtocol

    func pollEvents() async -> VoidEventResult {
        pollEventInvokeCount += 1

        return pollEventsResultStub
    }

    func executePendingActions() async -> VoidSessionResult {
        executePendingActionsInvokeCount += 1

        return pendingActionsExecutionResultStub
    }

    func accountDetails() async -> MailUserSessionAccountDetailsResult {
        fatalError()
    }
    
    func applicableLabels() async -> MailUserSessionApplicableLabelsResult {
        fatalError()
    }
    
    func connectionStatus() async -> MailUserSessionConnectionStatusResult {
        fatalError()
    }
    
    func executePendingAction() async -> VoidSessionResult {
        fatalError()
    }
    
    func fork() async -> MailUserSessionForkResult {
        fatalError()
    }
    
    func getAttachment(localAttachmentId: Id) async -> MailUserSessionGetAttachmentResult {
        fatalError()
    }
    
    func imageForSender(
        address: String,
        bimiSelector: String?,
        displaySenderImage: Bool,
        size: UInt32?,
        mode: String?,
        format: String?
    ) async -> MailUserSessionImageForSenderResult {
        fatalError()
    }
    
    func initialize(cb: any MailUserSessionInitializationCallback) async -> VoidSessionResult {
        fatalError()
    }
    
    func logout() async -> VoidSessionResult {
        fatalError()
    }
    
    func movableFolders() async -> MailUserSessionMovableFoldersResult {
        fatalError()
    }
    
    func observeEventLoopErrors(callback: any EventLoopErrorObserver) -> EventLoopErrorObserverHandle {
        fatalError()
    }

    func sessionId() -> String {
        fatalError()
    }
    
    func user() async -> MailUserSessionUserResult {
        fatalError()
    }
    
    func userId() -> String {
        fatalError()
    }

}

class ExecutePendingActionsBackgroundTaskScheduler {
    private static let identifier = "\(Bundle.defaultIdentifier).execute_pending_actions"
    private let userSession: () -> MailUserSessionProtocol?
    private let backgroundTaskRegistration: BackgroundTaskRegistration
    private let backgroundTaskScheduler: BackgroundTaskScheduler

    init(
        userSession: @escaping () -> MailUserSessionProtocol?,
        backgroundTaskRegistration: BackgroundTaskRegistration,
        backgroundTaskScheduler: BackgroundTaskScheduler
    ) {
        self.userSession = userSession
        self.backgroundTaskRegistration = backgroundTaskRegistration
        self.backgroundTaskScheduler = backgroundTaskScheduler
    }

    func register() {
        let isTaskDefinedInInfoPlist = backgroundTaskRegistration.registerWithIdentifier(
            Self.identifier,
            nil
        ) { [weak self] task in
            BackgroundEventsLogging.log("🎬 Task execution started")
            self?.execute(task: task)
        }
        if !isTaskDefinedInInfoPlist {
            BackgroundEventsLogging.log("📓 Missing background task identifier: <\(Self.identifier)> in the Info.plist file.")
            fatalError("Missing background task identifier: <\(Self.identifier)> in the Info.plist file.")
        }
        BackgroundEventsLogging.log("📓 Task with identifier: <\(Self.identifier)> registered.")
    }

    func submit() {
        let request = BGProcessingTaskRequest(identifier: Self.identifier)
        request.requiresExternalPower = false
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = DateEnvironment.currentDate().fifteenMinutesAfter
        do {
            try backgroundTaskScheduler.submit(request)
            BackgroundEventsLogging.log("🚀 Task submitted")
        } catch {
            BackgroundEventsLogging.log("👎🏻 Task submission failure: \(error)")
        }
    }

    // MARK: - Private

    private func execute(task: BackgroundTask) {
        guard let session = userSession() else {
            BackgroundEventsLogging.log("👋🏻 No session - complete the task")
            task.setTaskCompleted(success: true)
            return
        }
        let startTime = CFAbsoluteTimeGetCurrent()
        submit()

        func executionTime() {
            let endTime = CFAbsoluteTimeGetCurrent()
            let executionTime = endTime - startTime
        }

        task.expirationHandler = {
            BackgroundEventsLogging.log("⏰ Expiration handler called, time of execution: \(executionTime()) seconds")
            task.setTaskCompleted(success: true)
        }

        Task {
            BackgroundEventsLogging.log("🕺 Execute pending actions called")
            switch await session.executePendingActions() {
            case .ok:
                BackgroundEventsLogging.log("✅ Execute pending actions finished with success after: \(executionTime()) seconds")
            case .error(let error):
                BackgroundEventsLogging.log("❌ Execute pending actions finished with failure after: \(executionTime()) seconds")
            }

            switch await session.pollEvents() {
            case .ok:
                BackgroundEventsLogging.log("✅ Poll events finished with success after: \(executionTime()) seconds")
                task.setTaskCompleted(success: true)
            case .error(let eventError):
                BackgroundEventsLogging.log("❌ Poll events finished with failure after: \(executionTime()) seconds")
                task.setTaskCompleted(success: false)
            }
        }
    }

}

extension Date {
    var fifteenMinutesAfter: Self {
        DateEnvironment.calendar.date(byAdding: .minute, value: 15, to: self).unsafelyUnwrapped
    }
}
