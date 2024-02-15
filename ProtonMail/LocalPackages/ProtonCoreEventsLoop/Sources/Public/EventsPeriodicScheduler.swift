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

import Foundation

public class EventsPeriodicScheduler<GeneralEventsLoop: CoreLoop, SpecialEventsLoop: EventsLoop>: CoreLoopDelegate {

    public typealias LoopID = String

    /// Serial queue for jobs posted by all loops
    private let queue = SerialQueueFactory(
        createOperationQueue: Environment.mainSchedulerOperationQueueFactory
    ).makeSerialQueue()

    /// Timer re-fills `queue` periodically when it gets empty
    private var timer: Timer?

    /// Default `refillPeriod` is set to 60 seconds
    private let refillPeriod: TimeInterval

    private let serialQueueFactory = SerialQueueFactory(
        createOperationQueue: Environment.loopOperationQueueFactory
    ).makeSerialQueue

    private let timerScheduler = Environment.timerScheduler

    /// Factory for event polling operation for core events
    private var coreLoopScheduler: LoopOperationScheduler<GeneralEventsLoop>?
    private let coreLoopFactory: AnyCoreLoopFactory<GeneralEventsLoop>

    /// Factories for event polling operations for per-specific events. Key is `SpecialLoopID` e.g. `CalendarID`
    private var specialLoopsSchedulers: Atomic<[LoopID: LoopOperationScheduler<SpecialEventsLoop>]> = Atomic([:])
    private let specialLoopFactory: AnySpecialLoopFactory<SpecialEventsLoop>

    public init(
        refillPeriod: TimeInterval = 60,
        coreLoopFactory: AnyCoreLoopFactory<GeneralEventsLoop>,
        specialLoopFactory: AnySpecialLoopFactory<SpecialEventsLoop>
    ) {
        self.refillPeriod = refillPeriod
        self.coreLoopFactory = coreLoopFactory
        self.specialLoopFactory = specialLoopFactory
    }

    /// Starts timer that pings core and special loops
    public func start() {
        queue.isSuspended = false

        let timer = Timer(
            fireAt: Environment.currentDate(),
            interval: refillPeriod,
            target: self,
            selector: #selector(refillQueueIfNeeded),
            userInfo: nil,
            repeats: true
        )

        self.timer = timer
        timerScheduler.add(timer, forMode: .common)
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

    /// Removes all operations from the queue to execute a core loop as a first operation.
    public func triggerCoreLoop() {
        queue.cancelAllOperations()
        coreLoopScheduler?.addOperation(to: queue)
    }

    /// Triggers a core loop and just then a special loop with a given loop ID
    /// - Parameter specialLoopID: specify `specialLoopID` for which you want to enable a specific loop.
    /// e.g. for calendar app `specialLoopID` is `calendarID`
    public func triggerSpecialLoop(forSpecialLoopID specialLoopID: LoopID) {
        triggerCoreLoop()
        let specialLoop = specialLoopsSchedulers.value[specialLoopID]
        specialLoop?.addOperation(to: queue)
    }

    // MARK: - CoreLoopDelegate

    /// Disables a special loop with a given loop ID
    /// - Parameter specialLoopID: specify `specialLoopID` for which you want to disable a specific loop.
    /// e.g. for calendar app `specialLoopID` is `calendarID`
    public func disableSpecialLoop(withSpecialLoopID specialLoopID: LoopID) {
        queue
            .operations
            .compactMap { $0 as? LoopOperation<SpecialEventsLoop> }
            .filter { loopOperation in loopOperation.loopID == specialLoopID }
            .forEach { loopOperation in loopOperation.cancel() }

        specialLoopsSchedulers.mutate { value in
            value[specialLoopID] = nil
        }
    }

    // MARK: - Private

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

    private var sortedSpecialLoopsSchedulers: [(id: LoopID, scheduler: LoopOperationScheduler<SpecialEventsLoop>)] {
        specialLoopsSchedulers
            .value
            .map { specialLoop in (id: specialLoop.key, scheduler: specialLoop.value) }
            .sorted(by: \.scheduler.order, <)
    }

}

private extension OperationQueue {

    var isEmpty: Bool {
        operationCount == 0
    }

}
