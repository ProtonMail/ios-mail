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

@testable import ProtonMail
import InboxTesting
import XCTest

// FIXME: - Add missing tests later

//class BackgroundTransitionActionsExecutorTests: BaseTestCase {
//
//    var sut: BackgroundTransitionActionsExecutor!
//    var backgroundTransitionTaskSchedulerSpy: BackgroundTransitionTaskSchedulerSpy!
//    var mailUserSessionSpy: MailUserSessionSpy!
//    var notificationSchedullerSpy: NotificationSchedullerSpy!
//    private var backgroundTaskExecutorSpy: BackgroundTaskExecutorSpy!
//
//    override func setUp() {
//        super.setUp()
//
//        backgroundTransitionTaskSchedulerSpy = .init()
//        backgroundTaskExecutorSpy = .init()
//        mailUserSessionSpy = .init()
//        notificationSchedullerSpy = .init()
//        sut = BackgroundTransitionActionsExecutor(
//            backgroundTransitionTaskScheduler: backgroundTransitionTaskSchedulerSpy,
//            backgroundTaskExecutor: backgroundTaskExecutorSpy,
//            notificationScheduller: notificationSchedullerSpy,
//            actionQueueStatusProvider: { self.mailUserSessionSpy }
//        )
//    }
//
//    override func tearDown() {
//        backgroundTransitionTaskSchedulerSpy = nil
//        backgroundTaskExecutorSpy = nil
//        mailUserSessionSpy = nil
//        notificationSchedullerSpy = nil
//        sut = nil
//
//        super.tearDown()
//    }
//
//    func test_backgroundTaskWhenUserEntersBackgroundAndQueueProcessAllActionsWithSuccess() {
//        backgroundTaskExecutorSpy.areSendingActionsInActionQueueStub = []
//        mailUserSessionSpy.draftSendResultUnseenResultStub = .ok([])
//        mailUserSessionSpy.connectionStatusStub = .ok(.online)
//
//        sut.enterBackgroundService()
//
//        XCTAssertEqual(backgroundTaskExecutorSpy.invokedStartExecuteInBackground.count, 1)
//        XCTAssertEqual(backgroundTaskExecutorSpy.handlerSpy.abortInvokeCount, 1)
//        XCTAssertEqual(backgroundTransitionTaskSchedulerSpy.invokedEndBackgroundTask.count, 1)
//        XCTAssertEqual(notificationSchedullerSpy.schedulledNotifications.count, 0)
//    }
//
//}
//
//extension MailUserSessionSpy: ConnectionStatusProvider, ActiveAccountSendingStatusChecker {}
//
//import proton_app_uniffi
//
//class StartBackgroundExecutionHandlerSpy: StartBackgroundExecutionHandler {
//
//    private(set) var abortInvokeCount = 0
//
//    override func abort() {
//        abortInvokeCount += 1
//    }
//
//}
//
//private class BackgroundTaskExecutorSpy: BackgroundTaskExecutor {
//
//    let handlerSpy = StartBackgroundExecutionHandlerSpy()
//    var areSendingActionsInActionQueueStub: [ID] = []
//    private(set) var invokedStartExecuteInBackground: [LiveQueryCallback] = []
//
//    func startExecuteInBackground(callback: LiveQueryCallback) async -> StartBackgroundExecutionHandler {
//        invokedStartExecuteInBackground.append(callback)
//
//        return handlerSpy
//    }
//    
//    func areSendingActionsInActionQueue() async -> [ID] {
//        areSendingActionsInActionQueueStub
//    }
//
//}
//
//import UserNotifications
//
//class NotificationSchedullerSpy: NotificationScheduller {
//
//    private(set) var schedulledNotifications: [UNNotificationRequest] = []
//
//    func add(_ request: UNNotificationRequest) async throws {
//        schedulledNotifications.append(request)
//    }
//
//}
