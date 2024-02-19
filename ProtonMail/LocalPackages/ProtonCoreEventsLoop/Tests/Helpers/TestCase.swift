// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Technologies AG and ProtonCore.
//
// ProtonCore is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonCore is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonCore. If not, see https://www.gnu.org/licenses/.

@testable import ProtonCoreEventsLoop
import XCTest

class TestCase: XCTestCase {

    var originalCurrentDate: (() -> Date)!
    var originalMainSchedulerOperationQueueFactory: (() -> OperationQueue)!
    var originalLoopOperationQueueFactory: (() -> OperationQueue)!
    var originalTimerScheduler: TimerScheduler!

    override open func setUp() {
        super.setUp()

        originalCurrentDate = Environment.currentDate
        originalMainSchedulerOperationQueueFactory = Environment.mainSchedulerOperationQueueFactory
        originalLoopOperationQueueFactory = Environment.loopOperationQueueFactory
        originalTimerScheduler = Environment.timerScheduler

        Environment.currentDate = { .init() }
        Environment.mainSchedulerOperationQueueFactory = { SynchronousOperationQueueFixture() }
        Environment.loopOperationQueueFactory = { ImmediateOperationQueue() }
        Environment.timerScheduler = TimerSchedulerSpy()
    }

    override open func tearDown() {
        super.tearDown()

        Environment.currentDate = originalCurrentDate
        Environment.mainSchedulerOperationQueueFactory = originalMainSchedulerOperationQueueFactory
        Environment.loopOperationQueueFactory = originalLoopOperationQueueFactory
        Environment.timerScheduler = originalTimerScheduler

        originalCurrentDate = nil
        originalMainSchedulerOperationQueueFactory = nil
        originalLoopOperationQueueFactory = nil
        originalTimerScheduler = nil
    }

}
