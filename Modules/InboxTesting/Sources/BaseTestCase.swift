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

import InboxCore
import XCTest

open class BaseTestCase: XCTestCase {

    private var originalMainScheduler: DispatchQueueScheduler!
    private var originalDispatchOnMain: ((DispatchWorkItem) -> Void)!
    private var originalDispatchOnMainAfter: Dispatcher.DispatchAfterType!
    private var originalGlobalQueue: ((DispatchQoS.QoSClass) -> DispatchQueueScheduler)!
    private var original_swift_task_enqueueGlobal_hook: ConcurrencyEnvironment.Hook!

    open override func setUp() {
        super.setUp()

        originalMainScheduler = Dispatcher.mainScheduler
        originalDispatchOnMain = Dispatcher.dispatchOnMain
        originalDispatchOnMainAfter = Dispatcher.dispatchOnMainAfter
        originalGlobalQueue = Dispatcher.globalQueue
        original_swift_task_enqueueGlobal_hook = ConcurrencyEnvironment.swift_task_enqueueGlobal_hook

        Dispatcher.mainScheduler = AnyScheduler(DispatchQueueImmediateScheduler())
        Dispatcher.dispatchOnMain = { task in task.perform() }
        Dispatcher.dispatchOnMainAfter = { _, task in task.perform() }
        Dispatcher.globalQueue = { _ in .init(DispatchQueueImmediateScheduler()) }
        ConcurrencyEnvironment.swift_task_enqueueGlobal_hook = { job, _ in
            TestExecutor.shared.enqueue(job)
        }
    }

    open override func tearDown() {
        Dispatcher.mainScheduler = originalMainScheduler
        Dispatcher.dispatchOnMain = originalDispatchOnMain
        Dispatcher.dispatchOnMainAfter = originalDispatchOnMainAfter
        Dispatcher.globalQueue = originalGlobalQueue
        ConcurrencyEnvironment.swift_task_enqueueGlobal_hook = original_swift_task_enqueueGlobal_hook

        originalMainScheduler = nil
        originalDispatchOnMain = nil
        originalDispatchOnMainAfter = nil
        originalGlobalQueue = nil
        original_swift_task_enqueueGlobal_hook = nil

        super.tearDown()
    }

}

private final class TestExecutor: SerialExecutor {
    static let shared = TestExecutor()

    func enqueue(_ job: consuming ExecutorJob) {
        job.runSynchronously(on: asUnownedSerialExecutor())
    }

    func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}
