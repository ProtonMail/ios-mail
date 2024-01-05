// Copyright (c) 2022 Proton Technologies AG
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

class EventsPeriodicSchedulerTests: TestCase {

    var sut: EventsPeriodicScheduler<CoreLoopSpy, SpecialLoopSpy>!
    var eventsPeriodicSchedulerQueue: SynchronousOperationQueueFixture!
    var operationQueues: [OperationQueue]!
    var timerScheduler: TimerSchedulerSpy!
    var coreLoopFactory: CoreLoopFactorySpy!
    var specialLoopFactory: SpecialLoopFactorySpy!
    var currentDate: Date!

    override func setUp() {
        super.setUp()

        operationQueues = []
        coreLoopFactory = .init()
        specialLoopFactory = .init()
        currentDate = .init()
        timerScheduler = TimerSchedulerSpy()
        eventsPeriodicSchedulerQueue = .init()

        Environment.currentDate = { self.currentDate }
        Environment.timerScheduler = timerScheduler
        Environment.mainSchedulerOperationQueueFactory = { self.eventsPeriodicSchedulerQueue }
        Environment.loopOperationQueueFactory = {
            let queue = ImmediateOperationQueue()
            self.operationQueues.append(queue)
            return queue
        }

        sut = .init(
            coreLoopFactory: .init(coreLoopFactory),
            specialLoopFactory: .init(specialLoopFactory)
        )
    }

    override func tearDown() {
        eventsPeriodicSchedulerQueue = nil
        currentDate = nil
        specialLoopFactory = nil
        coreLoopFactory = nil
        timerScheduler = nil
        operationQueues = nil
        sut = nil
        super.tearDown()
    }

    func testConfiguresQueuesAsSerialQueuesWithUtilityMode() {
        XCTAssertEqual(allQueues.allSatisfy { $0.maxConcurrentOperationCount == 1 }, true)
        XCTAssertEqual(allQueues.allSatisfy { $0.qualityOfService == .utility }, true)
    }

    func testDoesNotCreateAnyLoopsYet() {
        XCTAssertEqual(coreLoopFactory.createdLoops.isEmpty, true)
        XCTAssertEqual(specialLoopFactory.createdLoops.value.isEmpty, true)
    }

    func testStart_SchedulesTimerWithCorrectTimeIntervalAndCommonModeOnce() {
        sut.start()

        XCTAssertEqual(timerScheduler.addCalls.count, 1)
        XCTAssertEqual(timerScheduler.addCalls.last?.timer.timeInterval, 60)
        XCTAssertEqual(timerScheduler.addCalls.last?.timer.isValid, true)
        XCTAssertEqual(timerScheduler.addCalls.last?.timer.fireDate, currentDate)
        XCTAssertEqual(timerScheduler.addCalls.last?.mode, .common)
    }

    func testStartAndSuspend_InvalidatesTimer() {
        sut.start()
        sut.suspend()

        XCTAssertEqual(timerScheduler.addCalls.last?.timer.isValid, false)
    }

    func testStartAndSuspend_SuspendsOperationQueue() {
        sut.start()
        sut.suspend()

        XCTAssertEqual(allQueues.allSatisfy { $0.isSuspended }, true)
    }

    func testEnableOneCoreLoopAndTwoCalendarLoops_CreatesOneCoreLoopAndTwoSpecialLoops() throws {
        sut.enableCoreLoop(forUserID: "<test_user_id_1>")
        sut.enableSpecialLoop(forSpecialLoopID: "<test_special_loop_id_1>")
        sut.enableSpecialLoop(forSpecialLoopID: "<test_special_loop_id_2>")

        try configureLatestEventIDs()

        XCTAssertEqual(coreLoopFactory.createdLoops.count, 1)
        XCTAssertEqual(specialLoopFactory.createdLoops.value.count, 2)

        XCTAssertEqual(coreLoopFactory.createdLoops.map(\.loopID), ["<test_user_id_1>"])
        XCTAssertEqual(coreLoopFactory.createdLoops.map(\.latestEventID), ["core_event_id_#0"])

        XCTAssertEqual(specialLoopFactory.createdLoops.value.map(\.loopID), ["<test_special_loop_id_1>", "<test_special_loop_id_2>"])
        XCTAssertEqual(specialLoopFactory.createdLoops.value.map(\.latestEventID), ["1st_special_event_id_#0", "2nd_special_event_id_#0"])
    }

    func testStart_DoesNotSchedulesAnyOperations() throws {
        try enableCoreLoopAndTwoSpecialLoops()

        sut.start()

        let coreLoop = try firstCoreLoop()
        let firstSpecialLoop = try firstSpecialLoop()
        let secondSpecialLoop = try secondSpecialLoop()

        XCTAssertEqual(coreLoop.recordedEvents, [])
        XCTAssertEqual(firstSpecialLoop.recordedEvents, [])
        XCTAssertEqual(secondSpecialLoop.recordedEvents, [])
    }

    func testTriggerSpecialLoop_ItTriggersEventsOnlyForCoreLoopAndSpecialLoopWithGivenID() throws {
        try enableCoreLoopAndTwoSpecialLoops()

        sut.start()

        let coreLoop = try firstCoreLoop()
        let firstSpecialLoop = try firstSpecialLoop()
        let secondSpecialLoop = try secondSpecialLoop()

        simulateTickAndFinish()

        sut.triggerSpecialLoop(forSpecialLoopID: firstSpecialLoop.loopID)

        finishAllOperations()

        XCTAssertEqual(coreLoop.recordedEvents, [
            .startedPolling(eventID: "core_event_id_#0"),
            .finishedPolling(eventID: "core_event_id_#0_#1", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "core_event_id_#0_#1"),
            .finishedProcessing(eventID: "core_event_id_#0_#1"),

            .startedPolling(eventID: "core_event_id_#0_#1"),
            .finishedPolling(eventID: "core_event_id_#0_#1_#2", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "core_event_id_#0_#1_#2"),
            .finishedProcessing(eventID: "core_event_id_#0_#1_#2")
        ])
        XCTAssertEqual(coreLoop.latestEventID, "core_event_id_#0_#1_#2")

        XCTAssertEqual(firstSpecialLoop.recordedEvents, [
            .startedPolling(eventID: "1st_special_event_id_#0"),
            .finishedPolling(eventID: "1st_special_event_id_#0_#1", requiresClearCache: false, hasMorePages: true),
            .startedProcessing(eventID: "1st_special_event_id_#0_#1"),
            .finishedProcessing(eventID: "1st_special_event_id_#0_#1"),

            .startedPolling(eventID: "1st_special_event_id_#0_#1"),
            .finishedPolling(eventID: "1st_special_event_id_#0_#1_#2", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "1st_special_event_id_#0_#1_#2"),
            .finishedProcessing(eventID: "1st_special_event_id_#0_#1_#2"),

            .startedPolling(eventID: "1st_special_event_id_#0_#1_#2"),
            .finishedPolling(eventID: "1st_special_event_id_#0_#1_#2_#3", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "1st_special_event_id_#0_#1_#2_#3"),
            .finishedProcessing(eventID: "1st_special_event_id_#0_#1_#2_#3")
        ])
        XCTAssertEqual(firstSpecialLoop.latestEventID, "1st_special_event_id_#0_#1_#2_#3")

        XCTAssertEqual(secondSpecialLoop.recordedEvents, [
            .startedPolling(eventID: "2nd_special_event_id_#0"),
            .finishedPolling(eventID: "2nd_special_event_id_#0_#1", requiresClearCache: false, hasMorePages: true),
            .startedProcessing(eventID: "2nd_special_event_id_#0_#1"),
            .finishedProcessing(eventID: "2nd_special_event_id_#0_#1"),

            .startedPolling(eventID: "2nd_special_event_id_#0_#1"),
            .finishedPolling(eventID: "2nd_special_event_id_#0_#1_#2", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "2nd_special_event_id_#0_#1_#2"),
            .finishedProcessing(eventID: "2nd_special_event_id_#0_#1_#2")
        ])
        XCTAssertEqual(secondSpecialLoop.latestEventID, "2nd_special_event_id_#0_#1_#2")
    }

    func testTriggerSpecialLoop_TimerTicksAfterSpecialLoopTrigger_ItTriggersEventsForAllEnabledLoops() throws {
        try enableCoreLoopAndTwoSpecialLoops()

        sut.start()

        let coreLoop = try firstCoreLoop()
        let firstSpecialLoop = try firstSpecialLoop()
        let secondSpecialLoop = try secondSpecialLoop()

        simulateTickAndFinish()

        sut.triggerSpecialLoop(forSpecialLoopID: firstSpecialLoop.loopID)

        finishAllOperations()

        XCTAssertFalse(secondSpecialLoop.recordedEvents.isEmpty)
        XCTAssertEqual(secondSpecialLoop.latestEventID, "2nd_special_event_id_#0_#1_#2")

        simulateTickAndFinish()

        XCTAssertEqual(coreLoop.recordedEvents, [
            .startedPolling(eventID: "core_event_id_#0"),
            .finishedPolling(eventID: "core_event_id_#0_#1", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "core_event_id_#0_#1"),
            .finishedProcessing(eventID: "core_event_id_#0_#1"),

            .startedPolling(eventID: "core_event_id_#0_#1"),
            .finishedPolling(eventID: "core_event_id_#0_#1_#2", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "core_event_id_#0_#1_#2"),
            .finishedProcessing(eventID: "core_event_id_#0_#1_#2"),

            .startedPolling(eventID: "core_event_id_#0_#1_#2"),
            .finishedPolling(eventID: "core_event_id_#0_#1_#2_#3", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "core_event_id_#0_#1_#2_#3"),
            .finishedProcessing(eventID: "core_event_id_#0_#1_#2_#3")
        ])
        XCTAssertEqual(coreLoop.latestEventID, "core_event_id_#0_#1_#2_#3")

        XCTAssertEqual(firstSpecialLoop.recordedEvents, [
            .startedPolling(eventID: "1st_special_event_id_#0"),
            .finishedPolling(eventID: "1st_special_event_id_#0_#1", requiresClearCache: false, hasMorePages: true),
            .startedProcessing(eventID: "1st_special_event_id_#0_#1"),
            .finishedProcessing(eventID: "1st_special_event_id_#0_#1"),

            .startedPolling(eventID: "1st_special_event_id_#0_#1"),
            .finishedPolling(eventID: "1st_special_event_id_#0_#1_#2", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "1st_special_event_id_#0_#1_#2"),
            .finishedProcessing(eventID: "1st_special_event_id_#0_#1_#2"),

            .startedPolling(eventID: "1st_special_event_id_#0_#1_#2"),
            .finishedPolling(eventID: "1st_special_event_id_#0_#1_#2_#3", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "1st_special_event_id_#0_#1_#2_#3"),
            .finishedProcessing(eventID: "1st_special_event_id_#0_#1_#2_#3"),

            .startedPolling(eventID: "1st_special_event_id_#0_#1_#2_#3"),
            .finishedPolling(eventID: "1st_special_event_id_#0_#1_#2_#3_#4", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "1st_special_event_id_#0_#1_#2_#3_#4"),
            .finishedProcessing(eventID: "1st_special_event_id_#0_#1_#2_#3_#4")
        ])
        XCTAssertEqual(firstSpecialLoop.latestEventID, "1st_special_event_id_#0_#1_#2_#3_#4")

        XCTAssertEqual(secondSpecialLoop.recordedEvents, [
            .startedPolling(eventID: "2nd_special_event_id_#0"),
            .finishedPolling(eventID: "2nd_special_event_id_#0_#1", requiresClearCache: false, hasMorePages: true),
            .startedProcessing(eventID: "2nd_special_event_id_#0_#1"),
            .finishedProcessing(eventID: "2nd_special_event_id_#0_#1"),

            .startedPolling(eventID: "2nd_special_event_id_#0_#1"),
            .finishedPolling(eventID: "2nd_special_event_id_#0_#1_#2", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "2nd_special_event_id_#0_#1_#2"),
            .finishedProcessing(eventID: "2nd_special_event_id_#0_#1_#2"),

            .startedPolling(eventID: "2nd_special_event_id_#0_#1_#2"),
            .finishedPolling(eventID: "2nd_special_event_id_#0_#1_#2_#3", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "2nd_special_event_id_#0_#1_#2_#3"),
            .finishedProcessing(eventID: "2nd_special_event_id_#0_#1_#2_#3")
        ])
        XCTAssertEqual(secondSpecialLoop.latestEventID, "2nd_special_event_id_#0_#1_#2_#3")
    }

    func testTriggerCoreLoop_ItTriggersEventsOnlyForCoreLoop() throws {
        try enableCoreLoopAndTwoSpecialLoops()

        sut.start()

        let coreLoop = try firstCoreLoop()
        let firstSpecialLoop = try firstSpecialLoop()
        let secondSpecialLoop = try secondSpecialLoop()

        simulateTickAndFinish()

        sut.triggerCoreLoop()

        finishAllOperations()

        XCTAssertEqual(coreLoop.recordedEvents, [
            .startedPolling(eventID: "core_event_id_#0"),
            .finishedPolling(eventID: "core_event_id_#0_#1", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "core_event_id_#0_#1"),
            .finishedProcessing(eventID: "core_event_id_#0_#1"),

            .startedPolling(eventID: "core_event_id_#0_#1"),
            .finishedPolling(eventID: "core_event_id_#0_#1_#2", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "core_event_id_#0_#1_#2"),
            .finishedProcessing(eventID: "core_event_id_#0_#1_#2")
        ])
        XCTAssertEqual(coreLoop.latestEventID, "core_event_id_#0_#1_#2")

        XCTAssertEqual(firstSpecialLoop.recordedEvents, [
            .startedPolling(eventID: "1st_special_event_id_#0"),
            .finishedPolling(eventID: "1st_special_event_id_#0_#1", requiresClearCache: false, hasMorePages: true),
            .startedProcessing(eventID: "1st_special_event_id_#0_#1"),
            .finishedProcessing(eventID: "1st_special_event_id_#0_#1"),

            .startedPolling(eventID: "1st_special_event_id_#0_#1"),
            .finishedPolling(eventID: "1st_special_event_id_#0_#1_#2", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "1st_special_event_id_#0_#1_#2"),
            .finishedProcessing(eventID: "1st_special_event_id_#0_#1_#2")
        ])
        XCTAssertEqual(firstSpecialLoop.latestEventID, "1st_special_event_id_#0_#1_#2")

        XCTAssertEqual(secondSpecialLoop.recordedEvents, [
            .startedPolling(eventID: "2nd_special_event_id_#0"),
            .finishedPolling(eventID: "2nd_special_event_id_#0_#1", requiresClearCache: false, hasMorePages: true),
            .startedProcessing(eventID: "2nd_special_event_id_#0_#1"),
            .finishedProcessing(eventID: "2nd_special_event_id_#0_#1"),

            .startedPolling(eventID: "2nd_special_event_id_#0_#1"),
            .finishedPolling(eventID: "2nd_special_event_id_#0_#1_#2", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "2nd_special_event_id_#0_#1_#2"),
            .finishedProcessing(eventID: "2nd_special_event_id_#0_#1_#2")
        ])
        XCTAssertEqual(secondSpecialLoop.latestEventID, "2nd_special_event_id_#0_#1_#2")
    }

    func testTriggerCoreLoop_TimerTicksAfterCoreLoopTrigger_ItTriggersEventsForAllEnabledLoops() throws {
        try enableCoreLoopAndTwoSpecialLoops()

        sut.start()

        let coreLoop = try firstCoreLoop()
        let firstSpecialLoop = try firstSpecialLoop()
        let secondSpecialLoop = try secondSpecialLoop()

        simulateTickAndFinish()

        sut.triggerCoreLoop()

        finishAllOperations()

        XCTAssertFalse(secondSpecialLoop.recordedEvents.isEmpty)
        XCTAssertEqual(secondSpecialLoop.latestEventID, "2nd_special_event_id_#0_#1_#2")

        simulateTickAndFinish()

        XCTAssertEqual(coreLoop.recordedEvents, [
            .startedPolling(eventID: "core_event_id_#0"),
            .finishedPolling(eventID: "core_event_id_#0_#1", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "core_event_id_#0_#1"),
            .finishedProcessing(eventID: "core_event_id_#0_#1"),

            .startedPolling(eventID: "core_event_id_#0_#1"),
            .finishedPolling(eventID: "core_event_id_#0_#1_#2", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "core_event_id_#0_#1_#2"),
            .finishedProcessing(eventID: "core_event_id_#0_#1_#2"),

            .startedPolling(eventID: "core_event_id_#0_#1_#2"),
            .finishedPolling(eventID: "core_event_id_#0_#1_#2_#3", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "core_event_id_#0_#1_#2_#3"),
            .finishedProcessing(eventID: "core_event_id_#0_#1_#2_#3")
        ])
        XCTAssertEqual(coreLoop.latestEventID, "core_event_id_#0_#1_#2_#3")

        XCTAssertEqual(firstSpecialLoop.recordedEvents, [
            .startedPolling(eventID: "1st_special_event_id_#0"),
            .finishedPolling(eventID: "1st_special_event_id_#0_#1", requiresClearCache: false, hasMorePages: true),
            .startedProcessing(eventID: "1st_special_event_id_#0_#1"),
            .finishedProcessing(eventID: "1st_special_event_id_#0_#1"),

            .startedPolling(eventID: "1st_special_event_id_#0_#1"),
            .finishedPolling(eventID: "1st_special_event_id_#0_#1_#2", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "1st_special_event_id_#0_#1_#2"),
            .finishedProcessing(eventID: "1st_special_event_id_#0_#1_#2"),

            .startedPolling(eventID: "1st_special_event_id_#0_#1_#2"),
            .finishedPolling(eventID: "1st_special_event_id_#0_#1_#2_#3", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "1st_special_event_id_#0_#1_#2_#3"),
            .finishedProcessing(eventID: "1st_special_event_id_#0_#1_#2_#3")
        ])
        XCTAssertEqual(firstSpecialLoop.latestEventID, "1st_special_event_id_#0_#1_#2_#3")

        XCTAssertEqual(secondSpecialLoop.recordedEvents, [
            .startedPolling(eventID: "2nd_special_event_id_#0"),
            .finishedPolling(eventID: "2nd_special_event_id_#0_#1", requiresClearCache: false, hasMorePages: true),
            .startedProcessing(eventID: "2nd_special_event_id_#0_#1"),
            .finishedProcessing(eventID: "2nd_special_event_id_#0_#1"),

            .startedPolling(eventID: "2nd_special_event_id_#0_#1"),
            .finishedPolling(eventID: "2nd_special_event_id_#0_#1_#2", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "2nd_special_event_id_#0_#1_#2"),
            .finishedProcessing(eventID: "2nd_special_event_id_#0_#1_#2"),

            .startedPolling(eventID: "2nd_special_event_id_#0_#1_#2"),
            .finishedPolling(eventID: "2nd_special_event_id_#0_#1_#2_#3", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "2nd_special_event_id_#0_#1_#2_#3"),
            .finishedProcessing(eventID: "2nd_special_event_id_#0_#1_#2_#3")
        ])
        XCTAssertEqual(secondSpecialLoop.latestEventID, "2nd_special_event_id_#0_#1_#2_#3")
    }

    func testStartAndSuspend_TimerTicksOnce_DoesNotSchedulesAnyOperations() throws {
        try enableCoreLoopAndTwoSpecialLoops()

        sut.start()
        sut.suspend()

        let coreLoop = try firstCoreLoop()
        let firstSpecialLoop = try firstSpecialLoop()
        let secondSpecialLoop = try secondSpecialLoop()

        simulateTickAndFinish()

        XCTAssertEqual(coreLoop.recordedEvents, [])
        XCTAssertEqual(firstSpecialLoop.recordedEvents, [])
        XCTAssertEqual(secondSpecialLoop.recordedEvents, [])
    }

    func testStartSuspendAndStartAgain_TimerTicksOnce_SchedulesOperations() throws {
        try enableCoreLoopAndTwoSpecialLoops()

        sut.start()
        sut.suspend()
        sut.start()

        let coreLoop = try firstCoreLoop()
        let firstSpecialLoop = try firstSpecialLoop()
        let secondSpecialLoop = try secondSpecialLoop()

        simulateTickAndFinish()

        XCTAssertEqual(coreLoop.recordedEvents.isEmpty, false)

        XCTAssertEqual(firstSpecialLoop.recordedEvents.isEmpty, false)
        XCTAssertEqual(secondSpecialLoop.recordedEvents.isEmpty, false)
    }

    func testStartAndReset_TimerTicksOnce_DoesNotSchedulesAnyOperations() throws {
        try enableCoreLoopAndTwoSpecialLoops()

        sut.start()
        sut.reset()

        let coreLoop = try firstCoreLoop()
        let firstSpecialLoop = try firstSpecialLoop()
        let secondSpecialLoop = try secondSpecialLoop()

        simulateTickAndFinish()

        XCTAssertEqual(coreLoop.recordedEvents, [])
        XCTAssertEqual(firstSpecialLoop.recordedEvents, [])
        XCTAssertEqual(secondSpecialLoop.recordedEvents, [])
    }

    func testStartResetAndStartAgain_TimerTicksOnce_SchedulesOnlyCoreEventLoopOperations() throws {
        try enableCoreLoopAndTwoSpecialLoops()

        sut.start()
        sut.reset()
        sut.start()

        let coreLoop = try firstCoreLoop()
        let firstSpecialLoop = try firstSpecialLoop()
        let secondSpecialLoop = try secondSpecialLoop()

        simulateTickAndFinish()

        XCTAssertEqual(coreLoop.recordedEvents, [
            .startedPolling(eventID: "core_event_id_#0"),
            .finishedPolling(eventID: "core_event_id_#0_#1", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "core_event_id_#0_#1"),
            .finishedProcessing(eventID: "core_event_id_#0_#1")
        ])
        XCTAssertEqual(firstSpecialLoop.recordedEvents, [])
        XCTAssertEqual(secondSpecialLoop.recordedEvents, [])
    }

    func testStart_TimerTicksOnce_SchedulesAndExecutesAllOperations() throws {
        try enableCoreLoopAndTwoSpecialLoops()

        sut.start()

        let coreLoop = try firstCoreLoop()
        let firstSpecialLoop = try firstSpecialLoop()
        let secondSpecialLoop = try secondSpecialLoop()

        simulateTickAndFinish()

        XCTAssertEqual(coreLoop.recordedEvents, [
            .startedPolling(eventID: "core_event_id_#0"),
            .finishedPolling(eventID: "core_event_id_#0_#1", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "core_event_id_#0_#1"),
            .finishedProcessing(eventID: "core_event_id_#0_#1")
        ])
        XCTAssertEqual(coreLoop.latestEventID, "core_event_id_#0_#1")

        XCTAssertEqual(firstSpecialLoop.recordedEvents, [
            .startedPolling(eventID: "1st_special_event_id_#0"),
            .finishedPolling(eventID: "1st_special_event_id_#0_#1", requiresClearCache: false, hasMorePages: true),
            .startedProcessing(eventID: "1st_special_event_id_#0_#1"),
            .finishedProcessing(eventID: "1st_special_event_id_#0_#1"),
            .startedPolling(eventID: "1st_special_event_id_#0_#1"),
            .finishedPolling(eventID: "1st_special_event_id_#0_#1_#2", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "1st_special_event_id_#0_#1_#2"),
            .finishedProcessing(eventID: "1st_special_event_id_#0_#1_#2")
        ])
        XCTAssertEqual(firstSpecialLoop.latestEventID, "1st_special_event_id_#0_#1_#2")

        XCTAssertEqual(secondSpecialLoop.recordedEvents, [
            .startedPolling(eventID: "2nd_special_event_id_#0"),
            .finishedPolling(eventID: "2nd_special_event_id_#0_#1", requiresClearCache: false, hasMorePages: true),
            .startedProcessing(eventID: "2nd_special_event_id_#0_#1"),
            .finishedProcessing(eventID: "2nd_special_event_id_#0_#1"),
            .startedPolling(eventID: "2nd_special_event_id_#0_#1"),
            .finishedPolling(eventID: "2nd_special_event_id_#0_#1_#2", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "2nd_special_event_id_#0_#1_#2"),
            .finishedProcessing(eventID: "2nd_special_event_id_#0_#1_#2")
        ])
        XCTAssertEqual(secondSpecialLoop.latestEventID, "2nd_special_event_id_#0_#1_#2")
    }

    func testStart_TimerTicksTwice_SchedulesAndExecutesAllOperationsOnlyOnce() throws {
        try enableCoreLoopAndTwoSpecialLoops()

        sut.start()

        let coreLoop = try firstCoreLoop()
        let firstSpecialLoop = try firstSpecialLoop()
        let secondSpecialLoop = try secondSpecialLoop()

        timerScheduler.simulateTick()
        timerScheduler.simulateTick()

        finishAllOperations()

        XCTAssertEqual(coreLoop.recordedEvents, [
            .startedPolling(eventID: "core_event_id_#0"),
            .finishedPolling(eventID: "core_event_id_#0_#1", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "core_event_id_#0_#1"),
            .finishedProcessing(eventID: "core_event_id_#0_#1")
        ])
        XCTAssertEqual(coreLoop.latestEventID, "core_event_id_#0_#1")

        XCTAssertEqual(firstSpecialLoop.recordedEvents, [
            .startedPolling(eventID: "1st_special_event_id_#0"),
            .finishedPolling(eventID: "1st_special_event_id_#0_#1", requiresClearCache: false, hasMorePages: true),
            .startedProcessing(eventID: "1st_special_event_id_#0_#1"),
            .finishedProcessing(eventID: "1st_special_event_id_#0_#1"),
            .startedPolling(eventID: "1st_special_event_id_#0_#1"),
            .finishedPolling(eventID: "1st_special_event_id_#0_#1_#2", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "1st_special_event_id_#0_#1_#2"),
            .finishedProcessing(eventID: "1st_special_event_id_#0_#1_#2")
        ])
        XCTAssertEqual(firstSpecialLoop.latestEventID, "1st_special_event_id_#0_#1_#2")

        XCTAssertEqual(secondSpecialLoop.recordedEvents, [
            .startedPolling(eventID: "2nd_special_event_id_#0"),
            .finishedPolling(eventID: "2nd_special_event_id_#0_#1", requiresClearCache: false, hasMorePages: true),
            .startedProcessing(eventID: "2nd_special_event_id_#0_#1"),
            .finishedProcessing(eventID: "2nd_special_event_id_#0_#1"),
            .startedPolling(eventID: "2nd_special_event_id_#0_#1"),
            .finishedPolling(eventID: "2nd_special_event_id_#0_#1_#2", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "2nd_special_event_id_#0_#1_#2"),
            .finishedProcessing(eventID: "2nd_special_event_id_#0_#1_#2")
        ])
        XCTAssertEqual(secondSpecialLoop.latestEventID, "2nd_special_event_id_#0_#1_#2")
    }

    func testCoreLoopNotifiesAboutStoppingSpecialLoop_ExecutesCoreOperationsAndCancelAllOperationsForOneSpecialLoop() throws {
        sut.enableCoreLoop(forUserID: "<test_user_id_100>")
        sut.enableSpecialLoop(forSpecialLoopID: "<test_special_loop_id_33>")
        sut.enableSpecialLoop(forSpecialLoopID: "<test_special_loop_id_44>")

        sut.start()

        let coreLoop = try firstCoreLoop()
        let firstSpecialLoop = try firstSpecialLoop()
        let secondSpecialLoop = try secondSpecialLoop()

        try configureLatestEventIDs()

        timerScheduler.simulateTick()

        coreLoop.delegate?.disableSpecialLoop(withSpecialLoopID: "<test_special_loop_id_33>")

        finishAllOperations()

        XCTAssertEqual(coreLoop.recordedEvents.isEmpty, false)
        XCTAssertEqual(firstSpecialLoop.recordedEvents, [])
        XCTAssertEqual(secondSpecialLoop.recordedEvents.isEmpty, false)
    }

    func testCoreLoopNotifiesAboutStoppingSpecialLoop_WhenTimerTicksTwice_DoesNotExecutePreviouslyDisabledSpecialLoop() throws {
        sut.enableCoreLoop(forUserID: "<test_user_id_100>")
        sut.enableSpecialLoop(forSpecialLoopID: "<test_special_loop_id_66>")
        sut.enableSpecialLoop(forSpecialLoopID: "<test_special_loop_id_88>")

        sut.start()

        let coreLoop = try firstCoreLoop()
        let firstSpecialLoop = try firstSpecialLoop()
        let secondSpecialLoop = try secondSpecialLoop()

        try configureLatestEventIDs()

        coreLoop.delegate?.disableSpecialLoop(withSpecialLoopID: "<test_special_loop_id_66>")

        simulateTickAndFinish()
        simulateTickAndFinish()

        XCTAssertEqual(coreLoop.recordedEvents.isEmpty, false)
        XCTAssertEqual(firstSpecialLoop.recordedEvents, [])
        XCTAssertEqual(secondSpecialLoop.recordedEvents.isEmpty, false)
    }

    func testPropagateErrorWhenLatestEventIDIsMissing_CompletesCoreLoopAndSecondSpecialLoopWithErrorAndExecutesAllOperationsForFirstSpecialLoops() throws {
        sut.enableCoreLoop(forUserID: "<test_user_id_1>")
        sut.enableSpecialLoop(forSpecialLoopID: "<test_special_loop_id_1>")
        sut.enableSpecialLoop(forSpecialLoopID: "<test_special_loop_id_2>")

        sut.start()

        let coreLoop = try firstCoreLoop()
        let firstSpecialLoop = try firstSpecialLoop()
        let secondSpecialLoop = try secondSpecialLoop()

        firstSpecialLoop.latestEventID = "1st_special_event_id_#0"

        simulateTickAndFinish()

        XCTAssertEqual(coreLoop.recordedEvents, [
            .missingLatestEventIDError
        ])
        XCTAssertNil(coreLoop.latestEventID)

        XCTAssertEqual(firstSpecialLoop.recordedEvents, [
            .startedPolling(eventID: "1st_special_event_id_#0"),
            .finishedPolling(eventID: "1st_special_event_id_#0_#1", requiresClearCache: false, hasMorePages: true),
            .startedProcessing(eventID: "1st_special_event_id_#0_#1"),
            .finishedProcessing(eventID: "1st_special_event_id_#0_#1"),
            .startedPolling(eventID: "1st_special_event_id_#0_#1"),
            .finishedPolling(eventID: "1st_special_event_id_#0_#1_#2", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "1st_special_event_id_#0_#1_#2"),
            .finishedProcessing(eventID: "1st_special_event_id_#0_#1_#2")
        ])
        XCTAssertEqual(firstSpecialLoop.latestEventID, "1st_special_event_id_#0_#1_#2")

        XCTAssertEqual(secondSpecialLoop.recordedEvents, [
            .missingLatestEventIDError
        ])
        XCTAssertNil(secondSpecialLoop.latestEventID)
    }

    func testPropagateErrorWhenRequiresClearCacheIsReturned_CompletesFirstSpecialLoopWithCacheIsOutdatedError() throws {
        try enableCoreLoopAndTwoSpecialLoops()

        sut.start()

        let coreLoop = try firstCoreLoop()
        let firstSpecialLoop = try firstSpecialLoop()
        let secondSpecialLoop = try secondSpecialLoop()

        firstSpecialLoop.stubbedRequiresClearCache = true

        simulateTickAndFinish()

        XCTAssertEqual(coreLoop.recordedEvents.isEmpty, false)

        XCTAssertEqual(firstSpecialLoop.recordedEvents, [
            .startedPolling(eventID: "1st_special_event_id_#0"),
            .finishedPolling(eventID: "1st_special_event_id_#0_#1", requiresClearCache: true, hasMorePages: true),
            .requiresClearCacheError
        ])
        XCTAssertEqual(firstSpecialLoop.latestEventID, "1st_special_event_id_#0")

        XCTAssertEqual(secondSpecialLoop.recordedEvents.isEmpty, false)
    }

    func testPropagateErrorPollingEventsFailed_CompletesCoreLoopWithNetworkError() throws {
        try enableCoreLoopAndTwoSpecialLoops()

        sut.start()

        let coreLoop = try firstCoreLoop()
        let firstSpecialLoop = try firstSpecialLoop()
        let secondSpecialLoop = try secondSpecialLoop()

        let error = NSError(domain: "Invalid parameters", code: -4_982)
        coreLoop.stubbedNetworkError = EventsLoopError.networkError(error)

        simulateTickAndFinish()

        XCTAssertEqual(coreLoop.recordedEvents, [
            .startedPolling(eventID: "core_event_id_#0"),
            .networkError("The operation couldn’t be completed. (ProtonCoreEventsLoop.EventsLoopError error 0.)")
        ])
        XCTAssertEqual(coreLoop.latestEventID, "core_event_id_#0")

        XCTAssertEqual(firstSpecialLoop.recordedEvents.isEmpty, false)
        XCTAssertEqual(secondSpecialLoop.recordedEvents.isEmpty, false)
    }

    func testProcessingPageFailedForTheFirstSpecialLoop_CompletesFirstSpecialLoopWithPageProcessingErrorAndDoesNotOverrideLatestEventID() throws {
        try enableCoreLoopAndTwoSpecialLoops()

        sut.start()

        let coreLoop = try firstCoreLoop()
        let firstSpecialLoop = try firstSpecialLoop()
        let secondSpecialLoop = try secondSpecialLoop()

        let firstSpecialLoopStubbedProcessingError = NSError(domain: "Processing error", code: 9_999)
        firstSpecialLoop.stubbedProcessingError = firstSpecialLoopStubbedProcessingError

        simulateTickAndFinish()

        XCTAssertEqual(coreLoop.recordedEvents, [
            .startedPolling(eventID: "core_event_id_#0"),
            .finishedPolling(eventID: "core_event_id_#0_#1", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "core_event_id_#0_#1"),
            .finishedProcessing(eventID: "core_event_id_#0_#1")
        ])
        XCTAssertEqual(coreLoop.latestEventID, "core_event_id_#0_#1")

        let firstSpecialLoopInitialLatestEventID = "1st_special_event_id_#0"
        XCTAssertEqual(firstSpecialLoop.recordedEvents, [
            .startedPolling(eventID: "1st_special_event_id_#0"),
            .finishedPolling(eventID: "1st_special_event_id_#0_#1", requiresClearCache: false, hasMorePages: true),
            .startedProcessing(eventID: "1st_special_event_id_#0_#1"),
            .pageProcessingError(firstSpecialLoopStubbedProcessingError.localizedDescription)
        ])
        XCTAssertEqual(firstSpecialLoop.latestEventID, firstSpecialLoopInitialLatestEventID)

        XCTAssertEqual(secondSpecialLoop.recordedEvents, [
            .startedPolling(eventID: "2nd_special_event_id_#0"),
            .finishedPolling(eventID: "2nd_special_event_id_#0_#1", requiresClearCache: false, hasMorePages: true),
            .startedProcessing(eventID: "2nd_special_event_id_#0_#1"),
            .finishedProcessing(eventID: "2nd_special_event_id_#0_#1"),
            .startedPolling(eventID: "2nd_special_event_id_#0_#1"),
            .finishedPolling(eventID: "2nd_special_event_id_#0_#1_#2", requiresClearCache: false, hasMorePages: false),
            .startedProcessing(eventID: "2nd_special_event_id_#0_#1_#2"),
            .finishedProcessing(eventID: "2nd_special_event_id_#0_#1_#2")
        ])
        XCTAssertEqual(secondSpecialLoop.latestEventID, "2nd_special_event_id_#0_#1_#2")
    }

    /// Dictionaries in Swift are not thread safe - this test checks whether enabling special loops from different threads does not crash the app.
    /// There is `Atomic` class that wraps any generic type and allows modify the value on serial queue.
    func testEnablingCalendarLoopFromMultipleThreads_DoesNotCrashTheApp() {
        let dispatchGroup = DispatchGroup()
        let concurrentQueue = DispatchQueue(label: UUID().uuidString, attributes: .concurrent)
        let specialLoopsNumber = 10
        var enableCallCount = 0

        (0..<specialLoopsNumber).forEach { loopNumber in
            dispatchGroup.enter()

            concurrentQueue.async { [weak self] in
                self?.sut.enableSpecialLoop(forSpecialLoopID: "\(loopNumber)")
                enableCallCount += 1
                dispatchGroup.leave()
            }
        }

        _ = dispatchGroup.wait(timeout: .now() + .seconds(1))

        XCTAssertEqual(enableCallCount, specialLoopsNumber)
    }

    // MARK: - Private

    private var allQueues: [OperationQueue] {
        [eventsPeriodicSchedulerQueue].compactMap { $0 } + operationQueues
    }

    private func finishAllOperations() {
        eventsPeriodicSchedulerQueue.finishAllOperations()
    }

    private func firstCoreLoop() throws -> CoreLoopSpy {
        try XCTUnwrap(coreLoopFactory.createdLoops.last)
    }

    private func firstSpecialLoop() throws -> SpecialLoopSpy {
        try XCTUnwrap(specialLoopFactory.createdLoops.value[safeIndex: 0])
    }

    private func secondSpecialLoop() throws -> SpecialLoopSpy {
        try XCTUnwrap(specialLoopFactory.createdLoops.value[safeIndex: 1])
    }

    private func enableCoreLoopAndTwoSpecialLoops() throws {
        sut.enableCoreLoop(forUserID: "<test_user_id_1>")
        sut.enableSpecialLoop(forSpecialLoopID: "<test_special_loop_id_1>")
        sut.enableSpecialLoop(forSpecialLoopID: "<test_special_loop_id_2>")

        try configureLatestEventIDs()
    }

    private func simulateTickAndFinish() {
        timerScheduler.simulateTick()

        finishAllOperations()
    }

    private func configureLatestEventIDs() throws {
        let coreLoop = try firstCoreLoop()
        let firstSpecialLoop = try firstSpecialLoop()
        let secondSpecialLoop = try secondSpecialLoop()

        coreLoop.latestEventID = "core_event_id_#0"
        firstSpecialLoop.latestEventID = "1st_special_event_id_#0"
        secondSpecialLoop.latestEventID = "2nd_special_event_id_#0"
    }

}

private extension Array {

    subscript(safeIndex index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return nil
        }
        return self[index]
    }

}
