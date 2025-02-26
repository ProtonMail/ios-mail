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
import proton_app_uniffi
import InboxTesting
import UIKit
import XCTest

class BackgroundTransitionActionsExecutorTests: BaseTestCase {

    var sut: BackgroundTransitionActionsExecutor!
    var mailUserSessionSpy: MailUserSessionSpy!
    private var backgroundTransitionTaskSchedulerSpy: BackgroundTransitionTaskSchedulerSpy!

    override func setUp() {
        super.setUp()

        backgroundTransitionTaskSchedulerSpy = .init()
        mailUserSessionSpy = .init()
        sut = BackgroundTransitionActionsExecutor(
            userSession: { self.mailUserSessionSpy },
            backgroundTransitionTaskScheduler: backgroundTransitionTaskSchedulerSpy
        )
    }

    override func tearDown() {
        sut = nil
        mailUserSessionSpy = nil
        backgroundTransitionTaskSchedulerSpy = nil

        super.tearDown()
    }

    func test_WhenEnterBackgroundServiceIsCalled_ItExecutesPendingActions() {
        sut.enterBackgroundService()

        XCTAssertEqual(
            backgroundTransitionTaskSchedulerSpy.invokedBeginBackgroundTask,
            [BackgroundTransitionActionsExecutor.taskName]
        )
        // this will be reworked in https://protonag.atlassian.net/browse/ET-2226
//        XCTAssertEqual(mailUserSessionSpy.executePendingActionsInvokeCount, 1)
        XCTAssertEqual(backgroundTransitionTaskSchedulerSpy.invokedEndBackgroundTask.count, 1)
    }

}

private class BackgroundTransitionTaskSchedulerSpy: BackgroundTransitionTaskScheduler {

    private(set) var invokedEndBackgroundTask: [UIBackgroundTaskIdentifier] = []
    private(set) var invokedBeginBackgroundTask: [String?] = []

    // MARK: - BackgroundTransitionTaskScheduler

    func beginBackgroundTask(
        withName taskName: String?,
        expirationHandler handler: (@MainActor @Sendable () -> Void)?
    ) -> UIBackgroundTaskIdentifier {
        invokedBeginBackgroundTask.append(taskName)

        return UIBackgroundTaskIdentifier.invalid
    }
    
    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        self.invokedEndBackgroundTask.append(identifier)
    }

}
