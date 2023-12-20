// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Technologies AG and Proton Calendar.
//
// Proton Calendar is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Calendar is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Calendar. If not, see https://www.gnu.org/licenses/.

import Foundation

public class EventsPeriodicScheduler<GeneralEventsLoop: CoreLoop, SpecialEventsLoop: EventsLoop>: CoreLoopDelegate {

    public typealias LoopID = String

    /// Serial queue for jobs posted by all loops
    private let queue: OperationQueue

    /// Timer re-fills `queue` periodically when it gets empty
    private var timer: Timer?
    /// Default `refillPeriod` is set to 60 seconds
    private let refillPeriod: TimeInterval
    private let currentDate: () -> Date
    private let serialQueueFactory: () -> OperationQueue
    private let timerScheduler: TimerScheduler

    /// Factory for event polling operation for core events
    private var coreLoopScheduler: LoopOperationScheduler<GeneralEventsLoop>?
    private let coreLoopFactory: AnyCoreLoopFactory<GeneralEventsLoop>

    /// Factories for event polling operations for per-specific events. Key is `SpecialLoopID` e.g. `CalendarID`
    private var specialLoopsSchedulers: Atomic<[LoopID: LoopOperationScheduler<SpecialEventsLoop>]> = Atomic([:])
    private let specialLoopFactory: AnySpecialLoopFactory<SpecialEventsLoop>

    public init(
        refillPeriod: TimeInterval = 60,
        currentDate: @escaping @autoclosure () -> Date,
        mainSchedulerOperationQueueFactory: @escaping () -> OperationQueue = OperationQueue.init,
        loopOperationQueueFactory: @escaping () -> OperationQueue = OperationQueue.init,
        timerScheduler: TimerScheduler = RunLoop.main,
        coreLoopFactory: AnyCoreLoopFactory<GeneralEventsLoop>,
        specialLoopFactory: AnySpecialLoopFactory<SpecialEventsLoop>
    ) {
        self.queue = SerialQueueFactory(createOperationQueue: mainSchedulerOperationQueueFactory).makeSerialQueue()
        self.serialQueueFactory = SerialQueueFactory(createOperationQueue: loopOperationQueueFactory).makeSerialQueue
        self.timerScheduler = timerScheduler
        self.refillPeriod = refillPeriod
        self.currentDate = currentDate
        self.coreLoopFactory = coreLoopFactory
        self.specialLoopFactory = specialLoopFactory
    }

    /// Starts listening for core and special loops
    public func start() {
        queue.isSuspended = false

        let timer = Timer(
            fireAt: currentDate(),
            interval: refillPeriod,
            target: self,
            selector: #selector(refillQueueIfNeeded),
            userInfo: nil,
            repeats: true
        )

        self.timer = timer
        timerScheduler.add(timer, forMode: .common)
    }

    @objc
    private func refillQueueIfNeeded() {
        if queue.isEmpty {
            scheduleOperations()
        }
    }

    private func scheduleOperations() {
        coreLoopScheduler?.addOperation(to: queue)
        sortedSpecialLoopsSchedulers.forEach { _, scheduler in
            scheduler.addOperation(to: queue)
        }
    }

    /// Suspends the queue and cancels all pending operations
    public func suspend() {
        queue.isSuspended = true
        queue.cancelAllOperations()

        timer?.invalidate()
    }

    /// Suspends the queue and disable all special loops
    public func reset() {
        suspend()
        specialLoopsSchedulers.mutate { value in
            value.removeAll()
        }
    }

    /// Enables core loop for specific userID
    /// - Parameter userID: specify `userID` for which you want to enable the core loop
    public func enableCoreLoop(forUserID userID: String) {
        let coreLoop = coreLoopFactory.makeCoreLoop(forUserID: userID)
        coreLoop.delegate = self

        coreLoopScheduler = LoopOperationScheduler(
            loop: coreLoop,
            order: 0,
            createOperationQueue: serialQueueFactory
        )
    }

    /// Enables special loop for specific loop ID
    /// - Parameter specialLoopID: specify `specialLoopID` for which you want to enable a specific loop
    /// e.g. for calendar app `specialLoopID` is `calendarID`
    public func enableSpecialLoop(forSpecialLoopID specialLoopID: LoopID) {
        let specialLoop = specialLoopFactory.makeSpecialLoop(forSpecialLoopID: specialLoopID)

        specialLoopsSchedulers.mutate { value in
            value[specialLoopID] = LoopOperationScheduler(
                loop: specialLoop,
                order: value.count,
                createOperationQueue: serialQueueFactory
            )
        }
    }

    /// Cancel current operations and triggers a core loop.
    public func triggerCoreLoop() {
        queue.cancelAllOperations()
        coreLoopScheduler?.addOperation(to: queue)
    }

    /// Triggers a special loop for a given loop ID
    /// - Parameter specialLoopID: specify `specialLoopID` for which you want to enable a specific loop.
    /// e.g. for calendar app `specialLoopID` is `calendarID`
    public func triggerSpecialLoop(forSpecialLoopID specialLoopID: LoopID) {
        triggerCoreLoop()
        let specialLoop = specialLoopsSchedulers.value[specialLoopID]
        specialLoop?.addOperation(to: queue)
    }

    private func disableSpecialLoop(forSpecialLoopID specialLoopID: LoopID) {
        queue
            .operations
            .compactMap { $0 as? LoopOperation<SpecialEventsLoop> }
            .filter { $0.loopID == specialLoopID }
            .forEach { $0.cancel() }

        specialLoopsSchedulers.mutate { value in
            value[specialLoopID] = nil
        }
    }

    /// Returns information which loops are currently enabled
    public func currentlyEnabled() -> EnabledLoops {
        let coreLoopIDs = [coreLoopScheduler?.loop.loopID].compactMap { $0 }
        let specialLoopIDs = sortedSpecialLoopsSchedulers.map(\.id)

        return .init(coreLoopIDs: coreLoopIDs, specialLoopIDs: specialLoopIDs)
    }

    private var sortedSpecialLoopsSchedulers: [(id: LoopID, scheduler: LoopOperationScheduler<SpecialEventsLoop>)] {
        specialLoopsSchedulers
            .value
            .map { (id: $0.key, scheduler: $0.value) }
            .sorted(by: \.scheduler.order, <)
    }

    // MARK: - CoreLoopDelegate

    public func didStopSpecialLoop(withSpecialLoopID specialLoopID: LoopID) {
        disableSpecialLoop(forSpecialLoopID: specialLoopID)
    }

}

private extension OperationQueue {

    var isEmpty: Bool {
        operationCount == 0
    }

}
